WildernessSurvivalRules = WildernessSurvivalRules or {}

WildernessSurvivalRules.DENIAL_TEXT = "You can't sleep here. Find shelter in the wilderness or a structure built by survivors."
WildernessSurvivalRules.SANDBOX_TABLE = "WildernessSurvivor"

WildernessSurvivalRules.COMPASS_MINIMAP_MODES = {
    [1] = "Disabled",
    [2] = "Main Inventory",
    [3] = "Anywhere",
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