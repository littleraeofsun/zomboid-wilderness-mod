require "WildernessSurvivalRules"
require "ISUI/Maps/ISMiniMap"

local COMPASS_TYPES = {
    ["Base.Compass"] = true,
    ["Base.CompassDirectional"] = true,
}

local function isCompass(item)
    return item ~= nil and COMPASS_TYPES[item:getFullType()] == true
end

local function containerHasCompass(container, includeContents)
    if container == nil then
        return false
    end

    local items = container:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if isCompass(item) then
            return true
        end

        if includeContents and containerHasCompass(item:getItemContainer(), true) then
            return true
        end
    end

    return false
end

local function playerCanDisplayMinimap(player)
    local mode = WildernessSurvivalRules.getCompassMinimapMode()
    if mode == "Disabled" then
        return true
    end

    if player == nil then
        return false
    end

    return containerHasCompass(player:getInventory(), mode == "Anywhere")
end

local vanillaToggleMiniMap = ISMiniMap.ToggleMiniMap
function ISMiniMap.ToggleMiniMap(playerNum)
    local player = getSpecificPlayer(playerNum)
    if not playerCanDisplayMinimap(player) then
        return
    end

    vanillaToggleMiniMap(playerNum)
end

local vanillaFocusMiniMap = ISMiniMap.FocusMiniMap
function ISMiniMap.FocusMiniMap(playerNum)
    local player = getSpecificPlayer(playerNum)
    if not playerCanDisplayMinimap(player) then
        return
    end

    vanillaFocusMiniMap(playerNum)
end

local function hideMinimap(playerNum, minimap)
    if minimap.joyfocus then
        minimap:clearJoypadFocus(minimap.joyfocus)
        setJoypadFocus(playerNum, nil)
    end

    minimap:removeFromUIManager()
end

local tickCount = 0
local function hideMinimapsWithoutCompass()
    tickCount = tickCount + 1
    if tickCount % 15 ~= 0 then
        return
    end

    for playerNum = 0, 3 do
        local player = getSpecificPlayer(playerNum)
        if player ~= nil and not playerCanDisplayMinimap(player) then
            local minimap = getPlayerMiniMap(playerNum)
            if minimap ~= nil and minimap:isReallyVisible() then
                hideMinimap(playerNum, minimap)
            end
        end
    end
end

Events.OnTick.Add(hideMinimapsWithoutCompass)
