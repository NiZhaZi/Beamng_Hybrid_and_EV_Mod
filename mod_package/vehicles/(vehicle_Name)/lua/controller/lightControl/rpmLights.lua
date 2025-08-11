-- rpmLights.lua - 2025.8.11 23:30 - RPM lights control
-- by NZZ
-- version 0.0.1 alpha
-- final edit - 2025.8.12 00:28

-- Full files at https://github.com/NiZhaZi/Beamng_Hybrid_and_EV_Mod

local M = {}

local engine = nil
local maxRPM = nil
local idleRPM = nil
local basicRPM = nil

local lightNum = nil

local timer = 0
local flash = 0

local function updateGFX(dt)

    local flasher = 1
    timer = timer + dt
    if timer > 0.05 then
        timer = 0
        flash = -1 * flash + 1
    end
    if engine.outputRPM > engine.maxRPM * 0.98 then
        flasher = flash
    end

    for i = 1, lightNum do
        local lightStr = "rpmLight" .. tostring(i)
        electrics.values[lightStr] = 0
        if engine.outputRPM >= basicRPM / lightNum * i then
            electrics.values[lightStr] = 1 * flasher
        end
    end

end

local function init(jbeamData)
    engine = powertrain.getDevice("mainEngine")
    maxRPM = engine.maxRPM
    idleRPM = engine.idleRPM
    basicRPM = engine.maxRPM - engine.idleRPM + 100

    lightNum = jbeamData.lightNum or 5
end

local function reset()
    
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M