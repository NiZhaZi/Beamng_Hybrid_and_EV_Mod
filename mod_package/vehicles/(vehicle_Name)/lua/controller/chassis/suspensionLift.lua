-- suspension_lift.lua - 2024.4.19 18:30 - suspension lift control
-- by NZZ
-- version 0.0.12 alpha
-- final edit - 2025.10.1 22:55

local M = {}

local floor = math.floor
local ceil = math.ceil

local lift0 = nil
local liftLevel = nil
local dropLevel = nil

local highSpeed = nil

local autoLevel = nil
local otSign = nil
local mode = nil

local flatAngle = nil

-- === Sport mode state/params ===
local sportPrevRoll = nil
local sportRollRate = 0
local sportSpeedMin = nil        -- m/s (converted from km/h)
local sportSteerDead = nil
local sportRollKp = nil          -- proportional gain for roll angle (/deg * unit/s)
local sportRollKd = nil          -- derivative gain for roll rate (/(deg/s) * unit/s)
local sportFFgain = nil          -- steering x speed feedforward (unit/s)
local sportRateMax = nil         -- maximum adjustment per second (unit/s)
local sportRelaxRate = nil       -- return-to-zero rate when straight/small attitude (unit/s)

local function getSign(num)
    if type(num) == "number" then
        if num == 0 or num == -0 then
            return 0
        elseif num > 0 then
            return 1
        else
            return -1
        end
    else
        error("typeError")
    end
end

local function onInit(jbeamData)
    
    lift0 = 0
    electrics.values['lift0'] = lift0
    electrics.values['liftFL'] = lift0
    electrics.values['liftFR'] = lift0
    electrics.values['liftRL'] = lift0
    electrics.values['liftRR'] = lift0

    highSpeed = jbeamData.liftVelocity or 80
    mode = jbeamData.defaultMode or "auto"
    autoLevel = 0

    liftLevel = jbeamData.liftLevel or 0.10
    dropLevel = jbeamData.dropLevel or -0.10

    flatAngle = jbeamData.flatAngle or 1.00

    -- === adaptiveSport params (overridable via jbeam) ===
    sportSpeedMin  = (jbeamData.sportSpeedMinKmh or 30) / 3.6  -- 30 km/h
    sportSteerDead = jbeamData.sportSteerDead or 0.05          -- steering deadband
    sportRollKp    = jbeamData.sportRollKp or 0.08
    sportRollKd    = jbeamData.sportRollKd or 0.02
    sportFFgain    = jbeamData.sportFFgain or 0.60
    sportRateMax   = jbeamData.sportRateMax or 0.80            -- unit/s
    sportRelaxRate = jbeamData.sportRelaxRate or 0.25           -- unit/s
    sportPrevRoll  = nil

end

local function adjustChassis(para)

    if mode == "manual" then

        lift0 = math.max(math.min(lift0 + para, liftLevel), dropLevel)
        if math.abs(lift0) < 0.0001 then
            lift0 = 0
        end

        local level = getSign(lift0) * math.abs(lift0 / para)
        if level == -0 then
            level = 0
        end
        guihooks.message("Chassis Height is now on level " .. level .. ".", 5, "")

        electrics.values['lift0'] = lift0
    else
        -- guihooks.message("Chassis Height can not be adjusted manually now.", 5, "")
        mode = "manual"
        adjustChassis(para)
    end

end

local function resetChassis()

    if mode == "manual" then
        lift0 = 0
        electrics.values['lift0'] = lift0
        guihooks.message("Chassis Height is now on level " .. 0 .. ".", 5, "")
    else
        guihooks.message("Chassis Height can not be adjusted manually now.", 5, "")
    end

end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function bump(v, sgn, step)  -- sgn in {+1, -1}
        return clamp(v + sgn * step, dropLevel, liftLevel)
    end

local function relax(v, relaxRate)
    if v >  relaxRate then return v - relaxRate
    elseif v < -relaxRate then return v + relaxRate
    else return 0 end
end

