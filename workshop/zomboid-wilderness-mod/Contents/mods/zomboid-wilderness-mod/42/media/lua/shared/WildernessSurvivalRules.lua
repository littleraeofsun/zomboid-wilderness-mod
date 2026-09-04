WildernessSurvivalRules = WildernessSurvivalRules or {}

WildernessSurvivalRules.DENIAL_TEXT = "You can't sleep here. Find shelter in the wilderness or a structure built by survivors."
WildernessSurvivalRules.SANDBOX_TABLE = "WildernessSurvivor"
WildernessSurvivalRules.STARTING_ITEMS_PRESETS = {
    [1] = "Vanilla",
    [2] = "Wilderness Glamper",
    [3] = "Stranded Hiker",
    [4] = "Naked and Afraid",
}
WildernessSurvivalRules.COMPASS_MINIMAP_MODES = {
    [1] = "Disabled",
    [2] = "Main Inventory",
    [3] = "Anywhere",
}
WildernessSurvivalRules.STARTING_ITEMS = {
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

function WildernessSurvivalRules.getSandboxSettings()
    if SandboxVars == nil then
        return nil
    end

    return SandboxVars[WildernessSurvivalRules.SANDBOX_TABLE]
end

function WildernessSurvivalRules.isSleepShelterRuleEnabled()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings == nil or settings.EnableSleepShelterRule ~= false
end

function WildernessSurvivalRules.isTent(object)
    return object ~= nil and object:isTent()
end

function WildernessSurvivalRules.isTentAt(square)
    if square == nil then
        return false
    end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        if WildernessSurvivalRules.isTent(objects:get(index)) then
            return true
        end
    end

    return false
end

function WildernessSurvivalRules.isPlayerBuiltShelter(square)
    if square == nil then
        return false
    end

    local region = IsoRegions.getIsoWorldRegion(square:getX(), square:getY(), square:getZ())
    return region ~= nil
        and region:isPlayerRoom()
        and region:isFullyRoofed()
        and region:getBuildingDef() == nil
end

function WildernessSurvivalRules.canSleepAt(player, bed)
    local square = player:getCurrentSquare()
    if bed == nil then
        return true
    end

    if not WildernessSurvivalRules.isSleepShelterRuleEnabled() then
        return true
    end

    return WildernessSurvivalRules.isTent(bed)
        or WildernessSurvivalRules.isTentAt(square)
        or WildernessSurvivalRules.isPlayerBuiltShelter(square)
end

function WildernessSurvivalRules.getStartingItemsPreset()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    if settings ~= nil then
        local preset = settings.StartingItemsPreset
        if WildernessSurvivalRules.STARTING_ITEMS_PRESETS[preset] ~= nil then
            return WildernessSurvivalRules.STARTING_ITEMS_PRESETS[preset]
        end
        if WildernessSurvivalRules.STARTING_ITEMS[preset] ~= nil or preset == "Vanilla" then
            return preset
        end
    end

    return "Vanilla"
end

function WildernessSurvivalRules.shouldUseCustomStartingItems()
    return WildernessSurvivalRules.getStartingItemsPreset() ~= "Vanilla"
end

function WildernessSurvivalRules.getStartingItemsForPreset()
    local preset = WildernessSurvivalRules.getStartingItemsPreset()
    return WildernessSurvivalRules.STARTING_ITEMS[preset]
end

function WildernessSurvivalRules.getCompassMinimapMode()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    if settings ~= nil then
        local mode = settings.CompassOpensMinimap
        if WildernessSurvivalRules.COMPASS_MINIMAP_MODES[mode] ~= nil then
            return WildernessSurvivalRules.COMPASS_MINIMAP_MODES[mode]
        end
        if mode == "Disabled" or mode == "Main Inventory" or mode == "Anywhere" then
            return mode
        end
    end

    return "Disabled"
end
