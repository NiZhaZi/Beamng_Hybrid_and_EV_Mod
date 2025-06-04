local M = {}

local autoHeadLight = nil

local function updateGFX(dt)

end


local function init(jbeamData)
    electrics.values.autoHeadLight = jbeamData.autoHeadLight
end

local function switch()
    local ahl = electrics.values.autoHeadLight
    electrics.values.autoHeadLight = -1 * electrics.values.autoHeadLight + 1
end

M.switch = switch

M.updateGFX = updateGFX
M.init = init
M.reset = init

return M