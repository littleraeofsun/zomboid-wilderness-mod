RPGSessionRules = RPGSessionRules or {}

require "WildernessSurvivalRules"

RPGSessionRules.MP_MODULE = {
    NAME = WildernessSurvivalRules.SANDBOX_TABLE .. ".RPGSession",
    EVENTS = {
        READING_START = "RPGReadingStart",
        READING_STOP = "RPGReadingStop",
        READING_COMPLETE = "RPGReadingComplete",
    },
}

-- =========================================================
-- Does this player possess any usable die?
--
-- containsTypeRecurse() means dice inside backpacks,
-- pouches, etc. still count.
-- =========================================================
function RPGSessionRules.playerHasDice(player)
    if not player then
        return false
    end

    local inventory = player:getInventory()
    local DICE_TYPES = {
        "Base.Dice",
        "Base.Dice_4",
        "Base.Dice_6",
        "Base.Dice_8",
        "Base.Dice_10",
        "Base.Dice_12",
        "Base.Dice_20",
        "Base.Dice_00",
        "Base.Dice_Bone",
        "Base.Dice_Wood",
    }

    for _, diceType in ipairs(DICE_TYPES) do
        if inventory:containsTypeRecurse(diceType) then
            return true
        end
    end

    return false
end

function RPGSessionRules.isRPGSessionEnabled()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings ~= nil and settings.EnableRPGSession == true
end

function RPGSessionRules.getRPGManualReadTime()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings ~= nil and settings.RPGManualReadTime or 30
end

function RPGSessionRules.getRPGSessionRange()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings ~= nil and settings.RPGSessionRange or 3
end

function RPGSessionRules.getRPGSessionInterval()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings ~= nil and settings.RPGSessionInterval or 5
end

function RPGSessionRules.getRPGSessionUnhappinessReduction()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings ~= nil and settings.RPGSessionUnhappinessReduction or 3
end

function RPGSessionRules.getRPGSessionStressReduction()
    local settings = WildernessSurvivalRules.getSandboxSettings()
    return settings ~= nil and settings.RPGSessionStressReduction or 2
end