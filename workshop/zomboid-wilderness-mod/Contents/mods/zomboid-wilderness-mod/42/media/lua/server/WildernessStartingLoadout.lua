require "WildernessStartingLoadoutRules"

local LOADOUT_STATE_KEY = "WildernessSurvival.StartingLoadouts"

local function hasStartingLoadout(player)
    local username = player:getUsername()
    if not username then
        return false
    end

    local appliedLoadouts = ModData.getOrCreate(LOADOUT_STATE_KEY)
    return appliedLoadouts[username] == true
end

local function markStartingLoadoutApplied(player)
    local username = player:getUsername()
    if not username then
        return
    end

    local appliedLoadouts = ModData.getOrCreate(LOADOUT_STATE_KEY)
    appliedLoadouts[username] = true
    ModData.transmit(LOADOUT_STATE_KEY)
end

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
        return
    end

    local username = player:getUsername()
    if not username then
        return
    end

    if hasStartingLoadout(player) then
        return
    end
        
    removeAllNonClothingItems(player)

    local preset = WildernessStartingLoadoutRules.getStartingItemsPreset()
    if preset == "Naked and Afraid" then
        WildernessStartingLoadoutRules.stripAllClothing(player)
    end    

    local startingItems = WildernessStartingLoadoutRules.getStartingItemsForPreset(preset)
    if startingItems == nil then
        return
    end

    for _, item in ipairs(startingItems) do
        addItem(player:getInventory(), item)
    end

    -- Hawks clause <3
    local isHawks = true -- username ~= nil and string.find(string.lower(username), "hawks", 1, true) ~= nil
    if isHawks then
        addHawksLoadout(player)
    end
    
    markStartingLoadoutApplied(player)
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
