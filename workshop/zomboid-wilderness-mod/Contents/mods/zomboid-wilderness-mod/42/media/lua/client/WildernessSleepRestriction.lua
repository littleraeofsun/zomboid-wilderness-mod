require "WildernessSurvivalRules"

local function installSleepRestriction()
    if WildernessSurvivalRules.originalOnSleepWalkToComplete ~= nil then
        return
    end

    local contextMenu = ISWorldObjectContextMenu
    WildernessSurvivalRules.originalOnSleepWalkToComplete = contextMenu.onSleepWalkToComplete

    contextMenu.onSleepWalkToComplete = function(playerIndex, bed)
        local player = getSpecificPlayer(playerIndex)
        if not WildernessSurvivalRules.isSleepShelterRuleEnabled() then
            WildernessSurvivalRules.originalOnSleepWalkToComplete(playerIndex, bed)
            return
        end

        if bed ~= nil and not WildernessSurvivalRules.canSleepAt(player, bed) then
            HaloTextHelper.addBadText(player, WildernessSurvivalRules.DENIAL_TEXT)
            return
        end

        WildernessSurvivalRules.originalOnSleepWalkToComplete(playerIndex, bed)
    end
end

Events.OnGameStart.Add(installSleepRestriction)
