require "WildernessStartingLoadoutRules"

local function addHawksLoadout(player)
    local inventory = player:getInventory()
    inventory:AddItem("Base.ChickenFeather")
    inventory:AddItem("Base.Cudgel_Nails")
    inventory:AddItem("Base.RPGmanual")
    local dicePouch = inventory:AddItem("Base.SeedBag")
    local pouchInventory = dicePouch:getInventory()
    pouchInventory:AddItem("Base.Dice_4")
    pouchInventory:AddItem("Base.Dice_6")
    pouchInventory:AddItem("Base.Dice_8")
    pouchInventory:AddItem("Base.Dice_10")
    pouchInventory:AddItem("Base.Dice_12")
    pouchInventory:AddItem("Base.Dice_20")
    pouchInventory:AddItem("Base.Dice_00")
end

local function applyMultiplayerStartingLoadout(player)
    if not WildernessStartingLoadoutRules.shouldUseCustomStartingItems() then
        print("WildernessStartingLoadout: applyMultiplayerStartingLoadout() - sandbox setting is disabled, skipping loadout application.")
        return
    end

    print("WildernessStartingLoadout: applyMultiplayerStartingLoadout() - applying starting loadout for player " .. player:getUsername())

    local modData = player:getModData()
    
    -- Prevent duplicate grants.
    if modData.WildernessSurvivalStartingLoadoutApplied then
        print("    applyMultiplayerStartingLoadout() - starting loadout already applied for player " .. player:getUsername() .. ", skipping.")
        return
    end
        
    WildernessStartingLoadoutRules.removeAllNonClothingItems(player)

    print("    applyMultiplayerStartingLoadout() - removed all non-clothing items from player ")

    local preset = WildernessStartingLoadoutRules.getStartingItemsPreset()
    if preset == "Naked and Afraid" then
        WildernessStartingLoadoutRules.stripAllClothing(player)
        print("    applyMultiplayerStartingLoadout() - N&A: stripped all clothing from player ")
    end    

    local startingItems = WildernessStartingLoadoutRules.getStartingItemsForPreset(preset)
    if startingItems == nil then
        print("    applyMultiplayerStartingLoadout() - no starting items found for preset " .. preset)
        return
    end

    print("    applyMultiplayerStartingLoadout() - adding starting items for preset " .. preset)
    for _, item in ipairs(startingItems) do
        player:getInventory():AddItem(item)
    end

    -- Hawks clause <3
    local username = player:getUsername()
    local isHawks = username ~= nil and string.find(string.lower(username), "hawks", 1, true) ~= nil    
    if isHawks then
        addHawksLoadout(player)
    end
    
    modData.WildernessSurvivalStartingLoadoutApplied = true

    print("    applyMultiplayerStartingLoadout() - starting loadout applied for player " .. player:getUsername())
end

local function onClientCommand(module, command, player, args)
    if module ~= WildernessStartingLoadoutRules.MP_MODULE.NAME then
        return
    end

    if command == WildernessStartingLoadoutRules.MP_MODULE.EVENTS.APPLY_STARTING_LOADOUT then
        applyMultiplayerStartingLoadout(player)
    end
end

Events.OnClientCommand.Add(onClientCommand)