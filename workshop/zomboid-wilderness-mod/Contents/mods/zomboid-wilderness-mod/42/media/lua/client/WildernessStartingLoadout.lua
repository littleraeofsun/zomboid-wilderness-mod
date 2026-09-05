require "WildernessStartingLoadoutRules"

local function applySoloStartingLoadout(player)
    if not WildernessStartingLoadoutRules.shouldUseCustomStartingItems() then
        print("WildernessStartingLoadout: applySoloStartingLoadout() - sandbox setting is disabled, skipping loadout application.")
        return
    end

    print("WildernessStartingLoadout: applySoloStartingLoadout() - applying starting loadout for player " .. player:getUsername())
        
    WildernessStartingLoadoutRules.removeAllNonClothingItems(player)

    print("    applySoloStartingLoadout() - removed all non-clothing items from player ")

    local preset = WildernessStartingLoadoutRules.getStartingItemsPreset()
    if preset == "Naked and Afraid" then
        WildernessStartingLoadoutRules.stripAllClothing(player)
        print("    applySoloStartingLoadout() - stripped all clothing from player ")
    end    

    local startingItems = WildernessStartingLoadoutRules.getStartingItemsForPreset(preset)
    if startingItems == nil then
        print("    applySoloStartingLoadout() - no starting items found for preset " .. preset)
        return
    end

    print("    applySoloStartingLoadout() - adding starting items for preset " .. preset)
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
        print("WildernessStartingLoadout: onNewGame() - exiting early; player: " .. tostring(player) .. ", isClient: " .. tostring(isClient()) .. ", shouldUseCustomStartingItems: " .. tostring(WildernessStartingLoadoutRules.shouldUseCustomStartingItems()))
        return
    end

    print("WildernessStartingLoadout: onNewGame() - this is a single player game, applying starting loadout for player " .. player:getUsername())
    applySoloStartingLoadout(player) 
end

Events.OnNewGame.Add(onNewGame)

-- ========================================================
-- Handle applying starting loadout for multiplayer games
-- ========================================================
local function onCreatePlayer(playerIndex, player)
    -- exit if player is nil or if this is a NOT client/server multiplayer game (we only want to apply the loadout on the server in multiplayer)
    if player == nil or not isClient() or not WildernessStartingLoadoutRules.shouldUseCustomStartingItems() then
        print("WildernessStartingLoadout: onCreatePlayer() - exiting early; player: " .. tostring(player) .. ", isClient: " .. tostring(isClient()) .. ", shouldUseCustomStartingItems: " .. tostring(WildernessStartingLoadoutRules.shouldUseCustomStartingItems()))
        return
    end

    print("WildernessStartingLoadout: onCreatePlayer() - this IS a client/server multiplayer game, handing loadout application to server.")
    sendClientCommand(
        player,
        WildernessStartingLoadoutRules.MP_MODULE.NAME,
        WildernessStartingLoadoutRules.MP_MODULE.EVENTS.APPLY_STARTING_LOADOUT,
        {}
    )
end

Events.OnCreatePlayer.Add(onCreatePlayer)