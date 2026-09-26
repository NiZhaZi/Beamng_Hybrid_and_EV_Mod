-- suspension_lift.lua - suspension lift / active body control
-- by NZZ
-- adaptive / adaptiveSport control reworked by ChatGPT
-- version 0.1.0
-- 2026.09.26

local M = {}

local lift0 = nil
local liftLevel = nil
local dropLevel = nil
local highSpeed = nil
local autoLevel = nil
local otSign = nil
local mode = nil
local flatAngle = nil

-- === Adaptive leveling state / params ===
local adaptiveRoll = nil
local adaptivePitch = nil
local adaptivePrevRoll = nil
local adaptivePrevPitch = nil
local adaptiveRollRate = 0
local adaptivePitchRate = 0

local adaptiveDeadAngle = nil
local adaptiveRollKp = nil
local adaptiveRollKd = nil
local adaptivePitchKp = nil
local adaptivePitchKd = nil
local adaptiveRateMax = nil
local adaptiveFilterTau = nil
local adaptiveRateFilterTau = nil
local adaptiveMaxCorrection = nil

-- === Adaptive Sport anti-roll state / params ===
local sportRoll = nil
local sportPrevRoll = nil
local sportRollRate = 0

local sportSpeedMin = nil
local sportFullSpeed = nil
local sportSteerDead = nil
local sportRollKp = nil
local sportRollKd = nil
local sportFFgain = nil
local sportRateMax = nil
local sportRelaxRate = nil
local sportFilterTau = nil
local sportRateFilterTau = nil
local sportDeadAngle = nil
local sportMaxCorrection = nil

local function getSign(num)
    if type(num) ~= "number" then
        error("typeError")
    end
    if num == 0 or num == -0 then
        return 0
    elseif num > 0 then
        return 1
    end
    return -1
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function moveTowards(current, target, maxStep)
    if current < target then
        return math.min(current + maxStep, target)
    elseif current > target then
        return math.max(current - maxStep, target)
    end
    return target
end

local function lowPass(current, target, tau, dt)
    if current == nil then
        return target
    end
    tau = math.max(tau or 0, 1e-4)
    local alpha = 1 - math.exp(-dt / tau)
    return current + (target - current) * alpha
end

-- Continuous dead-zone: unlike a hard cutoff, the command does not jump
-- when the angle crosses the threshold.
local function deadzoneSigned(v, dead)
    local a = math.abs(v)
    if a <= dead then
        return 0
    end
    return getSign(v) * (a - dead)
end

local function readAttitude()
    if obj and obj.getRollPitchYaw then
        local r, p = obj:getRollPitchYaw()
        return math.deg(r or 0), math.deg(p or 0)
    elseif obj and obj.getRollPitchYawWS then
        local r, p = obj:getRollPitchYawWS()
        return math.deg(r or 0), math.deg(p or 0)
    elseif vehicleInfo and vehicleInfo.posture then
        -- Keep compatibility with the scale used by the original script.
        return (vehicleInfo.posture.roll or 0) * 90,
               (vehicleInfo.posture.pitch or 0) * 90
    end
    return 0, 0
end

-- Scale the four corner offsets together before applying them.
-- This keeps their average height unchanged instead of independently clipping
-- individual corners and accidentally adding/removing chassis heave.
local function fitOffsetsToTravel(base, fl, fr, rl, rr)
    base = clamp(base, dropLevel, liftLevel)

    local scale = 1
    local offsets = {fl, fr, rl, rr}

    for _, d in ipairs(offsets) do
        if d > 0 then
            local room = liftLevel - base
            if d > room and d > 1e-9 then
                scale = math.min(scale, room / d)
            end
        elseif d < 0 then
            local room = dropLevel - base -- negative or zero
            if d < room and d < -1e-9 then
                scale = math.min(scale, room / d)
            end
        end
    end

    scale = clamp(scale, 0, 1)

    return base + fl * scale,
           base + fr * scale,
           base + rl * scale,
           base + rr * scale
