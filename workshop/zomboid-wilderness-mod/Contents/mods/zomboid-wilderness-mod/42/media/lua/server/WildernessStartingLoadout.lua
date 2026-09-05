require "WildernessStartingLoadoutRules"

local function addItem(inventory, itemType)
    local item = inventory:AddItem(itemType)
    if item then
        sendAddItemToContainer(inventory, item)
    end
    return item
end

local function removeAllNonClothingItems(player)
    local inventory = player:getInventory()
    local items = inventory:getItems()
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if not item:IsClothing() then
            inventory:Remove(item)
            sendRemoveItemFromContainer(inventory, item)
        end
    end
end

local function addHawksLoadout(player)
    local inventory = player:getInventory()
    addItem(inventory, "Base.ChickenFeather")
    addItem(inventory, "Base.Cudgel_Nails")
    addItem(inventory, "Base.RPGmanual")
    local dicePouch = addItem(inventory, "Base.SeedBag")
    local pouchInventory = dicePouch:getInventory()
    addItem(pouchInventory, "Base.Dice_4")
    addItem(pouchInventory, "Base.Dice_6")
    addItem(pouchInventory, "Base.Dice_8")
    addItem(pouchInventory, "Base.Dice_10")
    addItem(pouchInventory, "Base.Dice_12")
    addItem(pouchInventory, "Base.Dice_20")
    addItem(pouchInventory, "Base.Dice_00")
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
        
    removeAllNonClothingItems(player)

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
        addItem(player:getInventory(), item)
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
