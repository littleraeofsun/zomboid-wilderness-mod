require "WildernessSleepRules"

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

local function giveStartingItems(playerIndex, player)
    if player == nil then
        return
    end

    local preset = WildernessSleepRules.getStartingItemsPreset()
    if preset == "Vanilla" then
        return
    end

    removeAllNonClothingItems(player)

    local items = WildernessSleepRules.getStartingItemsForPreset()
    if items ~= nil then
        for index = 1, #items do
            player:getInventory():AddItem(items[index])
        end
    end

    if preset == "Wilderness Glamper" then
        local wipes = player:getInventory():AddItem("Base.AlcoholWipes")
        wipes:setUsedDelta(0.4)
    end

    if preset == "Naked and Afraid" then
        stripAllClothing(player)
    end
end

Events.OnCreatePlayer.Add(giveStartingItems)
