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

local function enforceInitialMiniMapVisibility(playerNum, player)
    local attempts = 0

    local function initialize()
        attempts = attempts + 1

        if WildernessSurvivalRules.getCompassMinimapMode() == "Disabled" then
            Events.OnTick.Remove(initialize)
        elseif getPlayerMiniMap(playerNum) ~= nil then
            Events.OnTick.Remove(initialize)
            playerHadCompass[playerNum] = nil
            update(player)
        elseif attempts >= 100 then
            Events.OnTick.Remove(initialize)
        end
    end

    Events.OnTick.Add(initialize)
end

local function onCreatePlayer(playerNum, player)
    if not player then
        return
    end

    print("WildernessSurvivalRules: onCreatePlayer() called for playerNum " .. tostring(playerNum) .. " and player " .. tostring(player))
    enforceInitialMiniMapVisibility(playerNum, player)
end

local function onInventoryRefresh(inventoryPage, reason)
    -- A refresh emits begin, beforeFloor, buttonsAdded, and end. Only the final
    -- character-inventory phase can reflect a compass change.
    if reason ~= "end" or not inventoryPage or not inventoryPage.onCharacter then
        return
    end

    update(getSpecificPlayer(inventoryPage.player))
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

    Events.OnRefreshInventoryWindowContainers.Add(onInventoryRefresh)
    Events.EveryOneMinute.Add(onMinute)

    -- The minimap can be created after player and game-start events.
    local player = getSpecificPlayer(0)
    if player then
        enforceInitialMiniMapVisibility(0, player)
    end
    print("WildernessSurvivalRules: Compass minimap mode is enabled, registered events.")
end

-- ISMiniMap registers its player-creation handler while it is required above, so this
-- handler runs afterward and can hide the vanilla-created minimap before it is drawn.
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnGameStart.Add(registerCompassEvents)

--========================================================
-- ISMiniMap overrides
--========================================================
local originalIsMiniMapAllowed = ISMiniMap.IsAllowed

function ISMiniMap.IsAllowed()
    -- This controls vanilla minimap creation. Possession is enforced through visibility
    -- and ToggleMiniMap below, after vanilla has created the UI instance.
    return originalIsMiniMapAllowed()
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