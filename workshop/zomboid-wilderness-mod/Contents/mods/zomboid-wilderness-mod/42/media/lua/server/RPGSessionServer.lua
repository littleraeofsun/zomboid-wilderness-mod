-- =========================================================
-- This feature has a tightly coupled client/server implementation for multiplayer games.
-- For single player games, only client-side logic is required.
-- =========================================================

require "RPGSessionRules"

local playerHasDice = RPGSessionRules.playerHasDice
local RPG_MANUAL = "Base.RPGmanual"

-- Active sessions indexed by the reader's online ID.
local activeReaders = {}

local function getActiveReaderCount()
    local count = 0
    for _ in pairs(activeReaders) do
        count = count + 1
    end
    return count
end

local function isReadingRPGManual(player)
    return player
        and not player:isDead()
        and player:isReading()
        and player:getInventory():containsTypeRecurse(RPG_MANUAL)
end

local function refreshActiveReaders(onlinePlayers)
    print("RPGSessionRules: refreshActiveReaders() - refreshing active readers from replicated reading state.")
    local currentlyReading = {}

    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i)
        local playerID = player and player:getOnlineID()

        if playerID and isReadingRPGManual(player) then
            print("RPGSessionRules: refreshActiveReaders() - detected reader " .. tostring(player:getUsername()) .. " (ID: " .. tostring(playerID) .. ")")
            currentlyReading[playerID] = true
            if not activeReaders[playerID] then
                activeReaders[playerID] = {
                    player = player,
                    elapsedMinutes = 0
                }
                print("RPGSessionRules: detected reader " .. tostring(player:getUsername()) .. " from replicated reading state.")
            end
        end
    end

    for readerID in pairs(activeReaders) do
        if not currentlyReading[readerID] then
            activeReaders[readerID] = nil
        end
    end
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
    print("**********RPG BONUS FOR " .. tostring(player:getUsername()) .. " (ID: " .. tostring(player:getOnlineID()) .. ")**********")
    local stats = player:getStats()

    stats:remove(
        CharacterStat.UNHAPPINESS,
        RPGSessionRules.getRPGSessionUnhappinessReduction()
    )

    local stressReduction = RPGSessionRules.getRPGSessionStressReduction() / 100
    local stress = stats:get(CharacterStat.STRESS)
    stats:set(CharacterStat.STRESS, math.max(0, stress - stressReduction))
    sendPlayerStatsChange(player)
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
    print("RPGSessionRules: onClientCommand() called with module: " .. tostring(module) .. ", command: " .. tostring(command) .. ", player: " .. tostring(player:getUsername()) .. ", args: " .. tostring(args))
    if module ~= RPGSessionRules.MP_MODULE.NAME
    or not RPGSessionRules.isRPGSessionEnabled() then
        print("    onClientCommand() - module does not match " .. tostring(RPGSessionRules.MP_MODULE.NAME) .. " or RPG sessions are disabled, ignoring command.")
        return
    end

    local playerID = player:getOnlineID()

    if player:isDead() then
        print("    onClientCommand() - player " .. tostring(player:getUsername()) .. " (ID: " .. tostring(playerID) .. ") is dead, removing from active readers.")
        activeReaders[playerID] = nil
        return
    end

    if command == RPGSessionRules.MP_MODULE.EVENTS.READING_START
        and RPGSessionRules.isRPGSessionEnabled() then
        print("RPGSessionRules: onClientCommand() - player " .. tostring(player:getUsername()) .. " (ID: " .. tostring(playerID) .. ") has started reading.")

        if not activeReaders[playerID] then
            activeReaders[playerID] = {
                player = player,
                elapsedMinutes = 0
            }
        end

    elseif command == RPGSessionRules.MP_MODULE.EVENTS.READING_STOP then

        print("RPGSessionRules: onClientCommand() - player " .. tostring(player:getUsername()) .. " (ID: " .. tostring(playerID) .. ") has cancelled reading.")

        activeReaders[playerID] = nil

    elseif command == RPGSessionRules.MP_MODULE.EVENTS.READING_COMPLETE then

        print("RPGSessionRules: onClientCommand() - player " .. tostring(player:getUsername()) .. " (ID: " .. tostring(playerID) .. ") has finished reading.")
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
    local onlinePlayers = getOnlinePlayers()
    if not RPGSessionRules.isRPGSessionEnabled()
    or not onlinePlayers or onlinePlayers:size() == 0 then
        return
    end

    -- Build 42 may silently drop timed-action client commands. The replicated
    -- reading state provides a server-authoritative fallback.
    refreshActiveReaders(onlinePlayers)

    print("RPGSessionRules: everyMinute() - " .. tostring(onlinePlayers:size()) .. " online players and " .. tostring(getActiveReaderCount()) .. " active readers.")

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