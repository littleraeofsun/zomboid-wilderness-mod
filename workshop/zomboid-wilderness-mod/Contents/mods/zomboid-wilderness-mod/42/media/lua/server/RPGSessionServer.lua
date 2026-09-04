require "WildernessSurvivalRules"

local DICE_TYPES = {
    "Base.Dice",
    "Base.Dice_4",
    "Base.Dice_6",
    "Base.Dice_8",
    "Base.Dice_10",
    "Base.Dice_12",
    "Base.Dice_20",
    "Base.Dice_00",
    "Base.Dice_Bone",
    "Base.Dice_Wood",
}


-- Active sessions indexed by the reader's online ID.
local activeReaders = {}


-- =========================================================
-- Does this player possess any usable die?
--
-- containsTypeRecurse() means dice inside backpacks,
-- pouches, etc. still count.
-- =========================================================

local function hasDice(player)
    if not player then
        return false
    end

    local inventory = player:getInventory()

    for _, diceType in ipairs(DICE_TYPES) do
        if inventory:containsTypeRecurse(diceType) then
            return true
        end
    end

    return false
end


-- =========================================================
-- Is participant within the 3-tile activity area?
--
-- This uses a square radius:
--
-- XXXXXXX
-- XXXXXXX
-- XXXXXXX
-- XXXRXXX
-- XXXXXXX
-- XXXXXXX
-- XXXXXXX
--
-- R = reader
-- =========================================================

local function isWithinDiceRange(reader, player)
    if not reader or not player then
        return false
    end

    -- Players on different floors cannot participate.
    if reader:getZ() ~= player:getZ() then
        return false
    end

    local dx = math.abs(reader:getX() - player:getX())
    local dy = math.abs(reader:getY() - player:getY())

    return dx <= WildernessSurvivalRules.getRPGSessionRange()
        and dy <= WildernessSurvivalRules.getRPGSessionRange()
end


-- =========================================================
-- Apply dice-session mood benefit.
--
-- This is completely separate from vanilla book behavior.
-- =========================================================

local function applyDiceBonus(player)
    player:getStats():remove(
        CharacterStat.UNHAPPINESS,
        WildernessSurvivalRules.getRPGSessionUnhappinessReduction()
    )
    player:getStats():remove(
        CharacterStat.STRESS,
        WildernessSurvivalRules.getRPGSessionStressReduction()
    )
end


-- =========================================================
-- Receive start/stop notifications from reader client
-- =========================================================

local function onClientCommand(module, command, player, args)
    if module ~= WildernessSurvivalRules.RPG_SESSION_MODULE.NAME then
        return
    end

    local playerID = player:getOnlineID()

    if command == WildernessSurvivalRules.RPG_SESSION_MODULE.EVENT_START
        and WildernessSurvivalRules.isRPGSessionEnabled() then

        activeReaders[playerID] = {
            player = player,
            elapsedMinutes = 0
        }

    elseif command == WildernessSurvivalRules.RPG_SESSION_MODULE.EVENT_STOP then

        activeReaders[playerID] = nil

    end
end

Events.OnClientCommand.Add(onClientCommand)


-- =========================================================
-- Process active RPG sessions every in-game minute
-- =========================================================

local function everyMinute()
    if not WildernessSurvivalRules.isRPGSessionEnabled() then
        return
    end

    local onlinePlayers = getOnlinePlayers()

    if not onlinePlayers then
        return
    end

    for readerID, session in pairs(activeReaders) do
        local reader = session.player

        if not reader then
            activeReaders[readerID] = nil

        else
            session.elapsedMinutes = session.elapsedMinutes + 1

            if session.elapsedMinutes >= WildernessSurvivalRules.getRPGSessionInterval() then
                session.elapsedMinutes = 0

                for i = 0, onlinePlayers:size() - 1 do
                    local participant = onlinePlayers:get(i)

                    if participant
                    and isWithinDiceRange(reader, participant)
                    and hasDice(participant) then

                        applyDiceBonus(participant)

                    end
                end
            end
        end
    end
end

Events.EveryOneMinute.Add(everyMinute)