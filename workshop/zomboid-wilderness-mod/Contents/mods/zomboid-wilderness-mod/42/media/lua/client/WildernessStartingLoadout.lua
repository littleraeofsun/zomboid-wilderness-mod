require "WildernessSurvivalRules"

local function removeAllNonClothingItems(player)
    local inventory = player:getInventory()
    local items = inventory:getItems()
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if not item:IsClothing() then
            inventory:Remove(item)
        end
    end
end

local function stripAllClothing(player)
    local clothing = player:getWornItems()
    local count = clothing:size()
    for index = count - 1, 0, -1 do
        player:removeWornItem(clothing:get(index):getItem())
    end
end

local function addLoadoutWithBackpack(player, items, backpackType)
    local inventory = player:getInventory()
    local backpack = inventory:AddItem(backpackType)
    player:setWornItem("Back", backpack)

    local backpackInventory = backpack:getItemContainer()
    for index = 1, #items do
        local itemType = items[index]
        if itemType ~= backpackType then
            local item = inventory:AddItem(itemType)
            if itemType ~= "Base.WaterBottle" then
                backpackInventory:AddItem(item)
            end
        end
    end

    return backpackInventory
end

local function addHawksLoadout(player, backpackInventory)
    local inventory = player:getInventory()
    local chickenFeather = inventory:AddItem("Base.ChickenFeather")
    local cudgel = inventory:AddItem("Base.Cudgel_Nails")
    local rpgBook = inventory:AddItem("Base.RPGmanual")
    local dicePouch = inventory:AddItem("Base.SeedBag")
    local pouchInventory = dicePouch:getInventory()
    pouchInventory:AddItem("Base.Dice_4")
    pouchInventory:AddItem("Base.Dice_6")
    pouchInventory:AddItem("Base.Dice_8")
    pouchInventory:AddItem("Base.Dice_10")
    pouchInventory:AddItem("Base.Dice_12")
    pouchInventory:AddItem("Base.Dice_20")
    pouchInventory:AddItem("Base.Dice_00")

    if backpackInventory ~= nil then
        backpackInventory:AddItem(chickenFeather)
        backpackInventory:AddItem(cudgel)
        backpackInventory:AddItem(rpgBook)
        backpackInventory:AddItem(dicePouch)
    end
end

local function applyStartingLoadout(playerIndex, player)
    if player == nil then
        return
    end

    local username = player:getUsername()
    local isHawks = username ~= nil and string.find(string.lower(username), "hawks", 1, true) ~= nil
    local preset = WildernessSurvivalRules.getStartingItemsPreset()
    if preset == "Vanilla" then
        return
    end

    removeAllNonClothingItems(player)

    local items = WildernessSurvivalRules.getStartingItemsForPreset()
    local backpackInventory = nil
    if items ~= nil then
        if preset == "Wilderness Glamper" then
            backpackInventory = addLoadoutWithBackpack(player, items, "Base.Bag_BigHikingBag")
            local wipes = backpackInventory:AddItem("Base.AlcoholWipes")
            wipes:setUsedDelta(0.4)
        elseif preset == "Stranded Hiker" then
            backpackInventory = addLoadoutWithBackpack(player, items, "Base.Bag_NormalHikingBag")
        else
            for index = 1, #items do
                player:getInventory():AddItem(items[index])
            end
        end
    end

    if isHawks then
        addHawksLoadout(player, backpackInventory)
    end

    if preset == "Naked and Afraid" then
        stripAllClothing(player)
    end
end

Events.OnCreatePlayer.Add(applyStartingLoadout)
