WildernessStartingLoadoutRules = WildernessStartingLoadoutRules or {}

require "WildernessSurvivalRules"

WildernessStartingLoadoutRules.MP_MODULE = {
    NAME = WildernessSurvivalRules.SANDBOX_TABLE .. ".WildernessStartingLoadout",
    EVENTS = {
        APPLY_STARTING_LOADOUT = "ApplyStartingLoadout",
    },
}

WildernessStartingLoadoutRules.STARTING_ITEMS_PRESETS = {
    [1] = "Vanilla",
    [2] = "Wilderness Glamper",
    [3] = "Stranded Hiker",
    [4] = "Naked and Afraid",
}
WildernessStartingLoadoutRules.STARTING_ITEMS = {
    ["Wilderness Glamper"] = {
        "Base.Bag_BigHikingBag",
        "Base.TentGreen_Packed",
        "Base.SleepingBag_Green_Packed",
        "Base.Multitool",
        "Base.Pot",
        "Base.WaterBottle",
        "Base.GranolaBar",
        "Base.GranolaBar",
        "Base.Bandage",
        "Base.Bandaid",
        "Base.Bandaid",
        "Base.MagnesiumFirestarter",
        "Base.CompassDirectional",
        "Base.WaterPurificationTablets",
        "Base.InsectRepellent",
        "Base.Spork",
        "Base.Torch",
        "Base.Battery",
        "Base.DigitalWatch2",
     },
    ["Stranded Hiker"] = { 
        "Base.Bag_NormalHikingBag",
        "Base.Tarp",
        "Base.HuntingKnife",
        "Base.Pot",
        "Base.WaterBottle",
        "Base.GranolaBar",
    },
    ["Naked and Afraid"] = {},
}

function WildernessStartingLoadoutRules.getStartingItemsPreset()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    if settings ~= nil then
        local preset = settings.StartingItemsPreset
        if WildernessStartingLoadoutRules.STARTING_ITEMS_PRESETS[preset] ~= nil then
            return WildernessStartingLoadoutRules.STARTING_ITEMS_PRESETS[preset]
        end
        if WildernessStartingLoadoutRules.STARTING_ITEMS[preset] ~= nil or preset == "Vanilla" then
            return preset
        end
    end

    return "Vanilla"
end

function WildernessStartingLoadoutRules.shouldUseCustomStartingItems()
    return WildernessStartingLoadoutRules.getStartingItemsPreset() ~= "Vanilla"
end

function WildernessStartingLoadoutRules.getStartingItemsForPreset()
    local preset = WildernessStartingLoadoutRules.getStartingItemsPreset()
    return WildernessStartingLoadoutRules.STARTING_ITEMS[preset]
end

function WildernessStartingLoadoutRules.removeAllNonClothingItems(player)
    local inventory = player:getInventory()
    local items = inventory:getItems()
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if not item:IsClothing() then
            inventory:Remove(item)
        end
    end
end

function WildernessStartingLoadoutRules.stripAllClothing(player)
    local clothing = player:getWornItems()
    local count = clothing:size()
    for index = count - 1, 0, -1 do
        player:removeWornItem(clothing:get(index):getItem())
    end
end