end

local function resetAdaptiveState()
    adaptiveRoll = nil
    adaptivePitch = nil
    adaptivePrevRoll = nil
    adaptivePrevPitch = nil
    adaptiveRollRate = 0
    adaptivePitchRate = 0
end

local function resetSportState()
    sportRoll = nil
    sportPrevRoll = nil
    sportRollRate = 0
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

    local symmetricTravel = math.min(math.abs(liftLevel), math.abs(dropLevel))

    -- === Adaptive: body leveling ===
    -- Output unit is the same lift command used by liftFL/FR/RL/RR.
    adaptiveDeadAngle      = jbeamData.adaptiveDeadAngle or math.min(flatAngle, 0.25)
    adaptiveRollKp         = jbeamData.adaptiveRollKp or 0.015
    adaptiveRollKd         = jbeamData.adaptiveRollKd or 0.0015
    adaptivePitchKp        = jbeamData.adaptivePitchKp or 0.012
    adaptivePitchKd        = jbeamData.adaptivePitchKd or 0.0010
    adaptiveRateMax        = jbeamData.adaptiveRateMax or 0.35
    adaptiveFilterTau      = jbeamData.adaptiveFilterTau or 0.12
    adaptiveRateFilterTau  = jbeamData.adaptiveRateFilterTau or 0.10
    adaptiveMaxCorrection  = jbeamData.adaptiveMaxCorrection
        or math.max(symmetricTravel * 0.90, 0.001)

    -- === adaptiveSport: active anti-roll ===
    sportSpeedMin       = (jbeamData.sportSpeedMinKmh or 20) / 3.6
    sportFullSpeed      = (jbeamData.sportFullSpeedKmh or 100) / 3.6
    sportSteerDead      = jbeamData.sportSteerDead or 0.05
    sportDeadAngle      = jbeamData.sportDeadAngle or 0.15

    -- New target-height gains. If an older JBeam still contains the old
    -- rate-controller gains, convert them to approximately equivalent values.
    if jbeamData.sportTargetKp ~= nil then
        sportRollKp = jbeamData.sportTargetKp
    elseif jbeamData.sportRollKp ~= nil then
        sportRollKp = jbeamData.sportRollKp * 0.20
    else
        sportRollKp = 0.018
    end

    if jbeamData.sportTargetKd ~= nil then
        sportRollKd = jbeamData.sportTargetKd
    elseif jbeamData.sportRollKd ~= nil then
        sportRollKd = jbeamData.sportRollKd * 0.15
    else
        sportRollKd = 0.0025
    end

    -- Feed-forward is used as a gain multiplier, so it can improve response
    -- without guessing the steering sign and accidentally leaning the wrong way.
    sportFFgain        = jbeamData.sportFFgain or 0.60
    sportRateMax       = jbeamData.sportRateMax or 1.00
    sportRelaxRate     = jbeamData.sportRelaxRate or 0.40
    sportFilterTau     = jbeamData.sportFilterTau or 0.07
    sportRateFilterTau = jbeamData.sportRateFilterTau or 0.06
    sportMaxCorrection = jbeamData.sportMaxCorrection
        or math.max(symmetricTravel * 0.95, 0.001)

    resetAdaptiveState()
    resetSportState()
end

local function adjustChassis(para)
    if mode == "manual" then
        lift0 = clamp(lift0 + para, dropLevel, liftLevel)

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
        mode = "manual"
        adjustChassis(para)
    end
end

local function resetChassis()
    if mode == "manual" then
        lift0 = 0
        electrics.values['lift0'] = lift0
        guihooks.message("Chassis Height is now on level 0.", 5, "")
    else
        guihooks.message("Chassis Height can not be adjusted manually now.", 5, "")
    end
end

