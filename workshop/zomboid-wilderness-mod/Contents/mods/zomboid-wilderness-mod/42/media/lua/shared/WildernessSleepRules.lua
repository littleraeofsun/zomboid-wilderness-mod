WildernessSleepRules = WildernessSleepRules or {}

WildernessSleepRules.DENIAL_TEXT = "You can't sleep here. Find shelter in the wilderness or a structure built by survivors."
WildernessSleepRules.SANDBOX_OPTION = "zomboid-wilderness-mod.EnableSleepShelterRule"
WildernessSleepRules.STARTING_ITEMS_OPTION = "zomboid-wilderness-mod.StartingItemsPreset"
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

    local sandboxEnabled = true
    if SandboxVars ~= nil and SandboxVars["zomboid-wilderness-mod"] ~= nil then
        local settings = SandboxVars["zomboid-wilderness-mod"]
        if settings.EnableSleepShelterRule ~= nil then
            sandboxEnabled = settings.EnableSleepShelterRule
        end
    end

    if not sandboxEnabled then
        return true
    end

    return WildernessSleepRules.isTent(bed)
        or WildernessSleepRules.isTentAt(square)
        or WildernessSleepRules.isPlayerBuiltShelter(square)
end

function WildernessSleepRules.getStartingItemsPreset()
    if SandboxVars ~= nil and SandboxVars["zomboid-wilderness-mod"] ~= nil then
        local settings = SandboxVars["zomboid-wilderness-mod"]
        if settings.StartingItemsPreset ~= nil then
            return settings.StartingItemsPreset
        end
    end

    return "Default"
end

function WildernessSleepRules.shouldUseCustomStartingItems()
    return WildernessSleepRules.getStartingItemsPreset() ~= "Default"
end

function WildernessSleepRules.getStartingItemsForPreset()
    local preset = WildernessSleepRules.getStartingItemsPreset()
    return WildernessSleepRules.STARTING_ITEMS[preset]
end
