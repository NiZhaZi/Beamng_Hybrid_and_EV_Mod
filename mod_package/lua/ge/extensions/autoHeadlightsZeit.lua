-- written by DaddelZeit
-- DO NOT USE ANY PART OF THIS CODE WITHOUT EXPLICIT PERMISSION

local M = {}

-- frame timer
local checktimer = 0
local vehTable = {}
local currentVehicleIndex = 0
local vehData = {}
local obbTable = {}
local checkHighForAll = false

local function getCombinedAmbColor(ambcolor)
    local r = ambcolor[1]
    local g = ambcolor[2]
    local b = ambcolor[3]
    return (r+g+b) / 3
end

local function getAmbColor(veh)
    for _, v in pairs(scenetree.findClassObjects("Zone")) do
        local object = scenetree.findObject(v)
        if object then
            if obbTable[object:getId()] and obbTable[object:getId()]:isContained(veh:getPosition()) and object.useAmbientLightColor then
                return getCombinedAmbColor(object.ambientLightColor:toTable())
            elseif not obbTable[object:getId()] then
                local obb = OrientedBox3F()
                obb:set2(object:getTransform(), object:getScale())
                obbTable[object:getId()] = obb
            end
        end
    end

    -- we're sure that the vehicle is not inside a zone at this point
    local sky = scenetree.sunsky
    if not sky and scenetree.findClassObjects("ScatterSky")[1] then scenetree.findObject(scenetree.findClassObjects("ScatterSky")[1]) end
    if sky and sky.ambientScale then return getCombinedAmbColor(sky.ambientScale:toTable()) else return 1 end
end

local function updateVehData(veh, vehId)
    if not vehData[vehId] then vehData[vehId] = {} end
    vehData[vehId].dir = veh:getDirectionVector()
    vehData[vehId].lightsState = core_vehicleBridge.getCachedVehicleData(vehId, "lights_state")
end

local function getHighBeam(veh, ambcol, checkAllVehs)
    local vehId = veh:getId()
    if ((vehId == be:getPlayerVehicleID(0)) or checkAllVehs) and ambcol < 0.55 then
        if vehData[vehId] and vehData[vehId].lightsState and vehData[vehId].lightsState >= 1 then
            for i = 0, be:getObjectCount()-1 do
                local otherVeh = be:getObject(i)
                local otherVehId = otherVeh:getId()

                if otherVehId == vehId then
                    goto skip
                end

                if vehData[otherVehId] and (vehData[otherVehId].lightsState or 0) ~= 0 then
                    local otherVehOBB = otherVeh:getSpawnWorldOOBB()
                    local bbCenter = otherVehOBB:getCenter()
                    local axis0, axis1, axis2 = otherVehOBB:getAxis(0), otherVehOBB:getAxis(1), otherVehOBB:getAxis(2)
                    local halfExtentsX, halfExtentsY, halfExtentsZ = otherVehOBB:getHalfExtents().x, otherVehOBB:getHalfExtents().y, otherVehOBB:getHalfExtents().z

                    --local distThreshold = 130
                    if vehData[otherVehId].lightsState == 1 then
                        halfExtentsX, halfExtentsY, halfExtentsZ = otherVehOBB:getHalfExtents().x*15, otherVehOBB:getHalfExtents().y*1.4, otherVehOBB:getHalfExtents().z*5
                        --distThreshold = 130
                    elseif vehData[otherVehId].lightsState == 2 then
                        halfExtentsX, halfExtentsY, halfExtentsZ = otherVehOBB:getHalfExtents().x*25, otherVehOBB:getHalfExtents().y*4, otherVehOBB:getHalfExtents().z*12.5
                        --distThreshold = 240
                    end

                    local result1, result2 = intersectsRay_OBB(veh:getPosition(), vehData[vehId].dir, bbCenter, halfExtentsX*axis0, halfExtentsY*axis1, halfExtentsZ*5*axis2)
                    if (result1 ~= math.huge and result1 >= 0) or (result2 ~= math.huge and result2 >= 0) then
                        -- check if the car is behind eg. a wall
                        local playerBBCenter = veh:getSpawnWorldOOBB():getCenter()
                        local staticRay = Engine.castRay(playerBBCenter, bbCenter, true, true)
                        if (staticRay and staticRay.dist or math.huge) >= playerBBCenter:distance(bbCenter) then
                            return 0
                        end
                    end
                end
                ::skip::
            end
        end
        return 1
    else
        return 0
    end
end

local function manageChecks(vehId)
    local vehObj = be:getObjectByID(vehId)
    if not vehObj then goto skip end
    local ambientColor = getAmbColor(vehObj) or 0
    local lightBaseVal = (ambientColor < 0.7) and 1 or 0
    local highBeamsVal = getHighBeam(vehObj, ambientColor, checkHighForAll) or 0

    if vehData[vehId].lastLightBaseVal and vehData[vehId].lastHighBeamsVal and (vehData[vehId].lastLightBaseVal ~= lightBaseVal or vehData[vehId].lastHighBeamsVal ~= highBeamsVal) then
        vehObj:queueLuaCommand("autoHeadlightsZeit.updateAutoHeadlights("..lightBaseVal + highBeamsVal..")")
    end

    vehData[vehId].lastLightBaseVal = lightBaseVal
    vehData[vehId].lastHighBeamsVal = highBeamsVal
    ::skip::
end

local function onUpdate(dt)
    checktimer = checktimer + 1
    if checktimer <= 2 then return end

    for i = 0, be:getObjectCount()-1 do
        local vehObj = be:getObject(i)
        updateVehData(vehObj, vehObj:getId())
    end

    if not next(vehTable) then return end

    currentVehicleIndex=(currentVehicleIndex+1)%#vehTable
    local _,curVehId = next(vehTable, currentVehicleIndex)
    manageChecks(curVehId)

    checktimer = 0
end

local function registerVeh(id)
    -- first try and unregister, then re-register in case of lua reload
    core_vehicleBridge.unregisterValueChangeNotification(be:getObjectByID(id), "lights_state")
    core_vehicleBridge.registerValueChangeNotification(be:getObjectByID(id), "lights_state")

    local vehDetails = core_vehicles.getVehicleDetails(id)
    if vehDetails.configs.aggregates and vehDetails.configs.aggregates.Years and vehDetails.configs.aggregates.Years.min and vehDetails.configs.aggregates.Years.min >= 2010 then
        table.insert(vehTable, id)
    elseif arrayFindValueIndex(vehTable, id) then
        table.remove(vehTable, arrayFindValueIndex(vehTable, id))
    end
end

local function onExtensionLoaded()
    --print("autoLowBeamZeit Loaded")
    local graphQual = core_settings_graphic.getOptions().GraphicLightingQuality.get()
    checkHighForAll = (graphQual == "Normal" or graphQual == "High" or graphQual == "Ultra") or false
end

M.manageChecks = manageChecks
M.updateVehData = updateVehData
M.registerVeh = registerVeh
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

return M