-- wiper.lua - 2025.6.10 - wiper control
-- by NZZ
-- version 0.0.3 alpha
-- final edit - 2025.6.16 17:46

-- Full files at https://github.com/NiZhaZi/Beamng_Hybrid_and_EV_Mod

local M = {}

local wiper = nil
local wiperSpeed = nil
local direction = 1

local wiperSoundUp = nil
local wiperSoundDown = nil
local soundVolume = nil

local function updateGFX(dt)
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
end

local function init(jbeamData)
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
end

local function reset(jbeamData)
    obj:setVolume(wiperSoundUp, 0)
    obj:stopSFX(wiperSoundUp)
    obj:setVolume(wiperSoundDown, 0)
    obj:stopSFX(wiperSoundDown)

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

local function swicthWiper()
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

M.swicthWiper = swicthWiper
M.setWiperSpeed = setWiperSpeed

M.onInit = init
M.onReset = reset
M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M