local M = {}

local function getRainLevel()
    if dynamicWeatherMK_weather then
        local rainLevel = dynamicWeatherMK_weather.getObjs().rain.numDrops
        if rainLevel then
            return rainLevel
        else
            return 0
        end
    else
        return 0
    end
end

local function getFogLevel()
    if dynamicWeatherMK_weather then
        local fogLevel = dynamicWeatherMK_weather.getObjs().fog.fogDensity
        if fogLevel then
            return fogLevel
        else
            return 0
        end
    else
        return 0
    end
end

local function onExtensionLoaded()

end

local function onUpdate(dt, dtSim)
    -- local weather = dynamicWeatherMK_weather.getCurrentWeatherEvent()
    be:sendToMailbox("rainLevel", getRainLevel())
    be:sendToMailbox("fogLevel", getFogLevel())
end

M.onExtensionLoaded = onExtensionLoaded
M.onVehicleSwitched = onExtensionLoaded
M.onVehicleDestroyed = onExtensionLoaded
M.onVehicleSpawned = onExtensionLoaded
M.onClientPostStartMission = onExtensionLoaded
M.registerVehicle = onExtensionLoaded
M.onUpdate = onUpdate
return M