local function updateAdaptive(dt, liftFL, liftFR, liftRL, liftRR)
    local rawRoll, rawPitch = readAttitude()

    adaptiveRoll = lowPass(adaptiveRoll, rawRoll, adaptiveFilterTau, dt)
    adaptivePitch = lowPass(adaptivePitch, rawPitch, adaptiveFilterTau, dt)

    local rawRollRate = 0
    local rawPitchRate = 0

    if adaptivePrevRoll ~= nil then
        rawRollRate = (adaptiveRoll - adaptivePrevRoll) / dt
    end
    if adaptivePrevPitch ~= nil then
        rawPitchRate = (adaptivePitch - adaptivePrevPitch) / dt
    end

    adaptivePrevRoll = adaptiveRoll
    adaptivePrevPitch = adaptivePitch

    adaptiveRollRate = lowPass(adaptiveRollRate, rawRollRate, adaptiveRateFilterTau, dt)
    adaptivePitchRate = lowPass(adaptivePitchRate, rawPitchRate, adaptiveRateFilterTau, dt)

    local rollErr = deadzoneSigned(adaptiveRoll, adaptiveDeadAngle)
    local pitchErr = deadzoneSigned(adaptivePitch, adaptiveDeadAngle)

    -- PD attitude control. D is only active while the corresponding attitude
    -- is outside the dead-zone, preventing suspension chatter on tiny road noise.
    local rollCmd = adaptiveRollKp * rollErr
    local pitchCmd = adaptivePitchKp * pitchErr

    if rollErr ~= 0 then
        rollCmd = rollCmd + adaptiveRollKd * adaptiveRollRate
    end
    if pitchErr ~= 0 then
        pitchCmd = pitchCmd + adaptivePitchKd * adaptivePitchRate
    end

    rollCmd = clamp(rollCmd, -adaptiveMaxCorrection, adaptiveMaxCorrection)
    pitchCmd = clamp(pitchCmd, -adaptiveMaxCorrection, adaptiveMaxCorrection)

    -- Same sign convention as the original script:
    -- positive roll  -> left side up, right side down
    -- positive pitch -> rear up, front down
    local targetFL, targetFR, targetRL, targetRR = fitOffsetsToTravel(
        0,
         rollCmd - pitchCmd,
        -rollCmd - pitchCmd,
         rollCmd + pitchCmd,
        -rollCmd + pitchCmd
    )

    local maxStep = adaptiveRateMax * dt
    liftFL = moveTowards(liftFL, targetFL, maxStep)
    liftFR = moveTowards(liftFR, targetFR, maxStep)
    liftRL = moveTowards(liftRL, targetRL, maxStep)
    liftRR = moveTowards(liftRR, targetRR, maxStep)

    return liftFL, liftFR, liftRL, liftRR
end

local function updateAdaptiveSport(dt, liftFL, liftFR, liftRL, liftRR)
    local rawRoll = readAttitude()

    sportRoll = lowPass(sportRoll, rawRoll, sportFilterTau, dt)

    local rawRollRate = 0
    if sportPrevRoll ~= nil then
        rawRollRate = (sportRoll - sportPrevRoll) / dt
    end
    sportPrevRoll = sportRoll
    sportRollRate = lowPass(sportRollRate, rawRollRate, sportRateFilterTau, dt)

    local steer = electrics.values.steering
        or electrics.values.steering_input
        or 0
    local speed = math.abs(electrics.values.wheelspeed or 0)

    local speedRange = math.max(sportFullSpeed - sportSpeedMin, 0.1)
    local speedBlend = clamp((speed - sportSpeedMin) / speedRange, 0, 1)
    local steerMag = clamp(
        (math.abs(steer) - sportSteerDead) / math.max(1 - sportSteerDead, 0.01),
        0, 1
    )

    local rollErr = deadzoneSigned(sportRoll, sportDeadAngle)

    -- Real PD anti-roll:
    --   P reacts to body roll.
    --   D keeps its SIGN, so it damps the motion instead of always adding force.
    -- Steering/speed feed-forward only increases authority; it never decides
    -- which side to lift, avoiding steering-sign convention problems.
    local rollCmd = sportRollKp * rollErr

    if rollErr ~= 0 or math.abs(sportRollRate) > 0.15 then
        rollCmd = rollCmd + sportRollKd * sportRollRate
    end

    local ffMultiplier = 1 + steerMag * speedBlend * sportFFgain
    rollCmd = rollCmd * ffMultiplier

    -- Below the sport activation speed, smoothly return to neutral.
    if speed < sportSpeedMin then
        rollCmd = 0
    end

    rollCmd = clamp(rollCmd, -sportMaxCorrection, sportMaxCorrection)

    local targetFL, targetFR, targetRL, targetRR = fitOffsetsToTravel(
        0,
         rollCmd,
        -rollCmd,
         rollCmd,
        -rollCmd
    )

    local targetMagnitude = math.max(
        math.abs(targetFL), math.abs(targetFR),
        math.abs(targetRL), math.abs(targetRR)
    )

    local rate = sportRateMax
    if targetMagnitude < 1e-4 then
        rate = sportRelaxRate
    end

    local maxStep = rate * dt
    liftFL = moveTowards(liftFL, targetFL, maxStep)
    liftFR = moveTowards(liftFR, targetFR, maxStep)
    liftRL = moveTowards(liftRL, targetRL, maxStep)
    liftRR = moveTowards(liftRR, targetRR, maxStep)

    return liftFL, liftFR, liftRL, liftRR
