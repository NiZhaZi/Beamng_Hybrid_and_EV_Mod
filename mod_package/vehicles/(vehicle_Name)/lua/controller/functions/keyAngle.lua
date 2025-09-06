local M = {}

local targetAngle = nil

local function updateGFX(dt)
    local ignitionLevel = electrics.values.ignitionLevel
    if ignitionLevel then
        if ignitionLevel == 0 then
            targetAngle = 0
        elseif ignitionLevel == 1 then
            targetAngle = 45
        elseif ignitionLevel == 2 then
            targetAngle = 90
        elseif ignitionLevel == 3 then
            targetAngle = 135
        end
    end

    local spinningSpeed = 150 * dt
    if electrics.values.keyAngle < targetAngle then
        electrics.values.keyAngle = math.min(electrics.values.keyAngle + spinningSpeed, targetAngle)
    elseif electrics.values.keyAngle > targetAngle then
        electrics.values.keyAngle = math.max(electrics.values.keyAngle - spinningSpeed, targetAngle)
    end

end

local function init()
    targetAngle = 0
    electrics.values.keyAngle = 0
end

local function reset()
    targetAngle = 0
    electrics.values.keyAngle = 0
end

M.onInit = init
M.onReset = reset
M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M