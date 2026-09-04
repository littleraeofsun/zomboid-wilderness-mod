WildernessSleepRules = WildernessSleepRules or {}

WildernessSleepRules.DENIAL_TEXT = "You can't sleep here. Find shelter in the wilderness or a structure built by survivors."
WildernessSleepRules.SANDBOX_TABLE = "WildernessSurvivor"
WildernessSleepRules.STARTING_ITEMS_PRESETS = {
    [1] = "Vanilla",
    [2] = "Wilderness Glamper",
    [3] = "Stranded Hiker",
    [4] = "Naked and Afraid",
}
WildernessSleepRules.STARTING_ITEMS = {
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

function WildernessSleepRules.getSandboxSettings()
    if SandboxVars == nil then
        return nil
    end

    return SandboxVars[WildernessSleepRules.SANDBOX_TABLE]
end

function WildernessSleepRules.isSleepShelterRuleEnabled()
    local settings = WildernessSleepRules.getSandboxSettings()
    return settings == nil or settings.EnableSleepShelterRule ~= false
end

function WildernessSleepRules.isTent(object)
    return object ~= nil and object:isTent()
end

function WildernessSleepRules.isTentAt(square)
    if square == nil then
        return false
    end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        if WildernessSleepRules.isTent(objects:get(index)) then
            return true
        end
    end

    return false
end

function WildernessSleepRules.isPlayerBuiltShelter(square)
    if square == nil then
        return false
    end

    local region = IsoRegions.getIsoWorldRegion(square:getX(), square:getY(), square:getZ())
    return region ~= nil
        and region:isPlayerRoom()
        and region:isFullyRoofed()
        and region:getBuildingDef() == nil
end

function WildernessSleepRules.canSleepAt(player, bed)
    local square = player:getCurrentSquare()
    if bed == nil then
        return true
    end

    if not WildernessSleepRules.isSleepShelterRuleEnabled() then
        return true
    end

    return WildernessSleepRules.isTent(bed)
        or WildernessSleepRules.isTentAt(square)
        or WildernessSleepRules.isPlayerBuiltShelter(square)
end

function WildernessSleepRules.getStartingItemsPreset()
    local settings = WildernessSleepRules.getSandboxSettings()
    if settings ~= nil then
        local preset = settings.StartingItemsPreset
        if WildernessSleepRules.STARTING_ITEMS_PRESETS[preset] ~= nil then
            return WildernessSleepRules.STARTING_ITEMS_PRESETS[preset]
        end
        if WildernessSleepRules.STARTING_ITEMS[preset] ~= nil or preset == "Vanilla" then
            return preset
        end
    end

    return "Vanilla"
end

function WildernessSleepRules.shouldUseCustomStartingItems()
    return WildernessSleepRules.getStartingItemsPreset() ~= "Vanilla"
end

function WildernessSleepRules.getStartingItemsForPreset()
    local preset = WildernessSleepRules.getStartingItemsPreset()
    return WildernessSleepRules.STARTING_ITEMS[preset]
end
