-- autoContrl.lua - 2024.3.17 12:48 - auto functions control
-- by NZZ
-- version 0.0.19 alpha
-- final edit - 2025.7.25 13:00

local M = {}
local debugTime = 0

local proxyEngine = nil
local gearbox = nil
local motors = nil 

local brake = nil
local throttle = nil

local brakeLightRegenTorque = nil

local mode = {
    autoHold = nil,
    autoStart = nil,
    hillDescentControl = nil,
    ecrawl = nil,
}

local function vehicleHold()
    if electrics.values.wheelspeed < 0.05 * 3.6 then
        return true
    else
        return false
    end
end

local function switchAutoHold()
    if mode.autoHold == "on" then
        gui.message({ txt = "Auto Hold Off" }, 5, "", "")
        mode.autoHold = "off"
    elseif mode.autoHold == "off" then
        gui.message({ txt = "Auto Hold On" }, 5, "", "")
        mode.autoHold = "on"
    else
        gui.message({ txt = "Auto Hold Disabled" }, 5, "", "")
    end
    if mode.autoHold == "on" then
        electrics.values.autohold = 1
    else
        electrics.values.autohold = 0
    end
end

local function switchAutoStart()
    if mode.autoStart == "on" then
        gui.message({ txt = "Auto Start Off" }, 5, "", "")
        mode.autoStart = "off"
    elseif mode.autoStart == "off" then
        gui.message({ txt = "Auto Start On" }, 5, "", "")
        mode.autoStart = "on"
    else
        gui.message({ txt = "Auto Start Disabled" }, 5, "", "")
    end
end

local function switchHDC()
    if mode.hillDescentControl == "on" then
        gui.message({ txt = "HDC Off" }, 5, "", "")
        mode.hillDescentControl = "off"
    elseif mode.hillDescentControl == "off" then
        gui.message({ txt = "HDC On" }, 5, "", "")
        mode.hillDescentControl = "on"
    else
        gui.message({ txt = "HDC Disabled" }, 5, "", "")
    end
end

local function switchECrawl()
    if mode.ecrawl == "on" then
        gui.message({ txt = "ECrawl Off" }, 5, "", "")
        mode.ecrawl = "off"
    elseif mode.ecrawl == "off" then
        gui.message({ txt = "ECrawl On" }, 5, "", "")
        mode.ecrawl = "on"
    else
        gui.message({ txt = "ECrawl Disabled" }, 5, "", "")
    end
end

