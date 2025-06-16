-- 4wsAdvance.lua - 2024.4.19 17:09 - advance rear wheel steering
-- by NZZ
-- version 0.0.3 alpha
-- final edit - 2025.5.19 20:37

local M = {}

local abs = math.abs
local sin = math.sin
local max = math.max
local min = math.min

local switchVelocity = nil
local ifRWS = 1

local judge = nil
local direction = nil

local function switch()
    ifRWS = not ifRWS
    if not ifRWS then
        gui.message({ txt = "Rear Wheel Steering Off" }, 5, "", "")
    else
        gui.message({ txt = "Rear Wheel Steering On" }, 5, "", "")
    end
end

local function onInit(jbeamData)
    ifRWS = true
    electrics.values['4wsAdvance'] = 0

    switchVelocity = (jbeamData.switchVelocity / 3.6) or 12.5
end

local function judgeUpdateSteer()
    if electrics.values.airspeed <= switchVelocity then
        if electrics.values['steering_input'] < 0.01 then
            direction = -1
        else
        end
    else
        if electrics.values['steering_input'] < 0.01 then
            direction = 1
        else
        end
    end
end

local function updateGFX(dt)
    if not electrics.values['steering_input'] then return end
    
    local steer

    judgeUpdateSteer()

    steer = direction * electrics.values['steering_input']
    local rwsTarget = sin(abs(steer) * 1.57) * -1 * fsign(steer)

    if ifRWS then
        rwsTarget = sin(abs(steer) * 1.57) * -1 * fsign(steer)
    else
        rwsTarget = 0
    end
    
    if electrics.values['4wsAdvance'] < rwsTarget then
        electrics.values['4wsAdvance'] = min(electrics.values['4wsAdvance'] + dt * 1.7, rwsTarget)
    elseif electrics.values['4wsAdvance'] > rwsTarget then
        electrics.values['4wsAdvance'] = max(electrics.values['4wsAdvance'] - dt * 1.7, rwsTarget)
    end

end

local function setParameters(parameters)
    local Val
    if parameters.val < 0.5 then
        Val = 0
        ifRWS = false
    else
        Val = 1
        ifRWS = true
    end
end

-- public interface
M.switchFWS = switch

M.onInit      = onInit
M.onReset     = onInit

M.init      = onInit
M.reset     = onInit

M.updateGFX = updateGFX
M.setParameters = setParameters

return M