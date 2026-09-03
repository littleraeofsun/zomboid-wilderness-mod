WildernessSleepRules = WildernessSleepRules or {}

WildernessSleepRules.DENIAL_TEXT = "You can't sleep here. Find shelter in the wilderness or a structure built by survivors."
WildernessSleepRules.SANDBOX_OPTION = "zomboid-wilderness-mod.EnableSleepShelterRule"

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
