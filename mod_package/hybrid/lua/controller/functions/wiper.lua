local M = {}

local wiper = nil
local wiperSpeed = nil
local direction = 1

local function updateGFX(dt)
    if wiper and electrics.values.ignitionLevel == 2 then
        electrics.values.wiper = math.min(math.max(electrics.values.wiper + direction * wiperSpeed * dt, 0), 90)
        if electrics.values.wiper >= 90 or electrics.values.wiper <= 0 then
            direction = -direction
        end
    else
        electrics.values.wiper = math.max(electrics.values.wiper - 100 * dt, 0)
        wiperSpeed = 100
    end

end

local function init()
    wiper = false
    wiperSpeed = 100
    electrics.values.wiper = 0
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
M.onReset = init
M.init = init
M.reset = init
M.updateGFX = updateGFX

return M