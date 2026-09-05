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


-- =========================================================
-- Start reading
-- =========================================================

local originalStart = ISReadABook.start

local function extendRPGManualReadTime(action)
    print("RPGSessionRules: extendRPGManualReadTime() called: " .. tostring(action.wsrDurationAdjusted) .. " | " .. tostring(action.maxTime) .. " | " .. tostring(action.item:getFullType()))
    if not action.wsrDurationAdjusted
        and isRPGManual(action.item) then

         -- vanilla read time is 10 minutes, so we divide the configured read time by 10 to get the multiplier
        local multiplier = RPGSessionRules.getRPGManualReadTime() / 10
        action.maxTime = action.maxTime * multiplier

        action.wsrDurationAdjusted = true

        print("    extendRPGManualReadTime() updated: " .. tostring(action.wsrDurationAdjusted) .. " | " .. tostring(action.maxTime))
    end
end

function ISReadABook:start()
    print("RPGSessionRules: ISReadABook:start() called: " .. tostring(self.wsrDurationAdjusted) .. " | " .. tostring(self.maxTime) .. " | " .. tostring(self.item:getFullType()))
    if not isRPGManual(self.item) then
        print("    ISReadABook:start() - not an RPG manual, skipping.")
        originalStart(self)
        return
    end

    extendRPGManualReadTime(self)
    originalStart(self)

    -- if this is a multiplayer game and the player is reading an RPG manual, notify the server to start tracking the RPG session
    if isClient() then
        print("    ISReadABook:start() - RPG manual detected, sending client command to start RPG session for player " .. self.character:getUsername())
        sendClientCommand(
            self.character,
            RPGSessionRules.MP_MODULE.NAME,
            RPGSessionRules.MP_MODULE.EVENTS.READING_START,
            {}
        )
    end
end


-- =========================================================
-- Stop/cancel reading
-- =========================================================

local originalStop = ISReadABook.stop

function ISReadABook:stop()
    print("RPGSessionRules: ISReadABook:stop() called: " .. tostring(self.wsrDurationAdjusted) .. " | " .. tostring(self.maxTime) .. " | " .. tostring(self.item:getFullType()))

    -- if this is a multiplayer game and the player is reading an RPG manual, notify the server to stop tracking the RPG session
    if isClient() and isRPGManual(self.item) then
        print("    ISReadABook:stop() - RPG manual detected in multiplayer, sending client command to stop RPG session for player " .. self.character:getUsername())
        sendClientCommand(
            self.character,
            RPGSessionRules.MP_MODULE.NAME,
            RPGSessionRules.MP_MODULE.EVENTS.READING_STOP,
            {}
        )
    end

    originalStop(self)
end


-- =========================================================
-- Finished reading normally
-- =========================================================

local function applySoloBulkDiceBonus(player, rpgManual)
    print("RPGSessionRules: applySoloBulkDiceBonus() called for player " .. player:getUsername() .. " feature is enabled " .. tostring(RPGSessionRules.isRPGSessionEnabled()) .. " and player has dice " .. tostring(RPGSessionRules.playerHasDice(player)))
    if RPGSessionRules.isRPGSessionEnabled()
        and RPGSessionRules.playerHasDice(player) then

        print("    applySoloBulkDiceBonus() - applying bonus for completing RPG session")

        -- for single player games, bonus is applied all at once when the player finishes reading the RPG manual
        local minutesPerPage = SandboxVars.MinutesPerPage
        local pages = 5 -- RPG manual has -1 pages in game, so we just hardcode the effective page count here

        local totalMinutes = pages * minutesPerPage

        -- get interval and bound it between 1 and 60 minutes
        local rpgInterval = math.min(60, math.max(1, RPGSessionRules.getRPGSessionInterval()))
        local intervalCount = math.min(60, math.max(0, math.floor(totalMinutes / rpgInterval)))

        print("    applySoloBulkDiceBonus() - totalMinutes: " .. tostring(totalMinutes) .. " | rpgInterval: " .. tostring(rpgInterval) .. " | intervalCount: " .. tostring(intervalCount))

        local unhappinessReduction = RPGSessionRules.getRPGSessionUnhappinessReduction() * intervalCount
        local stressReduction = RPGSessionRules.getRPGSessionStressReduction() * intervalCount

        player:getStats():remove(
            CharacterStat.UNHAPPINESS,
            RPGSessionRules.getRPGSessionUnhappinessReduction() * intervalCount
        )
        player:getStats():remove(
            CharacterStat.STRESS,
            RPGSessionRules.getRPGSessionStressReduction() * intervalCount
        )

        print("    applySoloBulkDiceBonus() - unhappiness reduced by " .. tostring(unhappinessReduction) .. " | stress reduced by " .. tostring(stressReduction))
    end
end

local originalPerform = ISReadABook.perform

function ISReadABook:perform()
    print("RPGSessionRules: ISReadABook:perform() called for player: " .. self.character:getUsername() .. " | feature is enabled: " .. tostring(RPGSessionRules.isRPGSessionEnabled()) .. " | item is RPG manual: " .. tostring(isRPGManual(self.item)))
    if RPGSessionRules.isRPGSessionEnabled() and isRPGManual(self.item) then     
        if not isClient() then -- this is a single player local game
            print("    ISReadABook:perform() - single player game detected, applying client-side bulk dice bonus for player " .. self.character:getUsername())
            applySoloBulkDiceBonus(self.character, self.item)
        else -- this is a multiplayer game
            print("    ISReadABook:perform() - multiplayer game detected, sending client command to notify server for player " .. self.character:getUsername())
            sendClientCommand(
                self.character,
                RPGSessionRules.MP_MODULE.NAME,
                RPGSessionRules.MP_MODULE.EVENTS.READING_COMPLETE,
                {}
            )
        end
    end

    originalPerform(self)
end