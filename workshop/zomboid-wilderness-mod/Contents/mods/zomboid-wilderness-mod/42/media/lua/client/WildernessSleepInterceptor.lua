require "WildernessSleepRules"

local function installSleepInterceptor()
    if WildernessSleepRules.originalOnSleepWalkToComplete ~= nil then
        return
    end

    local contextMenu = ISWorldObjectContextMenu
    WildernessSleepRules.originalOnSleepWalkToComplete = contextMenu.onSleepWalkToComplete

    contextMenu.onSleepWalkToComplete = function(playerIndex, bed)
        local player = getSpecificPlayer(playerIndex)
        if not WildernessSleepRules.isSleepShelterRuleEnabled() then
            WildernessSleepRules.originalOnSleepWalkToComplete(playerIndex, bed)
            return
        end

        if bed ~= nil and not WildernessSleepRules.canSleepAt(player, bed) then
            HaloTextHelper.addBadText(player, WildernessSleepRules.DENIAL_TEXT)
            return
        end

        WildernessSleepRules.originalOnSleepWalkToComplete(playerIndex, bed)
    end
end

Events.OnGameStart.Add(installSleepInterceptor)
