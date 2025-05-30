-- signleMotors.lua - 2024.3.18 21:52 - Control single motors
-- by NZZ
-- version 0.0.4 alpha
-- final edit - 2024.8.11 19:11

-- Full files at https://github.com/NiZhaZi/Beamng_Hybrid_and_EV_Mod

local M = {}

local abs = math.abs

local AVtoRPM = 9.549296596425384

local motorType = nil
local compareNodes1 = nil
local compareNodes2 = nil
local maxRPMdiff = nil

local node1 = nil
local node2 = nil

local motors = nil
local gearbox = nil

local function updateGFX(dt)

    local mode = electrics.values.hybridMode
    local motorDirection

    local typeDirection
    if motorType == "fullTime" then
        typeDirection = 1
    elseif motorType == "partTime" then

        local compareNum
        if node1 and node2 then
            compareNum = abs(node1.outputAV1 - node2.outputAV1)
        else
            compareNum = 999999999
        end

        if compareNum * AVtoRPM >= maxRPMdiff then
            typeDirection = 1
        else
            typeDirection = 0
        end
    else
        typeDirection = 0
    end

    if electrics.values.ignitionLevel == 2 then
        -- if gearbox.mode then
        --     if gearbox.mode == "drive" then -- D gear , S gear , R gear or M gear
        --         motorDirection = gearbox.gearIndex
        --     elseif gearbox.mode == "reverse" then -- CVT R gear
        --         motorDirection = -1
        --     elseif gearbox.mode == "neutral" then -- N gear
        --         motorDirection = 0
        --     elseif gearbox.mode == "park" then -- P gear
        --         motorDirection = 0
        --     end
        -- else
        --     motorDirection = gearbox.gearIndex
        -- end
        if gearbox.gearRatio ~= 0 then
            motorDirection = gearbox.gearRatio / abs(gearbox.gearRatio)
        else
            motorDirection = 0
        end
    else
        motorDirection = 0
    end
    log("D", "", motorDirection)

    motorDirection = motorDirection * typeDirection

    if mode == "hybrid" then
        for _, v in ipairs(motors) do
            v.motorDirection = motorDirection
        end
    elseif mode == "fuel" then
        for _, v in ipairs(motors) do
            v.motorDirection = 0
        end
    elseif mode == "electric" then
        for _, v in ipairs(motors) do
            v.motorDirection = motorDirection
        end
    else
        for _, v in ipairs(motors) do
            v.motorDirection = motorDirection
        end
    end

    local regenLevel = controller.getControllerSafe('hybridControl').getRegenLevel()
    -- log("", "", "" .. regenLevel)
    for _, v in ipairs(motors) do
        if v then
            v.maxWantedRegenTorque = v.originalRegenTorque * regenLevel
        end
    end

end

local function reset(jbeamData)

end

local function init(jbeamData)

    motors = {}
    local motorNames = jbeamData.motorNames
    if motorNames then
        for _, v in ipairs(motorNames) do
            local motor = powertrain.getDevice(v)
            if motor then
                table.insert(motors, motor)
                motor.originalRegenTorque = motor.maxWantedRegenTorque
            end
        end
    end

    gearbox = powertrain.getDevice("gearbox")

    motorType = jbeamData.motorType or "partTime"
    compareNodes1 = jbeamData.compareNodes1 or nil
    compareNodes2 = jbeamData.compareNodes2 or nil
    if compareNodes1 and compareNodes2 then
        node1 = powertrain.getDevice(compareNodes1) or nil
        node2 = powertrain.getDevice(compareNodes2) or nil
    end

    maxRPMdiff = jbeamData.maxRPMdiff or 50

end

M.updateGFX = updateGFX
M.reset = reset
M.init = init

return M