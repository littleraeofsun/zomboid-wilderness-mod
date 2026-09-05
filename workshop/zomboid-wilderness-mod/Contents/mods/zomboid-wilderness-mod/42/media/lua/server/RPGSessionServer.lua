-- =========================================================
-- This feature has a tightly coupled client/server implementation for multiplayer games.
-- For single player games, only client-side logic is required.
-- =========================================================

require "RPGSessionRules"

local playerHasDice = RPGSessionRules.playerHasDice

-- Active sessions indexed by the reader's online ID.
local activeReaders = {}

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

    return dx <= RPGSessionRules.getRPGSessionRange()
        and dy <= RPGSessionRules.getRPGSessionRange()
end


-- ========================================================
-- Get online player by ID (to determing if a cached reader is still online).
-- ========================================================
local function getOnlinePlayerByID(onlineID)
    local players = getOnlinePlayers()

    if not players then
        return nil
    end

    for i = 0, players:size() - 1 do
        local player = players:get(i)

        if player and player:getOnlineID() == onlineID then
            return player
        end
    end

    return nil
end


-- =========================================================
-- Apply dice-session mood benefit.
--
-- This is completely separate from vanilla book behavior.
-- =========================================================

local function applyDiceBonus(player)
    player:getStats():remove(
        CharacterStat.UNHAPPINESS,
        RPGSessionRules.getRPGSessionUnhappinessReduction()
    )
    player:getStats():remove(
        CharacterStat.STRESS,
        RPGSessionRules.getRPGSessionStressReduction()
    )
end

-- ========================================================
-- Apply dice-session mood benefit to all participants within range of the reader.
-- ========================================================

local function applySession(reader)
    local onlinePlayers = getOnlinePlayers()

    print("RPGSessionRules: applySession() called for " .. tostring(onlinePlayers:size()) .. " online players.")

    for i = 0, onlinePlayers:size() - 1 do
        local participant = onlinePlayers:get(i)

        print("    applySession() - checking participant " .. tostring(participant:getUsername()) .. " (ID: " .. tostring(participant:getOnlineID()) .. ")")

        if participant
        and isWithinDiceRange(reader, participant)
        and playerHasDice(participant) then

            applyDiceBonus(participant)

        end
    end
end


-- =========================================================
-- Receive start/stop notifications from reader client
-- =========================================================

local function onClientCommand(module, command, player, args)
    if module ~= RPGSessionRules.MP_MODULE.NAME then
        return
    end

    local playerID = player:getOnlineID()

    if player:isDead() then
        activeReaders[playerID] = nil
        return
    end

    if command == RPGSessionRules.MP_MODULE.EVENTS.READING_START
        and RPGSessionRules.isRPGSessionEnabled() then

        activeReaders[playerID] = {
            player = player,
            elapsedMinutes = 0
        }

    elseif command == RPGSessionRules.MP_MODULE.EVENTS.READING_STOP then

        activeReaders[playerID] = nil

    elseif command == RPGSessionRules.MP_MODULE.EVENTS.READING_COMPLETE then
        
        activeReaders[playerID] = nil
        applySession(player) -- apply final bonus for completing the session

    end
end

Events.OnClientCommand.Add(onClientCommand)


-- =========================================================
-- Process active RPG sessions every in-game minute
-- =========================================================

local function everyMinute()
    -- exit if RPG sessions are disabled or if there are no online players
    if not RPGSessionRules.isRPGSessionEnabled()
    or not getOnlinePlayers() then
        return
    end

    print("RPGSessionRules: everyMinute() - processing active RPG sessions for " .. tostring(getOnlinePlayers():size()) .. " online players.")

    for readerID, session in pairs(activeReaders) do
        local reader = getOnlinePlayerByID(readerID)

        if not reader or reader:isDead() then
            print("    everyMinute() - reader " .. tostring(readerID) .. " is no longer online or is dead, removing from active readers.")
            activeReaders[readerID] = nil

        else
            session.elapsedMinutes = session.elapsedMinutes + 1

            print("    everyMinute() - reader " .. tostring(readerID) .. " has been reading for " .. tostring(session.elapsedMinutes) .. " minutes.")

            -- apply bonus if the session has reached the configured interval
            if session.elapsedMinutes >= RPGSessionRules.getRPGSessionInterval() then
                session.elapsedMinutes = 0
                applySession(reader)
            end
        end
    end
end

Events.EveryOneMinute.Add(everyMinute)