require "WildernessSurvivalRules"
require "TimedActions/ISReadABook"

local RPG_MANUAL = "Base.RPGmanual"

local function isRPGManual(item)
    return item
        and item:getFullType() == RPG_MANUAL
end


-- =========================================================
-- Start reading
-- =========================================================

local originalStart = ISReadABook.start

function ISReadABook:start()
    originalStart(self)

    if isRPGManual(self.item) then
        sendClientCommand(
            self.character,
            WildernessSurvivalRules.RPG_SESSION_MODULE.NAME,
            WildernessSurvivalRules.RPG_SESSION_MODULE.EVENT_START,
            {}
        )
    end
end


-- =========================================================
-- Stop/cancel reading
-- =========================================================

local originalStop = ISReadABook.stop

function ISReadABook:stop()
    if isRPGManual(self.item) then
        sendClientCommand(
            self.character,
            WildernessSurvivalRules.RPG_SESSION_MODULE.NAME,
            WildernessSurvivalRules.RPG_SESSION_MODULE.EVENT_STOP,
            {}
        )
    end

    originalStop(self)
end


-- =========================================================
-- Finished reading normally
-- =========================================================

local originalPerform = ISReadABook.perform

function ISReadABook:perform()
    if isRPGManual(self.item) then
        sendClientCommand(
            self.character,
            WildernessSurvivalRules.RPG_SESSION_MODULE.NAME,
            WildernessSurvivalRules.RPG_SESSION_MODULE.EVENT_STOP,
            {}
        )
    end

    originalPerform(self)
end