local function updateGFX(dt)

    local finalLevel = autoLevel
    local liftFL = 0
    local liftFR = 0
    local liftRL = 0
    local liftRR = 0

    if mode ~= "outTrouble" and autoLevel == 0 and electrics.values.wheelspeed >= highSpeed / 3.6 then
        finalLevel = dropLevel
    end
    
    if mode == "auto" then
        electrics.values['lift0'] = finalLevel
        lift0 = finalLevel
    elseif mode == "outTrouble" then
        if electrics.values['lift0'] == liftLevel then
            otSign = -1
        elseif electrics.values['lift0'] == dropLevel then
            otSign = 1
        end
        finalLevel = math.min(math.max(electrics.values['lift0'] + otSign * dt, dropLevel), liftLevel)
        electrics.values['lift0'] = finalLevel
        lift0 = finalLevel
    elseif mode == "adaptive" then
        local roll, pitch

        -- if vehicleInfo then
        --     roll = vehicleInfo.posture.roll * 90
        --     pitch = vehicleInfo.posture.pitch * 90
        --     roll = roll - roll % 0.1
        --     pitch = pitch - pitch % 0.1
        if obj and obj.getRollPitchYaw then
            local r, p = obj:getRollPitchYaw()     -- radians
            roll  = math.deg(r)
            pitch = math.deg(p)
        elseif obj and obj.getRollPitchYawWS then
            local r, p = obj:getRollPitchYawWS()   -- radians
            roll  = math.deg(r)
            pitch = math.deg(p)
        else
            roll, pitch = 0, 0
        end

        liftFL = electrics.values['liftFL'] or 0
        liftFR = electrics.values['liftFR'] or 0
        liftRL = electrics.values['liftRL'] or 0
        liftRR = electrics.values['liftRR'] or 0

        local stepFast  = 1.0 * dt     -- ~ 1.0 / s
        local stepSlow  = 0.5 * dt     -- ~ 0.5 / s
        local relaxRate = 0.6 * dt     

        if math.abs(roll) <= flatAngle and math.abs(pitch) <= flatAngle then
            liftFL = relax(liftFL, relaxRate); liftFR = relax(liftFR, relaxRate)
            liftRL = relax(liftRL, relaxRate); liftRR = relax(liftRR, relaxRate)
        else
            if roll > flatAngle then
                if pitch > flatAngle then
                    liftRL = bump(liftRL,  1, stepFast)
                    liftFR = bump(liftFR, -1, stepFast)
                elseif pitch < -flatAngle then
                    liftFL = bump(liftFL,  1, stepFast)
                    liftRR = bump(liftRR, -1, stepFast)
                else
                    liftFL = bump(liftFL,  1, stepSlow)
                    liftRL = bump(liftRL,  1, stepSlow)
                    liftFR = bump(liftFR, -1, stepSlow)
                    liftRR = bump(liftRR, -1, stepSlow)
                end
            elseif roll < -flatAngle then
                if pitch > flatAngle then
                    liftRR = bump(liftRR,  1, stepFast)
                    liftFL = bump(liftFL, -1, stepFast)
                elseif pitch < -flatAngle then
                    liftFR = bump(liftFR,  1, stepFast)
                    liftRL = bump(liftRL, -1, stepFast)
                else
                    liftFR = bump(liftFR,  1, stepSlow)
                    liftRR = bump(liftRR,  1, stepSlow)
                    liftFL = bump(liftFL, -1, stepSlow)
                    liftRL = bump(liftRL, -1, stepSlow)
                end
            else
                if pitch > flatAngle then
                    liftRL = bump(liftRL,  1, stepSlow)
                    liftRR = bump(liftRR,  1, stepSlow)
                    liftFL = bump(liftFL, -1, stepSlow)
                    liftFR = bump(liftFR, -1, stepSlow)
                elseif pitch < -flatAngle then
                    liftFL = bump(liftFL,  1, stepSlow)
                    liftFR = bump(liftFR,  1, stepSlow)
                    liftRL = bump(liftRL, -1, stepSlow)
                    liftRR = bump(liftRR, -1, stepSlow)
                end
            end
        end
    elseif mode == "adaptiveSport" then
        -- Read attitude (prefer physics object; fallback to vehicleInfo)
        local roll
        if obj and obj.getRollPitchYaw then
            local r, _ = obj:getRollPitchYaw()   -- radians
            roll = math.deg(r)
        elseif vehicleInfo and vehicleInfo.posture then
            roll = (vehicleInfo.posture.roll or 0) * 90  -- consistent with the original script
        else
            roll = 0
        end

        -- Use the current value as the baseline (avoid being zeroed)
        liftFL = electrics.values['liftFL'] or 0
        liftFR = electrics.values['liftFR'] or 0
        liftRL = electrics.values['liftRL'] or 0
        liftRR = electrics.values['liftRR'] or 0

        -- Inputs (steering, speed)
        local steer = electrics.values.steering or electrics.values.steering_input or 0
        local v     = electrics.values.wheelspeed or 0 -- m/s

        -- Roll rate (for D term)
        if sportPrevRoll ~= nil then
            sportRollRate = (roll - sportPrevRoll) / math.max(dt, 1e-3)
        else
            sportRollRate = 0
        end
        sportPrevRoll = roll

        -- Normalized speed (for feedforward)
        local vmax = math.max((highSpeed or 80) / 3.6, sportSpeedMin + 0.1)
        local vNorm = clamp((v - sportSpeedMin) / (vmax - sportSpeedMin), 0, 1)

        local steerMag = math.max(math.abs(steer) - sportSteerDead, 0)
        local err      = math.max(math.abs(roll) - flatAngle, 0)

        -- Target adjustment rate (unit/s), then multiply by dt to get per-frame step
        local rateCmd = err * sportRollKp + math.abs(sportRollRate) * sportRollKd + steerMag * vNorm * sportFFgain
        rateCmd = clamp(rateCmd, 0, sportRateMax)

        local step = rateCmd * dt

        local function relax(vv)
            if vv >  sportRelaxRate * dt then return vv - sportRelaxRate * dt
            elseif vv < -sportRelaxRate * dt then return vv + sportRelaxRate * dt
            else return 0 end
        end

        -- Straight/too slow or small attitude -> gently return to zero
        if steerMag <= 1e-4 or v < sportSpeedMin then
            liftFL = relax(liftFL); liftFR = relax(liftFR)
            liftRL = relax(liftRL); liftRR = relax(liftRR)
        else
            -- Anti-roll: outer up, inner down (positive roll = right high, left low)
            if roll > 0 then
                liftFL = clamp(liftFL + step, dropLevel, liftLevel)
                liftRL = clamp(liftRL + step, dropLevel, liftLevel)
                liftFR = clamp(liftFR - step, dropLevel, liftLevel)
                liftRR = clamp(liftRR - step, dropLevel, liftLevel)
            elseif roll < 0 then
                liftFR = clamp(liftFR + step, dropLevel, liftLevel)
                liftRR = clamp(liftRR + step, dropLevel, liftLevel)
                liftFL = clamp(liftFL - step, dropLevel, liftLevel)
                liftRL = clamp(liftRL - step, dropLevel, liftLevel)
            else
                liftFL = relax(liftFL); liftFR = relax(liftFR)
                liftRL = relax(liftRL); liftRR = relax(liftRR)
            end
        end
    end

    if mode == "adaptive" or mode == "adaptiveSport" then
        electrics.values['liftFL'] = liftFL
        electrics.values['liftFR'] = liftFR
        electrics.values['liftRL'] = liftRL
        electrics.values['liftRR'] = liftRR
    else
        electrics.values['liftFL'] = lift0
        electrics.values['liftFR'] = lift0
        electrics.values['liftRL'] = lift0
        electrics.values['liftRR'] = lift0
    end

end

local function setParameters(parameters)
    if mode == "auto" then
        autoLevel = parameters.lift
    end
end

local function switchMode(Mode)
    if Mode == "auto" or Mode == "manual" or Mode == "outTrouble" or Mode == "adaptive" or Mode == "adaptiveSport" then
        mode = Mode
    else
        if mode == "auto" then
            mode = "manual"
        elseif mode == "manual" then
            mode = "auto"
        else
            mode = "auto"
        end
    end
    if Mode == "outTrouble" then
        otSign = -1
    end
    guihooks.message("Chassis Adjust Mode is now " .. mode .. " mode." , 5, "")
end

-- public interface
M.switchMode = switchMode

M.adjustChassis = adjustChassis
M.resetChassis = resetChassis

M.setParameters = setParameters

M.init      = onInit
M.reset     = onInit
M.updateGFX = updateGFX

return M