local function updateGFX(dt)

    local ign
    if electrics.values.ignitionLevel == 2 then
        ign = 1
    else
        ign = 0
    end

    local ifRegen = 0
    for _, v in ipairs(motors) do
        if v.outputTorque1 < brakeLightRegenTorque then
            ifRegen = 1
            break
        end
    end

    if ifRegen == 1 then
        electrics.values.brakewithign = ifRegen * ign
    else
        electrics.values.brakewithign = input.brake * electrics.values.brakelights * ign
    end
    
    local hybridMode = electrics.values.hybridMode

    local autoHoldMode
    local autoStartMode
    local ecrawlMode
    if mode.hillDescentControl == "on" then
        autoHoldMode = "off"
        autoStartMode = "off"
        ecrawlMode = "off"
    else
        autoHoldMode = mode.autoHold
        autoStartMode = mode.autoStart
        ecrawlMode = mode.ecrawl
    end

    if hybridMode == "electric" or hybridMode == "auto" or hybridMode == "reev" then
        autoStartMode = "off"
    end

    if hybridMode ~= "electric" then
        ecrawlMode = "off"
    end

    if autoStartMode == "on" and electrics.values.ignitionLevel == 2 then
        if input.throttle == 0 and vehicleHold() then
            proxyEngine:setIgnition(0)
        elseif input.throttle > 0 then
            proxyEngine:activateStarter()
        end
    elseif autoStartMode== "off" and electrics.values.ignitionLevel == 2 then
        if electrics.values.engineRunning == 0 and proxyEngine.outputRPM <= 0 and (hybridMode == "fuel" or hybridMode == "hybrid") then
            proxyEngine:activateStarter()
        end
    end

    if autoHoldMode == "on" then
        local velocity = electrics.values.wheelspeed * 3.6
        if input.throttle <= 0 then
            if input.brake >= 0.8 and vehicleHold() then
                brake = 1
                electrics.values.autoholdActive = 1
            elseif input.brake > 0 then
                brake = input.brake
            elseif math.abs(vehicleInfo.posture.pitch) > 0.08 then
                brake = math.max(0, input.brake, -(1 / 0.10) * velocity + 1) -- auto stay
                if vehicleHold() then
                    brake = 1
                end
                electrics.values.autoholdActive = 1
            elseif electrics.values.autoholdActive ~= 1 then
                brake = input.brake
                electrics.values.autoholdActive = 0
            end
        else
            brake = input.brake
            electrics.values.autoholdActive = 0
        end
    end

    if (input.throttle > 0 or input.brake > 0 or electrics.values.ignitionLevel ~= 2) and mode.hillDescentControl == "on" then
        gui.message({ txt = "HDC Off" }, 5, "", "")
        mode.hillDescentControl = "off"
    end

    if mode.hillDescentControl == "on" then
        throttle = 0.01
        electrics.values.throttle = 0.01
        if electrics.values.wheelspeed > 1 then
            brake = brake + 0.1
        else
            brake = brake - 0.1
        end
    end

    if ecrawlMode == "on" and hybridMode == "electric" and electrics.values.ignitionLevel == 2 then
        if input.throttle == 0 then
            if electrics.values.wheelspeed < 1  then
                throttle = throttle + 0.1
            else
                throttle = throttle - 0.1
            end
        else
            throttle = input.throttle
        end
        electrics.values.throttle = throttle
    end

    if mode.ecrawl ~= "on" and mode.hillDescentControl ~= "on" then
        throttle = input.throttle
    end

    if mode.autoHold ~= "on" and mode.hillDescentControl ~= "on" then
        brake = input.brake
    end

    if throttle > 1 then
        throttle = 1
    elseif throttle < 0 then
        throttle = 0
    end

    if gearbox then
        if gearbox.mode == "park" then
            brake = 1
        end
    end

    brake = math.max(math.min(brake, 1), 0)

    --if throttle ~= electrics.values.throttle then
    --    electrics.values.throttle = throttle
    --end
    if brake ~= electrics.values.brake then
        electrics.values.brake = brake
    end

    --debugTime = debugTime + dt
    --if debugTime >= 5 then
    --    log("", "", "electrics.values.airspeed" .. electrics.values.airspeed)
    --    debugTime = 0
    --end

end

local function init(jbeamData)

    proxyEngine = powertrain.getDevice("mainEngine")
    gearbox =  powertrain.getDevice("gearbox")
    motors = {}
    -- local motorNames = jbeamData.motorNames or {"mainMotor"}
    -- for _, v in ipairs(motorNames) do
    --     local motor = powertrain.getDevice(v)
    --     if motor then
    --         table.insert(motors, motor)
    --         motor.originalRegenTorque = motor.maxWantedRegenTorque
    --     end
    -- end
    local emotors = powertrain.getDevicesByType("electricMotor")
    local smotors = powertrain.getDevicesByType("motorShaft")
    motors = emotors
    for _,v in ipairs(smotors) do
        table.insert(motors, v)
    end

    mode.autoHold = jbeamData.defaultAutoHold or "off"
    mode.autoStart = jbeamData.defaultAutoStart or "off"
    mode.hillDescentControl = jbeamData.HDC or "off"
    mode.ecrawl = jbeamData.defaultECrawl or "off"

    brake = 0
    throttle = 0

    if mode.autoHold == "on" then
        electrics.values.autohold = 1
    else
        electrics.values.autohold = 0
    end
    electrics.values.autoholdActive = 0

    brakeLightRegenTorque = -100
    if jbeamData.brakeLightRegenTorque then
        if jbeamData.brakeLightRegenTorque >= 0 then
            brakeLightRegenTorque = -1 * jbeamData.brakeLightRegenTorque
        else
            brakeLightRegenTorque = jbeamData.brakeLightRegenTorque
        end
    end

end

local function reset(jbeamData)
    
    mode.autoHold = jbeamData.defaultAutoHold or "off"
    mode.autoStart = jbeamData.defaultAutoStart or "off"
    mode.hillDescentControl = jbeamData.HDC or "off"
    mode.ecrawl = jbeamData.defaultECrawl or "off"

    brake = 0
    throttle = 0

    if mode.autoHold == "on" then
        electrics.values.autohold = 1
    else
        electrics.values.autohold = 0
    end
    electrics.values.autoholdActive = 0
    
end

M.switchAutoHold = switchAutoHold
M.switchAutoStart = switchAutoStart
M.switchHDC = switchHDC
M.switchECrawl = switchECrawl

M.init = init
M.reset = reset
M.onReset = reset
M.onInit = init
M.updateGFX = updateGFX

return M