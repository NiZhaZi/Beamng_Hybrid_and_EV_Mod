-- wiper.lua - 2025.6.10 - wiper control
-- by NZZ
-- version 0.0.6 alpha
-- final edit - 2025.9.30 23:36

-- Full files at https://github.com/NiZhaZi/Beamng_Hybrid_and_EV_Mod

local M = {}

local abs = math.abs

local wiperAuto = nil

local wiper = nil
local wiperSpeed = nil
local direction = 1

local wiperSoundUp = nil
local wiperSoundDown = nil
local soundVolume = nil

local ifImpactActive = nil
local brakeThreshold = nil

local function updateGFX(dt)

    local rainLevel = tonumber(obj:getLastMailbox("rainLevel"))
    if wiperAuto then
        if rainLevel > 0 then
            wiper = true
            wiperSpeed = 0.075 * rainLevel + 100
        else
            wiper = false
            wiperSpeed = 100
        end
    end

    if wiper and electrics.values.ignitionLevel == 2 then
        -- action
        electrics.values.wiper = math.min(math.max(electrics.values.wiper + direction * wiperSpeed * dt, 0), 90)
        if electrics.values.wiper >= 90 or electrics.values.wiper <= 0 then
            direction = -direction
            if direction == 1 then
                obj:cutSFX(wiperSoundDown)
            elseif direction == -1 then
                obj:cutSFX(wiperSoundUp)
            end
        end
        -- sound
        if direction == 1 then
            obj:setVolume(wiperSoundUp, soundVolume)
            obj:playSFX(wiperSoundUp)
        elseif direction == -1 then
            obj:setVolume(wiperSoundDown, soundVolume)
            obj:playSFX(wiperSoundDown)
        end
    else
        -- action
        electrics.values.wiper = math.max(electrics.values.wiper - 100 * dt, 0)
        wiperSpeed = 100
        direction = 1
        -- sound
        obj:setVolume(wiperSoundUp, 0)
        obj:stopSFX(wiperSoundUp)

        obj:setVolume(wiperSoundDown, 0)
        obj:stopSFX(wiperSoundDown)
    end

    if ifImpactActive then
        if (abs(sensors.gx2) > brakeThreshold or abs(sensors.gy2) > brakeThreshold) or ((sensors.gz2 - powertrain.currentGravity) > brakeThreshold) then
            wiperAuto = false
            wiper = true
        end
    end

end

local function init(jbeamData)
    obj:queueGameEngineLua('extensions.load("weatherToVe")')
    -- obj:queueGameEngineLua('extensions.unload("weatherToVe")')

    wiperAuto = true

    wiper = false
    wiperSpeed = 100
    electrics.values.wiper = 0

    local wiperSoundFile1 = "art/sound/wipers1.wav"
    local wiperSoundFile2 = "art/sound/wipers2.wav"

    for v, node in pairs (v.data.nodes) do	--for finding out the node ID
		if node.name == jbeamData.nodeName then
			wiperSoundUp = obj:createSFXSource(wiperSoundFile1, "AudioDefaultLoop3D", "", v)
            wiperSoundDown = obj:createSFXSource(wiperSoundFile2, "AudioDefaultLoop3D", "", v)
		end
	end

    soundVolume = jbeamData.soundVolume or 0.25

    ifImpactActive = jbeamData.ifImpactActive or true
    brakeThreshold = jbeamData.brakeThreshold or 50
end

local function reset(jbeamData)
    obj:setVolume(wiperSoundUp, 0)
    obj:stopSFX(wiperSoundUp)
    obj:setVolume(wiperSoundDown, 0)
    obj:stopSFX(wiperSoundDown)

    wiperAuto = true

    wiper = false
    wiperSpeed = 100
    electrics.values.wiper = 0

    local wiperSoundFile1 = "art/sound/wipers1.wav"
    local wiperSoundFile2 = "art/sound/wipers2.wav"

    for v, node in pairs (v.data.nodes) do	--for finding out the node ID
		if node.name == jbeamData.nodeName then
			wiperSoundUp = obj:createSFXSource(wiperSoundFile1, "AudioDefaultLoop3D", "", v)
            wiperSoundDown = obj:createSFXSource(wiperSoundFile2, "AudioDefaultLoop3D", "", v)
		end
	end
end

local function swicthAutoWiper()
    wiperAuto = not wiperAuto
    if not wiperAuto then
        wiperSpeed = 100
    end
    if wiperAuto then
        gui.message({ txt = "Wiper Auto" }, 5, "", "")
    else
        gui.message({ txt = "Wiper Manual" }, 5, "", "")
    end
end

local function swicthWiper()
    if wiperAuto then
        wiperAuto = false
        wiperSpeed = 100
        gui.message({ txt = "Wiper Manual" }, 5, "", "")
    end
    wiper = not wiper
    if wiper then
        gui.message({ txt = "Wiper On" }, 5, "", "")
    else
        gui.message({ txt = "Wiper Off" }, 5, "", "")
    end
end

local function setWiperSpeed(num)
    wiperSpeed = math.min(math.max(wiperSpeed + num, 100), 250)
    if num > 0 then
        gui.message({ txt = "Wiper Speed Up" }, 5, "", "")
    elseif num < 0 then
        gui.message({ txt = "Wiper Speed Down" }, 5, "", "")
    else
        gui.message({ txt = "What Are You Doing?" }, 5, "", "")
    end
end

M.swicthAutoWiper = swicthAutoWiper
M.swicthWiper = swicthWiper
M.setWiperSpeed = setWiperSpeed

M.onInit = init
M.onReset = reset
M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M