end

local function updateGFX(dt)
    -- Avoid a very large control jump after a pause / frame hitch.
    local controlDt = clamp(dt or 0.016, 0.001, 0.05)

    local finalLevel = autoLevel
    local liftFL = 0
    local liftFR = 0
    local liftRL = 0
    local liftRR = 0

    local wheelspeed = math.abs(electrics.values.wheelspeed or 0)
    if mode ~= "outTrouble"
       and autoLevel == 0
       and wheelspeed >= highSpeed / 3.6 then
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

        finalLevel = clamp(
            (electrics.values['lift0'] or 0) + (otSign or -1) * controlDt,
            dropLevel,
            liftLevel
        )

        electrics.values['lift0'] = finalLevel
        lift0 = finalLevel

    elseif mode == "adaptive" then
        liftFL = electrics.values['liftFL'] or 0
        liftFR = electrics.values['liftFR'] or 0
        liftRL = electrics.values['liftRL'] or 0
        liftRR = electrics.values['liftRR'] or 0

        liftFL, liftFR, liftRL, liftRR =
            updateAdaptive(controlDt, liftFL, liftFR, liftRL, liftRR)

        electrics.values['lift0'] = 0
        lift0 = 0

    elseif mode == "adaptiveSport" then
        liftFL = electrics.values['liftFL'] or 0
        liftFR = electrics.values['liftFR'] or 0
        liftRL = electrics.values['liftRL'] or 0
        liftRR = electrics.values['liftRR'] or 0

        liftFL, liftFR, liftRL, liftRR =
            updateAdaptiveSport(controlDt, liftFL, liftFR, liftRL, liftRR)

        electrics.values['lift0'] = 0
        lift0 = 0
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
    local previousMode = mode

    if Mode == "auto"
       or Mode == "manual"
       or Mode == "outTrouble"
       or Mode == "adaptive"
       or Mode == "adaptiveSport" then
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

    if mode == "outTrouble" then
        otSign = -1
    end

    -- Reset derivative/filter history on mode entry so the first frame cannot
    -- create a false rate spike.
    if mode ~= previousMode then
        if mode == "adaptive" then
            resetAdaptiveState()
        elseif mode == "adaptiveSport" then
            resetSportState()
        end
    end

    guihooks.message("Chassis Adjust Mode is now " .. mode .. " mode.", 5, "")
end

-- public interface
M.switchMode = switchMode
M.adjustChassis = adjustChassis
M.resetChassis = resetChassis
M.setParameters = setParameters

M.init = onInit
M.reset = onInit
M.updateGFX = updateGFX

return M
