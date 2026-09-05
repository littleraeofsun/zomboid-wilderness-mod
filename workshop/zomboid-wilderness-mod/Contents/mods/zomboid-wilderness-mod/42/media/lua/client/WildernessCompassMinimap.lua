require "WildernessSurvivalRules"
require "ISUI/Maps/ISMiniMap"

local COMPASS_TYPE = "Base.CompassDirectional"

local playerHadCompass = {}

local function isCompass(item)
    if not item then
        return false
    end

    return item:getFullType() == COMPASS_TYPE
end

local function playerHasCompass(player, recursive)
    if not player then
        return false
    end

    if isCompass(player:getPrimaryHandItem())
    or isCompass(player:getSecondaryHandItem()) then
        return true
    end

    local inventory = player:getInventory()

    if recursive then
        if inventory:containsTypeRecurse(COMPASS_TYPE) then
            return true
        end
    elseif inventory:containsType(COMPASS_TYPE) then
        return true
    end

    return false
end

local function setMiniMapVisible(playerNum, makeVisible)
    local minimap = getPlayerMiniMap(playerNum)

    if not minimap then
        return
    end

    local isVisible = minimap:isReallyVisible()

    -- Already in desired state
    if isVisible == makeVisible then
        return
    end

    if makeVisible then
        minimap:addToUIManager()
    else
        if minimap.joyfocus then
            minimap:clearJoypadFocus(minimap.joyfocus)
            setJoypadFocus(playerNum, nil)
        end

        minimap:removeFromUIManager()
    end

    -- Match vanilla persistence behavior for player 0
    if playerNum == 0 then
        local settings = WorldMapSettings.getInstance()
        settings:setBoolean("MiniMap.StartVisible", makeVisible)
    end
end

local function update(player)
    if not player then
        return
    end

    local playerNum = player:getPlayerNum()

    local mode = WildernessSurvivalRules.getCompassMinimapMode()
    local hasCompass = playerHasCompass(player, mode == "Anywhere")

    -- Only touch the UI when the state actually changed.
    if hasCompass == playerHadCompass[playerNum] then
        return
    end

    print("WildernessSurvivalRules: compass state changed to " .. tostring(hasCompass) .. " for player " .. tostring(player))

    playerHadCompass[playerNum] = hasCompass
    setMiniMapVisible(playerNum, hasCompass)
end

local function onCreatePlayer(playerNum, player)
    print("WildernessSurvivalRules: onCreatePlayer() called for playerNum " .. tostring(playerNum) .. " and player " .. tostring(player))
    playerHadCompass[playerNum] = false
    setMiniMapVisible(playerNum, false)
    update(player)
end

local function onInventoryRefresh(inventoryPage, reason)
    print("WildernessSurvivalRules: onInventoryRefresh() called for inventoryPage " .. tostring(inventoryPage) .. " and reason " .. tostring(reason))
    local player = getSpecificPlayer(0)
    update(player)
end

local function onMinute()
    local player = getSpecificPlayer(0)
    update(player)
end

local function registerCompassEvents()
    if WildernessSurvivalRules.getCompassMinimapMode() == "Disabled" then
        print("WildernessSurvivalRules: Compass minimap mode is disabled, skipping event registration.")
        return
    end

    Events.OnCreatePlayer.Add(onCreatePlayer)
    Events.OnRefreshInventoryWindowContainers.Add(onInventoryRefresh)
    Events.EveryOneMinute.Add(onMinute)
    print("WildernessSurvivalRules: Compass minimap mode is enabled, registered events.")
end

Events.OnGameStart.Add(registerCompassEvents)

--========================================================
-- ISMiniMap overrides
--========================================================
local originalIsMiniMapAllowed = ISMiniMap.IsAllowed

function ISMiniMap.IsAllowed()
    -- Preserve vanilla restrictions first.
    if not originalIsMiniMapAllowed() then
        return false
    end

    local mode = WildernessSurvivalRules.getCompassMinimapMode()
    if mode == "Disabled" then
        return true -- vanilla behavior would be true here, so return true
    end

    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    return playerHasCompass(player, mode == "Anywhere")
end

local originalToggleMiniMap = ISMiniMap.ToggleMiniMap

function ISMiniMap.ToggleMiniMap(playerNum)
    local mode = WildernessSurvivalRules.getCompassMinimapMode()

    if mode ~= "Disabled" then
        local player = getSpecificPlayer(playerNum)

        if not player
        or not playerHasCompass(player, mode == "Anywhere") then
            return
        end
    end

    return originalToggleMiniMap(playerNum)
end