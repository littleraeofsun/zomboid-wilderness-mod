-- =========================================================
-- This feature has a tightly coupled client/server implementation for multiplayer games.
-- For single player games, only client-side logic is required.
-- =========================================================

require "RPGSessionRules"
require "TimedActions/ISReadABook"

local RPG_MANUAL = "Base.RPGmanual"

local function isRPGManual(item)
    return item
        and item:getFullType() == RPG_MANUAL
end

local function sendRPGCommand(command)
    -- The player overload silently drops commands when Build 42 does not regard
    -- the timed-action character as local. Let the game associate player 0.
    sendClientCommand(RPGSessionRules.MP_MODULE.NAME, command, {})
end


-- =========================================================
-- Start reading
-- =========================================================

local originalStart = ISReadABook.start

local function extendRPGManualReadTime(action)
    if not action.wsrDurationAdjusted
        and isRPGManual(action.item) then

         -- vanilla read time is 10 minutes, so we divide the configured read time by 10 to get the multiplier
        local multiplier = RPGSessionRules.getRPGManualReadTime() / 10
        action.maxTime = action.maxTime * multiplier

        action.wsrDurationAdjusted = true
    end
end

function ISReadABook:start()
    if not isRPGManual(self.item) then
        originalStart(self)
        return
    end

    extendRPGManualReadTime(self)
    originalStart(self)

    -- if this is a multiplayer game and the player is reading an RPG manual, notify the server to start tracking the RPG session
    if isClient() then
        sendRPGCommand(RPGSessionRules.MP_MODULE.EVENTS.READING_START)
    end
end


-- =========================================================
-- Stop/cancel reading
-- =========================================================

local originalStop = ISReadABook.stop

function ISReadABook:stop()

    -- if this is a multiplayer game and the player is reading an RPG manual, notify the server to stop tracking the RPG session
    if isClient() and isRPGManual(self.item) then
    end

    originalStop(self)
end


-- =========================================================
-- Finished reading normally
-- =========================================================

local function applySoloBulkDiceBonus(player, rpgManual)
        and RPGSessionRules.playerHasDice(player) then

        -- for single player games, bonus is applied all at once when the player finishes reading the RPG manual
        local minutesPerPage = SandboxVars.MinutesPerPage
        local pages = 5 -- RPG manual has -1 pages in game, so we just hardcode the effective page count here

        local totalMinutes = pages * minutesPerPage

        -- get interval and bound it between 1 and 60 minutes
        local rpgInterval = math.min(60, math.max(1, RPGSessionRules.getRPGSessionInterval()))
        local intervalCount = math.min(60, math.max(0, math.floor(totalMinutes / rpgInterval)))

        local unhappinessReduction = RPGSessionRules.getRPGSessionUnhappinessReduction() * intervalCount
        local stressReduction = RPGSessionRules.getRPGSessionStressReduction() / 100 * intervalCount
        local stats = player:getStats()
        local stress = stats:get(CharacterStat.STRESS)

        stats:remove(CharacterStat.UNHAPPINESS, unhappinessReduction)
        stats:set(CharacterStat.STRESS, math.max(0, stress - stressReduction))
end

local originalPerform = ISReadABook.perform

function ISReadABook:perform()
    if RPGSessionRules.isRPGSessionEnabled() and isRPGManual(self.item) then     
        if not isClient() then -- this is a single player local game
            applySoloBulkDiceBonus(self.character, self.item)
        else -- this is a multiplayer game
            sendRPGCommand(RPGSessionRules.MP_MODULE.EVENTS.READING_COMPLETE)
        end
    end

    originalPerform(self)
end