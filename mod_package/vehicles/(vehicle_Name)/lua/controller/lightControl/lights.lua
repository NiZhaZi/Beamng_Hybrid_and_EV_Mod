-- lights.lua - 2025.6.12 17:37 - lights control
-- by NZZ
-- version 0.0.12 alpha
-- final edit - 2025.12.10 23:25

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
local enLight = nil

local autoDrive = nil

local autoFogLight = nil

local function switchAutoFogLight()
    if autoFogLight == nil then
        autoFogLight = true
    else
        autoFogLight = not autoFogLight
    end
end

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

    local devide = 0.4 / (lightNum + 1) -- time(seconds) one light bulb lasts
    local devideR = 0.6 / (lightNum + 1)

    if electrics.values.ignitionLevel == 2 and runningBegin < 0.6 then
        runningBegin = math.min(runningBegin + dt, 0.6) -- time(seconds) after ignition
    end

    if electrics.values.ignitionLevel ~= 2 then
        runningBegin = 0
        enLight = lightNum
    end 

        local maxFlowIndex = lightNum + 2
    local runningState = electrics.values.running

    if runningBegin >= 0.6 then
        -- After the animation, keep all lights on
        for i = 0, maxFlowIndex do
            local lightStr = "flowRunning" .. tostring(i)
            electrics.values[lightStr] = runningState
        end
    elseif flowLightType == 1 then
        -- Mode 1: simple forward filling (one by one on, stays on)
        for i = 0, maxFlowIndex do
            local lightStr = "flowRunning" .. tostring(i)
            if runningBegin > devide * i then
                electrics.values[lightStr] = runningState
            else
                electrics.values[lightStr] = 0
            end
        end
    elseif flowLightType == 2 then
        -- Mode 2: flowing light with a short "tail"
        for i = 0, maxFlowIndex do
            local lightStr = "flowRunning" .. tostring(i)
            electrics.values[lightStr] = 0

            if runningBegin >= 0.55 then
                -- Near the end of animation: keep all lights on
                electrics.values[lightStr] = runningState
            elseif runningBegin > devide * i then
                -- Turn on current light and turn off a light behind it
                electrics.values[lightStr] = runningState

                local prevIndex = i - 3
                if prevIndex >= 0 then
                    local lightStr2 = "flowRunning" .. tostring(prevIndex)
                    electrics.values[lightStr2] = 0
                end
            end
        end
    elseif flowLightType == 3 then
        -- Mode 3: single "dot" flowing from outside to inside
        local currentEnLight = enLight or lightNum or 1
        if currentEnLight < 1 then currentEnLight = 1 end
        local lastIndex = currentEnLight - 1

        for i = 0, lastIndex do
            local lightStr = "flowRunning" .. tostring(i)
            local lightStrPrev = "flowRunning" .. tostring(i - 1)

            -- All lights except the last one in the current range are off by default
            if i < lastIndex or not runningState then
                electrics.values[lightStr] = 0
            end

            -- When time is enough for this index, move the "dot" forward
            if runningBegin > devideR * i then
                electrics.values[lightStr] = runningState
                electrics.values[lightStrPrev] = 0
            end
        end

        -- Check if the last light in the current range is actually on
        -- It may be stored as boolean or number, so we handle both cases
        local lightStrEn = "flowRunning" .. tostring(lastIndex)
        local value = electrics.values[lightStrEn]
        local isOn = false
        if type(value) == "boolean" then
            isOn = value
        elseif type(value) == "number" then
            isOn = value > 0
        end

        -- When the last light is on, shrink the range and reset timer
        -- This prevents the last few lights from turning on all at once
        if isOn then
            if currentEnLight > 1 then
                enLight = currentEnLight - 1
            end
            runningBegin = 0
        end
    else
        -- Unknown mode: all lights simply follow the running state
        for i = 0, maxFlowIndex do
            local lightStr = "flowRunning" .. tostring(i)
            electrics.values[lightStr] = runningState
        end
    end


    for i = 0, lightNum - 1 do
        local lightSourceStrL
        local lightSourceStrR
        lightSourceStrL = "lightSourceSignalL" .. tostring(i)
        lightSourceStrR = "lightSourceSignalR" .. tostring(i)
        electrics.values[lightSourceStrL] = 0
        electrics.values[lightSourceStrR] = 0
        lightSourceStrL = "lightSourceRunningL" .. tostring(i)
        lightSourceStrR = "lightSourceRunningR" .. tostring(i)
        electrics.values[lightSourceStrL] = 0
        electrics.values[lightSourceStrR] = 0
    end

    if electrics.values.signal_L == 1 then
        signalDelayL = signalDelayL + dt
    else
        signalDelayL = 0
    end

    if electrics.values.signal_left_input == 1 then

        for i = 0, lightNum - 1 do
            local lightStr = "muitiLightL" .. tostring(i)
            local lightSourceStr = "lightSourceSignalL" .. tostring(i)
            electrics.values[lightStr] = 0
            if signalDelayL > devide * i then
                electrics.values[lightStr] = 2
                electrics.values[lightSourceStr] = 1
            end
        end

    else

        for i = 0, lightNum + 2 do
            local lightStr = "muitiLightL" .. tostring(i)
            local flowStr = "flowRunning" .. tostring(i)
            local lightSourceStr = "lightSourceRunningL" .. tostring(i)
            electrics.values[lightStr] = electrics.values[flowStr]
            electrics.values[lightSourceStr] = electrics.values[flowStr]
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
            local lightSourceStr = "lightSourceSignalR" .. tostring(i)
            electrics.values[lightStr] = 0
            if signalDelayR > devide * i then
                electrics.values[lightStr] = 2
                electrics.values[lightSourceStr] = 1
            end
        end

    else

        for i = 0, lightNum + 2 do
            local lightStr = "muitiLightR" .. tostring(i)
            local flowStr = "flowRunning" .. tostring(i)
            local lightSourceStr = "lightSourceRunningR" .. tostring(i)
            electrics.values[lightStr] = electrics.values[flowStr]
            electrics.values[lightSourceStr] = electrics.values[flowStr]
        end

    end

    local fogLevel = tonumber(obj:getLastMailbox("fogLevel")) * 100
    if autoFogLight then
        if fogLevel >= 1 and electrics.values.fog == 0 then
            electrics.values.fog = 1
        elseif fogLevel < 1 and electrics.values.fog == 1 then
            electrics.values.fog = 0
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
    if ai.mode == "traffic" or autopilotPrevEnableElectrics then autoDrive = true else autoDrive = nil end
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
    obj:queueGameEngineLua('extensions.load("weatherToVe")')
    autoFogLight = jbeamData.defaultAutoFogLight or true

    -- lightSign = 0
    -- electrics.values.saftyLight = 0
    -- electrics.values.fogLight = 0
    electrics.values.muitiLightL = 0
    electrics.values.muitiLightR = 0

    lightNum = jbeamData.lightNum or 3
    enLight = lightNum

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

local function reset(jbeamData)
    autoFogLight = jbeamData.defaultAutoFogLight or true

    enLight = lightNum

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
M.switchAutoFogLight = switchAutoFogLight

M.updateGFX = updateGFX
M.init = init
M.reset = reset

return M