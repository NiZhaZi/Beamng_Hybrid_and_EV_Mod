-- lights.lua - 2025.6.12 17:37 - lights control
-- by NZZ
-- version 0.0.5 alpha
-- final edit - 2025.6.12 18:17

-- Full files at https://github.com/NiZhaZi/Beamng_Hybrid_and_EV_Mod

local M = {}

local lightSign = {
    saftyLight = nil,
    fogLight = nil,
    muitiLightL = nil,
    muitiLightR = nil
}

-- safty light
local light1 = nil
local light2 = nil
local t1 = nil
local t2 = nil
local range1 = nil
local timerange = nil

local lightNum = nil
local signalDelayL = 0
local signalDelayR = 0
local runningBegin = 0
local flowLightType = nil

local autoDrive = nil

local function updateGFX(dt)

    local ifIgnition
    if electrics.values.ignitionLevel == 2 then
        ifIgnition = 1
    else
        ifIgnition = 0
    end

    -- safty light
    -- if timerange < 4 then
    --     t1 = t1 + dt
    --     if t1 >= 0.1 then
    --         light1 = 1
    --         t1 = 0
    --         timerange = timerange + 1
    --     else
    --         light1 = 0
    --     end
    -- else
    --     light1 = 0
    --     t2 = t2 + dt
    --     if t2 >= 0.5 then
    --         timerange = 0
    --         t2 = 0
    --     end
    -- end
    -- electrics.values.saftyLight = light1 * ifIgnition * lightSign

    -- fog light
    -- electrics.values.fogLight = lightSign * ifIgnition

    -- muitilight
    if electrics.values.signal_left_input == 1 then
        electrics.values.muitiLightL = electrics.values.signal_L * 2

        electrics.values.mlrunnigL = 0
        electrics.values.mlsignalL = electrics.values.signal_L
    else
        electrics.values.muitiLightL = electrics.values.running

        electrics.values.mlrunnigL = electrics.values.running
        electrics.values.mlsignalL = 0
    end

    if electrics.values.signal_right_input == 1 then
        electrics.values.muitiLightR = electrics.values.signal_R * 2

        electrics.values.mlrunnigR = 0
        electrics.values.mlsignalR = electrics.values.signal_R
    else
        electrics.values.muitiLightR = electrics.values.running

        electrics.values.mlrunnigR = electrics.values.running
        electrics.values.mlsignalR = 0
    end

    -- running light 2

    local devide = 0.4 / (lightNum + 1)
    local devideR = 0.6 / (lightNum + 1)

    if electrics.values.ignitionLevel == 2 and runningBegin < 0.6 then
        runningBegin = math.min(runningBegin + dt, 0.6)
    end

    if electrics.values.ignitionLevel ~= 2 then
        runningBegin = 0
    end 

    -- flow light

    if electrics.values.signal_L == 1 then
        signalDelayL = signalDelayL + dt
    else
        signalDelayL = 0
    end

    if electrics.values.signal_left_input == 1 then

        for i = 0, lightNum - 1 do
            local lightStr = "muitiLightL" .. tostring(i)
            electrics.values[lightStr] = 0
            if signalDelayL > devide * i then
                electrics.values[lightStr] = 2
            end
        end

    else

        for i = 0, lightNum + 2 do
            local lightStr = "muitiLightL" .. tostring(i)
            local lightStr2 = "muitiLightL" .. tostring(i - 3)
            electrics.values[lightStr] = 0
            if flowLightType == 1 then
                if runningBegin > devide * i then
                    electrics.values[lightStr] = electrics.values.running
                end
            elseif flowLightType == 2 then
                if runningBegin >= 0.55 then
                    electrics.values[lightStr] = electrics.values.running
                elseif runningBegin > devide * i then
                    electrics.values[lightStr] = electrics.values.running
                    electrics.values[lightStr2] = 0
                end
            end
        end

    end

    if electrics.values.signal_R == 1 then
        signalDelayR = signalDelayR + dt
    else
        signalDelayR = 0
    end

    if electrics.values.signal_right_input == 1 then

        for i = 0, lightNum - 1 do
            local lightStr = "muitiLightR" .. tostring(i)
            electrics.values[lightStr] = 0
            if signalDelayR > devide * i then
                electrics.values[lightStr] = 2
            end
        end

    else

        for i = 0, lightNum + 2 do
            local lightStr = "muitiLightR" .. tostring(i)
            local lightStr2 = "muitiLightR" .. tostring(i - 3)
            electrics.values[lightStr] = 0
            if flowLightType == 1 then
                if runningBegin > devide * i then
                    electrics.values[lightStr] = electrics.values.running
                end
            elseif flowLightType == 2 then
                if runningBegin >= 0.55 then
                    electrics.values[lightStr] = electrics.values.running
                elseif runningBegin > devide * i then
                    electrics.values[lightStr] = electrics.values.running
                    electrics.values[lightStr2] = 0
                end
            end
        end

    end

    if electrics.values.fog == 1 then
        electrics.values.turnAsisR = 1
        electrics.values.turnAsisL = 1
    elseif electrics.values.steering >= 450 * 0.6 then
        electrics.values.turnAsisR = 0
        electrics.values.turnAsisL = 1
    elseif electrics.values.steering <= 450 * -0.6 then
        electrics.values.turnAsisR = 1
        electrics.values.turnAsisL = 0
    else
        electrics.values.turnAsisR = 0
        electrics.values.turnAsisL = 0
    end

    local running = 0
    if electrics.values.running then
        running = 1
    end
    if autoDrive then
        electrics.values.autoDrive = running * 2
        electrics.values.AuRuA = running
        electrics.values.AuRuR = 0
    else
        electrics.values.autoDrive = running
        electrics.values.AuRuA = 0
        electrics.values.AuRuR = running
    end

end

local function setsign()
    if lightSign == 0 then
        lightSign = 1
    else
        lightSign = 0
    end
end 

local function init(jbeamData)
    -- lightSign = 0
    -- electrics.values.saftyLight = 0
    -- electrics.values.fogLight = 0
    electrics.values.muitiLightL = 0
    electrics.values.muitiLightR = 0

    lightNum = jbeamData.lightNum or 7

    -- light1 = 0
    -- light2 = 0
    -- t1 = 0
    -- t2 = 0
    -- range1 = 0
    -- timerange = 0

    flowLightType = jbeamData.flowLightType or 1

    electrics.values.autoDrive = 0
    electrics.values.innerLight = 0
end

local function reset()
    electrics.values.muitiLightL = 0
    electrics.values.muitiLightR = 0

    electrics.values.autoDrive = 0
    electrics.values.innerLight = 0
end

local function switchInnerLight()
    electrics.values.innerLight = -1 * electrics.values.innerLight + 1
end

M.setsign = setsign

M.switchInnerLight = switchInnerLight

M.updateGFX = updateGFX
M.init = init
M.reset = reset

return M