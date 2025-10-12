-- dynamicAWD.lua - 2025.10.12 22:09 - center differential control for activeLock
-- by NZZ
-- version 0.0.1 alpha
-- final edit - 2025.10.12 22:09

local M = {}

local abs = math.abs
local floor = math.floor

local AVtoRPM = 9.549296596425384

local centerDiff = nil

local defaultSplit = nil
local mainShaft = nil

local function resetSplit()
	centerDiff.diffTorqueSplitA = 1 - defaultSplit
	centerDiff.diffTorqueSplitB = defaultSplit
end

local function _2wdMode()
	centerDiff.diffTorqueSplitA = 1 - mainShaft
	centerDiff.diffTorqueSplitB = mainShaft
end

local function updateSplit(split)
	-- If 0 <= split <= 1, follow the input value.
	-- If split < 0, awd reset to default.
	-- If split > 0, awd off and switch to 2wd.
	if split >= 0 and split <= 1 then
		centerDiff.diffTorqueSplitA = 1 - split
		centerDiff.diffTorqueSplitB = split
	elseif split < 0 then
		resetSplit()
	else
		_2wdMode()
	end
end

local function updateGFX(dt)

end

local function init(jbeamData)
	local diffName = jbeamData.diffName or "transferCase"
	centerDiff = powertrain.getDevice(diffName)
	
	defaultSplit = centerDiff.diffTorqueSplitB
	mainShaft = jbeamData.defaultMainShaft or 0
end

local function reset(jbeamData)

end

local function setParameters(parameters)
	if parameters.split then
		local split = parameters.split
    	updateSplit(split)
	end
end

M.resetSplit = resetSplit
M._2wdMode = _2wdMode
M.updateSplit = updateSplit

M.init = init
M.reset = reset
M.updateGFX = updateGFX

M.setParameters = setParameters

return M