local function setStartDateAndTime()
    local gameTime = GameTime:getInstance()
    if gameTime == nil then
        return
    end

    gameTime:setStartDay(1)
    gameTime:setStartMonth(4)
    gameTime:setStartYear(1993)
    gameTime:setStartTime(7)
end

Events.OnGameStart.Add(setStartDateAndTime)
