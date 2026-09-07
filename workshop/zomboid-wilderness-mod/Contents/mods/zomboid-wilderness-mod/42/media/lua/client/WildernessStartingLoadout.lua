require "WildernessStartingLoadoutRules"

local function applySoloStartingLoadout(player)
    if not WildernessStartingLoadoutRules.shouldUseCustomStartingItems() then
        return
    end
        
    WildernessStartingLoadoutRules.removeAllNonClothingItems(player)

    local preset = WildernessStartingLoadoutRules.getStartingItemsPreset()
    if preset == "Naked and Afraid" then
        WildernessStartingLoadoutRules.stripAllClothing(player)
    end    

    local startingItems = WildernessStartingLoadoutRules.getStartingItemsForPreset(preset)
    if startingItems == nil then
        return
    end

    for _, item in ipairs(startingItems) do
        player:getInventory():AddItem(item)
    end
end

-- ========================================================
-- Handle applying starting loadout for single player games
-- ========================================================
local function onNewGame(player)
    -- exit if player is nil
    if player == nil or isClient() or not WildernessStartingLoadoutRules.shouldUseCustomStartingItems() then
        return
    end

    applySoloStartingLoadout(player) 
end

Events.OnNewGame.Add(onNewGame)

-- ========================================================
-- Handle applying starting loadout for multiplayer games
-- ========================================================
local function onGameStart()
    if not isClient() then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local function awaitStartingLoadout()
        -- Wait until character creation and the initial inventory sync have completed.
        if WildernessSurvivalRules.getSandboxSettings() == nil then
            return
        end

        Events.OnTick.Remove(awaitStartingLoadout)

        if not WildernessStartingLoadoutRules.shouldUseCustomStartingItems() then
            return
        end

        sendClientCommand(
            player,
            WildernessStartingLoadoutRules.MP_MODULE.NAME,
            WildernessStartingLoadoutRules.MP_MODULE.EVENTS.APPLY_STARTING_LOADOUT,
            {}
        )
    end

    Events.OnTick.Add(awaitStartingLoadout)
end

Events.OnGameStart.Add(onGameStart)
