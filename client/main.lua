local QBCore = exports['qb-core']:GetCoreObject()
local cam = nil
local inCharSelection = false
local charData = {}
local currentPed = nil
local cinematicThread = nil
local lastSelectedCitizenid = nil
local inSpawnSelector = false

CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            Citizen.Wait(1500)
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            Citizen.Wait(500)
            TriggerServerEvent('qrp-multicharacter:server:requestCharacters')
            return
        end
    end
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })
    inSpawnSelector = false
    cb('ok')
end)

RegisterNUICallback('changeSpawnLocation', function(data, cb)
    if not data.coords then
        cb('error')
        return
    end

    if not cam then
        cb('error')
        return
    end

    local coords = data.coords
    local camHeight = 80.0
    local camDistance = 100.0

    local camX = coords.x - camDistance
    local camY = coords.y - camDistance
    local camZ = coords.z + camHeight

    DoScreenFadeOut(300)
    Citizen.Wait(300)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local loadRadius = 200.0
    for i = 1, 8 do
        local angle = (i - 1) * 45
        local rad = math.rad(angle)
        local offsetX = math.cos(rad) * loadRadius
        local offsetY = math.sin(rad) * loadRadius
        RequestCollisionAtCoord(coords.x + offsetX, coords.y + offsetY, coords.z)
    end

    SetFocusArea(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

    local collisionTimeout = GetGameTimer() + 3000
    while GetGameTimer() < collisionTimeout do
        if HasCollisionLoadedAroundEntity(PlayerPedId()) then
            break
        end
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Citizen.Wait(0)
    end

    SetCamCoord(cam, camX, camY, camZ)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + 2.0)
    SetCamFov(cam, 50.0)

    Citizen.Wait(1000)

    DoScreenFadeIn(300)

    cb('ok')
end)

RegisterNUICallback('spawnPlayer', function(data, cb)
    if not data.coords then
        cb('error')
        return
    end

    inSpawnSelector = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })

    if cam then
        DestroyCamera()
    end

    DoScreenFadeOut(500)
    Wait(500)

    local ped = PlayerPedId()
    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z, false, false, false, false)
    SetEntityHeading(ped, data.coords.w or 0.0)
    FreezeEntityPosition(ped, false)

    Wait(500)
    DoScreenFadeIn(500)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    cb('ok')
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    if not data.citizenid then
        cb('error')
        return
    end

    if currentPed and DoesEntityExist(currentPed) then
        ClearPedTasksImmediately(currentPed)
        ClearPedSecondaryTask(currentPed)

        if IsPedActiveInScenario(currentPed) then
            ClearPedTasks(currentPed)
        end

        StopAnimTask(currentPed, "friends@frj@ig_1", "wave_a", -1.0)

        Citizen.Wait(1000) 

        if not HasAnimDictLoaded("friends@frj@ig_1") then
            RequestAnimDict("friends@frj@ig_1")
            local animTimeout = GetGameTimer() + 2000
            while not HasAnimDictLoaded("friends@frj@ig_1") and GetGameTimer() < animTimeout do
                Citizen.Wait(0)
            end
        end

        if HasAnimDictLoaded("friends@frj@ig_1") then
            TaskPlayAnim(currentPed, "friends@frj@ig_1", "wave_a", 8.0, -8.0, 3000, 0, 0, false, false, false)

            local animWaitTimeout = GetGameTimer() + 500
            while GetGameTimer() < animWaitTimeout do
                if IsEntityPlayingAnim(currentPed, "friends@frj@ig_1", "wave_a", 3) then
                    break
                end
                Citizen.Wait(0)
            end

            local animStartTime = GetGameTimer()
            while GetGameTimer() - animStartTime < 7000 and DoesEntityExist(currentPed) do
                if not IsEntityPlayingAnim(currentPed, "friends@frj@ig_1", "wave_a", 3) then
                    break
                end
                Citizen.Wait(0)
            end
        end
    end

    TriggerServerEvent('qrp-multicharacter:server:selectCharacter', data.citizenid)

    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    CloseCharacterSelection()

    TriggerServerEvent('qrp-multicharacter:server:createCharacter', data)

    cb('ok')
end)

local isTransitioning = false

RegisterNUICallback('changeSlot', function(data, cb)
    if isTransitioning then
        cb('busy')
        return
    end

    if not data.citizenid then
        if currentPed and DoesEntityExist(currentPed) then
            if cinematicThread then
                cinematicThread = nil
            end

            ClearPedTasks(currentPed)
            DeleteEntity(currentPed)
            currentPed = nil


            if Config.Camera.mode == "cinematic" and Config.Camera.cinematic.useRPC then
                local idleCam = Config.Camera.cinematic.camera.idle
                SetCamCoord(cam, idleCam.coords.x, idleCam.coords.y, idleCam.coords.z)
                PointCamAtCoord(cam, idleCam.pointAt.x, idleCam.pointAt.y, idleCam.pointAt.z)
                SetCamFov(cam, idleCam.fov)
            end
        end
        lastSelectedCitizenid = nil
        cb('ok')
        return
    end

    if data.citizenid == lastSelectedCitizenid then
        cb('ok')
        return
    end

    isTransitioning = true
    lastSelectedCitizenid = data.citizenid

    local oldPedLocation = nil
    if currentPed and DoesEntityExist(currentPed) then
        oldPedLocation = GetEntityCoords(currentPed)

        if cinematicThread then
            cinematicThread = nil
        end

        ClearPedTasks(currentPed)
    end

    cb('ok')

    if Config.Debug then
        print("[qrp-multicharacter] Requesting appearance for: " .. tostring(data.citizenid))
    end

    if oldPedLocation then
        TransitionCameraToSky(oldPedLocation, function()
            if currentPed and DoesEntityExist(currentPed) then
                DeleteEntity(currentPed)
                currentPed = nil
            end

            QBCore.Functions.TriggerCallback('qrp-multicharacter:server:getAppearance', function(appearance)
                if Config.Debug then
                    print("[qrp-multicharacter] Appearance callback received. Has appearance: " .. tostring(appearance ~= nil))
                end

                if data.citizenid == lastSelectedCitizenid then
                    TransitionToCharacter(data.citizenid, appearance, true) 
                else
                    if Config.Debug then
                        print("[qrp-multicharacter] Character changed, canceling transition")
                    end
                    isTransitioning = false
                end
            end, data.citizenid)
        end)
    else
        QBCore.Functions.TriggerCallback('qrp-multicharacter:server:getAppearance', function(appearance)
            if Config.Debug then
                print("[qrp-multicharacter] Appearance callback received. Has appearance: " .. tostring(appearance ~= nil))
            end

            if data.citizenid == lastSelectedCitizenid then
                TransitionToCharacter(data.citizenid, appearance, false) 
            else
                if Config.Debug then
                    print("[qrp-multicharacter] Character changed, canceling transition")
                end
                isTransitioning = false
            end
        end, data.citizenid)
    end
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    if not data.citizenid then
        cb('error')
        return
    end

    if Config.DeleteCharacter.requireConfirmation then
        -- TODO: Onay dialogu eklenebilir
    end

    TriggerServerEvent('qrp-multicharacter:server:deleteCharacter', data.citizenid)

    cb('ok')
end)

function OpenCharacterSelection(characters)
    if inCharSelection then return end

    inCharSelection = true
    charData = characters or {}

    RequestAnimDict("friends@frj@ig_1")
    while not HasAnimDictLoaded("friends@frj@ig_1") do
        Wait(10)
    end

    SetupCamera()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        data = {
            characters = charData,
            maxCharacters = Config.MaxCharacters
        }
    })

    DisablePlayerControls()
end

function CloseCharacterSelection()
    if not inCharSelection then return end

    inCharSelection = false
    lastSelectedCitizenid = nil

    DestroyCamera()

    if cinematicThread then
        cinematicThread = nil
    end

    if currentPed and DoesEntityExist(currentPed) then
        DeleteEntity(currentPed)
        currentPed = nil
    end

    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })

    EnablePlayerControls()
end

function SetupCamera()
    if cam then
        DestroyCamera()
    end

    local mode = Config.Camera.mode

    if mode == "cinematic" and Config.Camera.cinematic.useRPC then
        SetupCinematicCamera()
    else
        SetupStaticCamera()
    end
end

function SetupStaticCamera()
    local coords = Config.Camera.static.coords

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, coords.x, coords.y, coords.z)
    SetCamRot(cam, 0.0, 0.0, coords.w, 2)
    SetCamFov(cam, Config.Camera.static.fov)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    if Config.Camera.static.enableBlur then
        TriggerScreenblurFadeIn(Config.Camera.static.blurIntensity)
    end

    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 10.0)
    FreezeEntityPosition(ped, true)
end

function UpdatePedAppearance(appearance)
    if not currentPed or not DoesEntityExist(currentPed) then
        return
    end

    if not appearance then
        ClearAllPedProps(currentPed)
        SetPedDefaultComponentVariation(currentPed)
        return
    end

    if Config.Appearance.script == "qb-clothing" or Config.Appearance.script == "illenium-appearance" then
        ApplyClothingAppearance(currentPed, appearance)
    elseif Config.Appearance.script == "fivem-appearance" then
        ApplyFiveMAppearance(currentPed, appearance)
    end
end

function ApplyClothingAppearance(ped, data)
    if not data then return end

    if Config.Debug and data.model then
        local currentModel = GetEntityModel(ped)
        local newModel = type(data.model) == "string" and GetHashKey(data.model) or data.model
        print("[qrp-multicharacter] Skipping model change in character selection (Current: " .. tostring(currentModel) .. ", Data: " .. tostring(newModel) .. ")")
    end

    if data.headBlend then
        SetPedHeadBlendData(ped,
            data.headBlend.shapeFirst or 0,
            data.headBlend.shapeSecond or 0,
            data.headBlend.shapeThird or 0,
            data.headBlend.skinFirst or 0,
            data.headBlend.skinSecond or 0,
            data.headBlend.skinThird or 0,
            data.headBlend.shapeMix or 0.0,
            data.headBlend.skinMix or 0.0,
            data.headBlend.thirdMix or 0.0
        )
    end

    if data.faceFeatures then
        for i = 0, 19 do
            if data.faceFeatures[i] then
                SetPedFaceFeature(ped, i, data.faceFeatures[i])
            end
        end
    end

    if data.headOverlays then
        for i = 0, 12 do
            if data.headOverlays[i] then
                local overlay = data.headOverlays[i]
                SetPedHeadOverlay(ped, i, overlay.style or 0, overlay.opacity or 0.0)
                if overlay.color then
                    SetPedHeadOverlayColor(ped, i, 1, overlay.color or 0, overlay.secondColor or 0)
                end
            end
        end
    end

    if data.hair then
        SetPedComponentVariation(ped, 2, data.hair.style or 0, 0, 0)
        SetPedHairColor(ped, data.hair.color or 0, data.hair.highlight or 0)
    end

    if data.components then
        for k, v in pairs(data.components) do
            local componentId = tonumber(k)
            if componentId then
                SetPedComponentVariation(ped, componentId, v.drawable or 0, v.texture or 0, 0)
            end
        end
    end

    if data.props then
        for k, v in pairs(data.props) do
            local propId = tonumber(k)
            if propId then
                if v.drawable and v.drawable > 0 then
                    SetPedPropIndex(ped, propId, v.drawable or 0, v.texture or 0, true)
                else
                    ClearPedProp(ped, propId)
                end
            end
        end
    end

    if data.eyeColor then
        SetPedEyeColor(ped, data.eyeColor)
    end

    if Config.Debug then
        print("[qrp-multicharacter] Appearance applied successfully!")
    end
end

function ApplyFiveMAppearance(ped, data)

    if exports['fivem-appearance'] then
        exports['fivem-appearance']:setPedAppearance(ped, data)
    end
end

function SetupCinematicCamera()
    local config = Config.Camera.cinematic

    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)
    SetEntityCoords(playerPed, 0.0, 0.0, -1000.0)
    FreezeEntityPosition(playerPed, true)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    local idleCam = config.camera.idle
    SetCamCoord(cam, idleCam.coords.x, idleCam.coords.y, idleCam.coords.z)
    PointCamAtCoord(cam, idleCam.pointAt.x, idleCam.pointAt.y, idleCam.pointAt.z)
    SetCamFov(cam, idleCam.fov)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
end

function TransitionCameraToSky(pedLocation, callback)
    local config = Config.Camera.cinematic
    local idleCam = config.camera.idle
    local duration = 1500 

    if Config.Debug then
        print("[qrp-multicharacter] Transitioning camera to sky from: " .. tostring(pedLocation))
    end

    local currentCamPos = GetCamCoord(cam)

    local currentLookAt = vector3(
        pedLocation.x,
        pedLocation.y,
        pedLocation.z + 0.5
    )

    local targetSkyX = pedLocation.x
    local targetSkyY = pedLocation.y
    local targetSkyZ = pedLocation.z + 100.0 

    CreateThread(function()
        local startTime = GetGameTimer()

        while GetGameTimer() - startTime < duration do
            local elapsed = GetGameTimer() - startTime
            local progress = math.min(elapsed / duration, 1.0)

            local easeProgress = 1 - math.pow(1 - progress, 3)

            local camX = currentCamPos.x + (targetSkyX - currentCamPos.x) * easeProgress
            local camY = currentCamPos.y + (targetSkyY - currentCamPos.y) * easeProgress
            local camZ = currentCamPos.z + (targetSkyZ - currentCamPos.z) * easeProgress

            SetCamCoord(cam, camX, camY, camZ)

            local lookAtZ = currentLookAt.z + (currentLookAt.z + 50.0 - currentLookAt.z) * easeProgress
            PointCamAtCoord(cam, pedLocation.x, pedLocation.y, lookAtZ)

            SetCamFov(cam, 50.0)

            Wait(0)
        end

        SetCamCoord(cam, targetSkyX, targetSkyY, targetSkyZ)
        PointCamAtCoord(cam, pedLocation.x, pedLocation.y, pedLocation.z)
        SetCamFov(cam, 50.0)

        if Config.Debug then
            print("[qrp-multicharacter] Camera reached sky position above character")
        end

        if callback then
            callback()
        end
    end)
end

function TransitionToCharacter(citizenid, appearance, fromSky)
    if Config.Debug then
        print("[qrp-multicharacter] TransitionToCharacter called for: " .. tostring(citizenid))
    end

    local config = Config.Camera.cinematic

    local randomIndex = math.random(1, #config.randomLocations)
    local location = config.randomLocations[randomIndex]

    local pedModel = "mp_m_freemode_01"
    if charData and #charData > 0 then
        for _, char in ipairs(charData) do
            if char.citizenid == citizenid then
                local charinfo = json.decode(char.charinfo or "{}")
                if charinfo.gender == 1 then
                    pedModel = "mp_f_freemode_01"
                end
                break
            end
        end
    end

    if Config.Debug then
        print("[qrp-multicharacter] Loading model: " .. pedModel)
    end

    RequestModel(GetHashKey(pedModel))
    local modelTimeout = GetGameTimer() + 5000
    while not HasModelLoaded(GetHashKey(pedModel)) and GetGameTimer() < modelTimeout do
        RequestModel(GetHashKey(pedModel))
        Citizen.Wait(0)
    end

    if not HasModelLoaded(GetHashKey(pedModel)) then
        if Config.Debug then
            print("[qrp-multicharacter] ERROR: Model could not be loaded!")
        end
        isTransitioning = false
        return
    end

    local loadRadius = 200.0
    for i = 1, 8 do
        local angle = (i - 1) * 45
        local rad = math.rad(angle)
        local offsetX = math.cos(rad) * loadRadius
        local offsetY = math.sin(rad) * loadRadius
        RequestCollisionAtCoord(location.x + offsetX, location.y + offsetY, location.z)
    end
    RequestCollisionAtCoord(location.x, location.y, location.z)
    SetFocusArea(location.x, location.y, location.z, 0.0, 0.0, 0.0)

    local collisionTimeout = GetGameTimer() + 5000
    while GetGameTimer() < collisionTimeout do
        if HasCollisionLoadedAroundEntity(PlayerPedId()) then
            break
        end
        RequestCollisionAtCoord(location.x, location.y, location.z)
        Citizen.Wait(0)
    end

    Citizen.Wait(300)

    if Config.Debug then
        print("[qrp-multicharacter] Creating ped at: " .. tostring(location))
    end

    currentPed = CreatePed(4, GetHashKey(pedModel), location.x, location.y, location.z, location.w, false, true)

    if Config.Debug then
        print("[qrp-multicharacter] Ped created: " .. tostring(currentPed) .. " - Exists: " .. tostring(DoesEntityExist(currentPed)))
    end

    SetEntityAsMissionEntity(currentPed, true, true)
    SetEntityInvincible(currentPed, true)
    SetBlockingOfNonTemporaryEvents(currentPed, true)

    SetPedCanRagdoll(currentPed, false)
    SetPedConfigFlag(currentPed, 17, true) 
    SetPedConfigFlag(currentPed, 126, true) 
    SetPedSteersAroundPeds(currentPed, true)
    SetPedSteersAroundObjects(currentPed, true)
    SetPedSteersAroundVehicles(currentPed, true)

    SetEntityCoordsNoOffset(currentPed, location.x, location.y, location.z, false, false, false)
    PlaceObjectOnGroundProperly(currentPed)
    FreezeEntityPosition(currentPed, false)

    if appearance then
        if Config.Debug then
            print("[qrp-multicharacter] Applying appearance...")
        end
        Citizen.Wait(100) 
        UpdatePedAppearance(appearance)

        if currentPed and DoesEntityExist(currentPed) then
            SetEntityAsMissionEntity(currentPed, true, true)
            SetEntityInvincible(currentPed, true)
            SetBlockingOfNonTemporaryEvents(currentPed, true)
            SetPedCanRagdoll(currentPed, false)
            SetPedConfigFlag(currentPed, 17, true)
            SetPedConfigFlag(currentPed, 126, true)
            SetPedSteersAroundPeds(currentPed, true)
            SetPedSteersAroundObjects(currentPed, true)
            SetPedSteersAroundVehicles(currentPed, true)
            FreezeEntityPosition(currentPed, false)

            if Config.Debug then
                print("[qrp-multicharacter] Ped properties reapplied after appearance")
            end
        end
    else
        if Config.Debug then
            print("[qrp-multicharacter] No appearance data!")
        end
    end

    if not currentPed or not DoesEntityExist(currentPed) then
        if Config.Debug then
            print("[qrp-multicharacter] ERROR: Ped does not exist after appearance!")
        end
        isTransitioning = false
        return
    end

    RequestAnimDict(config.walkAnimation)
    local walkAnimTimeout = GetGameTimer() + 2000
    while not HasAnimDictLoaded(config.walkAnimation) and GetGameTimer() < walkAnimTimeout do
        RequestAnimDict(config.walkAnimation)
        Citizen.Wait(0)
    end

    local activityIndex = math.random(1, #config.initialActivities)
    local initialActivity = config.initialActivities[activityIndex]

    if Config.Debug then
        print("[qrp-multicharacter] Starting activity: " .. initialActivity)
    end

    StartInitialActivity(initialActivity)

    if Config.Debug then
        print("[qrp-multicharacter] Starting camera transition... (fromSky: " .. tostring(fromSky or false) .. ")")
    end

    SmoothCameraTransition(location, fromSky)
end

function SmoothCameraTransition(pedLocation, fromSky)
    local config = Config.Camera.cinematic
    local idleCam = config.camera.idle
    local transitionDuration = fromSky and 2000 or config.camera.transition.duration

    Citizen.Wait(100)
    local forwardVector = GetEntityForwardVector(currentPed)

    local followCam = config.camera.follow
    local targetCamX = pedLocation.x + forwardVector.x * followCam.offset.y
    local targetCamY = pedLocation.y + forwardVector.y * followCam.offset.y
    local targetCamZ = pedLocation.z + followCam.offset.z + 0.5

    local midpointX = pedLocation.x
    local midpointY = pedLocation.y
    local midpointZ = pedLocation.z + 100.0

    CreateThread(function()
        if fromSky then
            if Config.Debug then
                print("[qrp-multicharacter] Camera descending from sky...")
            end

            local currentCamPos = GetCamCoord(cam)

            RequestCollisionAtCoord(pedLocation.x, pedLocation.y, pedLocation.z)
            SetFocusArea(pedLocation.x, pedLocation.y, pedLocation.z, 0.0, 0.0, 0.0)

            local collisionTimeout = GetGameTimer() + 3000
            while GetGameTimer() < collisionTimeout do
                if HasCollisionLoadedAroundEntity(currentPed) then
                    break
                end
                RequestCollisionAtCoord(pedLocation.x, pedLocation.y, pedLocation.z)
                Citizen.Wait(0)
            end

            if Config.Debug then
                print("[qrp-multicharacter] Collision loaded, starting camera movement")
            end

            local startTime = GetGameTimer()

            local horizontalDuration = transitionDuration * 0.4
            while GetGameTimer() - startTime < horizontalDuration do
                local elapsed = GetGameTimer() - startTime
                local progress = math.min(elapsed / horizontalDuration, 1.0)
                local easeProgress = progress < 0.5 and 2 * progress * progress or 1 - math.pow(-2 * progress + 2, 2) / 2

                local camX = currentCamPos.x + (midpointX - currentCamPos.x) * easeProgress
                local camY = currentCamPos.y + (midpointY - currentCamPos.y) * easeProgress
                local camZ = midpointZ 

                SetCamCoord(cam, camX, camY, camZ)
                PointCamAtCoord(cam, pedLocation.x, pedLocation.y, pedLocation.z + 0.5)
                SetCamFov(cam, 50.0)

                Citizen.Wait(0)
            end

            local descendStart = GetGameTimer()
            local descendDuration = transitionDuration * 0.6
            while GetGameTimer() - descendStart < descendDuration do
                local elapsed = GetGameTimer() - descendStart
                local progress = math.min(elapsed / descendDuration, 1.0)
                local easeProgress = 1 - math.pow(1 - progress, 3) 

                local camX = midpointX + (targetCamX - midpointX) * easeProgress
                local camY = midpointY + (targetCamY - midpointY) * easeProgress
                local camZ = midpointZ + (targetCamZ - midpointZ) * easeProgress

                SetCamCoord(cam, camX, camY, camZ)
                PointCamAtCoord(cam, pedLocation.x, pedLocation.y, pedLocation.z + 0.5)

                local fov = 50.0 + (followCam.fov - 50.0) * easeProgress
                SetCamFov(cam, fov)

                Citizen.Wait(0)
            end

        else
            local startTime = GetGameTimer()
            local phase1Duration = transitionDuration * 0.4
            local phase2Duration = transitionDuration * 0.6

            while GetGameTimer() - startTime < phase1Duration do
                local elapsed = GetGameTimer() - startTime
                local progress = math.min(elapsed / phase1Duration, 1.0)

                local easeProgress = 1 - math.pow(1 - progress, 3)

                local camX = idleCam.coords.x + (midpointX - idleCam.coords.x) * easeProgress
                local camY = idleCam.coords.y + (midpointY - idleCam.coords.y) * easeProgress
                local camZ = idleCam.coords.z

                local lookX = idleCam.pointAt.x + (pedLocation.x - idleCam.pointAt.x) * easeProgress
                local lookY = idleCam.pointAt.y + (pedLocation.y - idleCam.pointAt.y) * easeProgress
                local lookZ = idleCam.pointAt.z 

                local fov = idleCam.fov + (followCam.fov - idleCam.fov) * easeProgress * 0.3

                RequestCollisionAtCoord(lookX, lookY, lookZ)
                SetFocusArea(lookX, lookY, lookZ, 0.0, 0.0, 0.0)

                SetCamCoord(cam, camX, camY, camZ)
                PointCamAtCoord(cam, lookX, lookY, lookZ)
                SetCamFov(cam, fov)

                Wait(0)
            end

            local phase2Start = GetGameTimer()
            while GetGameTimer() - phase2Start < phase2Duration do
                local elapsed = GetGameTimer() - phase2Start
                local progress = math.min(elapsed / phase2Duration, 1.0)

                local easeProgress = progress < 0.5
                    and 2 * progress * progress
                    or 1 - math.pow(-2 * progress + 2, 2) / 2

                local camX = midpointX + (targetCamX - midpointX) * easeProgress
                local camY = midpointY + (targetCamY - midpointY) * easeProgress
                local camZ = midpointZ + (targetCamZ - midpointZ) * easeProgress

                RequestCollisionAtCoord(pedLocation.x, pedLocation.y, pedLocation.z)
                SetFocusArea(pedLocation.x, pedLocation.y, pedLocation.z, 0.0, 0.0, 0.0)

                PointCamAtCoord(cam, pedLocation.x, pedLocation.y, pedLocation.z + 0.5)

                local fov = idleCam.fov + (followCam.fov - idleCam.fov) * (0.3 + 0.7 * easeProgress)

                SetCamCoord(cam, camX, camY, camZ)
                SetCamFov(cam, fov)

                Wait(0)
            end
        end

        SetCamCoord(cam, targetCamX, targetCamY, targetCamZ)
        PointCamAtCoord(cam, pedLocation.x, pedLocation.y, pedLocation.z + 0.5)
        SetCamFov(cam, followCam.fov)

        isTransitioning = false

        Citizen.Wait(500)
    end)
end

function StartInitialActivity(activity)
    local config = Config.Camera.cinematic

    if activity == "wander" then
        StartWanderMode()
    elseif activity == "stand" then
        TaskStartScenarioInPlace(currentPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
        CreateThread(function()
            Wait(math.random(10000, 15000))
            if inCharSelection and DoesEntityExist(currentPed) then
                ClearPedTasks(currentPed)
                StartWanderMode()
            end
        end)
    elseif activity == "phone" then
        TaskStartScenarioInPlace(currentPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
        CreateThread(function()
            Wait(math.random(10000, 15000))
            if inCharSelection and DoesEntityExist(currentPed) then
                ClearPedTasks(currentPed)
                StartWanderMode()
            end
        end)
    elseif activity == "smoke" then
        TaskStartScenarioInPlace(currentPed, "WORLD_HUMAN_SMOKING", 0, true)
        CreateThread(function()
            Wait(math.random(10000, 15000))
            if inCharSelection and DoesEntityExist(currentPed) then
                ClearPedTasks(currentPed)
                StartWanderMode()
            end
        end)
    end
end

function StartWanderMode()
    local config = Config.Camera.cinematic

    TaskWanderStandard(currentPed, 10.0, 10)

    cinematicThread = CreateThread(function()
        local lastCamPos = nil
        local lastLookAtPos = nil

        while inCharSelection and DoesEntityExist(currentPed) do
            local newPedCoords = GetEntityCoords(currentPed)
            local followCam = config.camera.follow

            local forwardVector = GetEntityForwardVector(currentPed)

            local targetCamX = newPedCoords.x + forwardVector.x * followCam.offset.y
            local targetCamY = newPedCoords.y + forwardVector.y * followCam.offset.y
            local targetCamZ = newPedCoords.z + followCam.offset.z + 0.5

            local camX, camY, camZ
            if lastCamPos then
                local lerpFactorXY = 0.08 
                local lerpFactorZ = 0.03   
                camX = lastCamPos.x + (targetCamX - lastCamPos.x) * lerpFactorXY
                camY = lastCamPos.y + (targetCamY - lastCamPos.y) * lerpFactorXY
                camZ = lastCamPos.z + (targetCamZ - lastCamPos.z) * lerpFactorZ
            else
                camX, camY, camZ = targetCamX, targetCamY, targetCamZ
            end

            lastCamPos = vector3(camX, camY, camZ)
            SetCamCoord(cam, camX, camY, camZ)

            local pedBoneCoords = GetPedBoneCoords(currentPed, 24818, 0.0, 0.0, 0.0)

            local lookAtX, lookAtY, lookAtZ
            if lastLookAtPos then
                local lookAtLerpFactor = 0.05  
                lookAtX = lastLookAtPos.x + (pedBoneCoords.x - lastLookAtPos.x) * lookAtLerpFactor
                lookAtY = lastLookAtPos.y + (pedBoneCoords.y - lastLookAtPos.y) * lookAtLerpFactor
                lookAtZ = lastLookAtPos.z + (pedBoneCoords.z - lastLookAtPos.z) * lookAtLerpFactor
            else
                lookAtX, lookAtY, lookAtZ = pedBoneCoords.x, pedBoneCoords.y, pedBoneCoords.z
            end

            lastLookAtPos = vector3(lookAtX, lookAtY, lookAtZ)
            PointCamAtCoord(cam, lookAtX, lookAtY, lookAtZ)

            SetCamFov(cam, followCam.fov)
            SetCamActive(cam, true)

            Wait(0)
        end
    end)
end


function DestroyCamera()
    if cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cam, false)
        cam = nil
    end

    local mode = Config.Camera.mode
    if mode == "static" and Config.Camera.static.enableBlur then
        TriggerScreenblurFadeOut(500)
    end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
end

function DisablePlayerControls()
    CreateThread(function()
        while inCharSelection do
            DisableAllControlActions(0)
            Wait(0)
        end
    end)
end

function EnablePlayerControls()
    EnableAllControlActions(0)
end

function OpenSpawnSelector(lastLocation)
    if inSpawnSelector then return end

    inSpawnSelector = true

    if not cam then
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
    end

    local firstLocation = lastLocation or Config.SpawnLocations[1].coords
    local coords = firstLocation
    local camHeight = 80.0
    local camDistance = 100.0

    local camX = coords.x - camDistance
    local camY = coords.y - camDistance
    local camZ = coords.z + camHeight

    SetCamCoord(cam, camX, camY, camZ)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + 2.0)
    SetCamFov(cam, 50.0)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openSpawnSelector',
        data = {
            locations = Config.SpawnLocations,
            lastLocation = lastLocation
        }
    })
end

function CloseSpawnSelector()
    if not inSpawnSelector then return end

    inSpawnSelector = false


    if cam then
        DestroyCamera()
    end

    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })
end

RegisterNetEvent('qrp-multicharacter:client:openCharacterSelection', function(characters)
    OpenCharacterSelection(characters)
end)

RegisterNetEvent('qrp-multicharacter:client:closeNUI', function()
    CloseCharacterSelection()
end)

RegisterNetEvent('qrp-multicharacter:client:transitionToSpawnSelector', function(lastLocation)
    if currentPed and DoesEntityExist(currentPed) then
        if IsEntityPlayingAnim(currentPed, "friends@frj@ig_1", "wave_a", 3) then
            local waitStart = GetGameTimer()
            while IsEntityPlayingAnim(currentPed, "friends@frj@ig_1", "wave_a", 3) and (GetGameTimer() - waitStart) < 2500 do
                Wait(50)
            end
            Wait(300)
        end
        FreezeEntityPosition(currentPed, true)
    end

    -- Sadece bir kere fade out yap
    DoScreenFadeOut(500)
    Wait(500)

    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })

    Wait(200)

    local targetLocation = lastLocation or Config.SpawnLocations[1].coords
    local targetCamX = targetLocation.x - 100.0
    local targetCamY = targetLocation.y - 100.0
    local targetCamZ = targetLocation.z + 80.0

    RequestCollisionAtCoord(targetLocation.x, targetLocation.y, targetLocation.z)

    local loadRadius = 200.0
    for i = 1, 8 do
        local angle = (i - 1) * 45
        local rad = math.rad(angle)
        local offsetX = math.cos(rad) * loadRadius
        local offsetY = math.sin(rad) * loadRadius
        RequestCollisionAtCoord(targetLocation.x + offsetX, targetLocation.y + offsetY, targetLocation.z)
    end

    SetFocusArea(targetLocation.x, targetLocation.y, targetLocation.z, 0.0, 0.0, 0.0)

    if cam then
        local currentCamPos = GetCamCoord(cam)

        local duration = 2000
        local startTime = GetGameTimer()

        CreateThread(function()
            while GetGameTimer() - startTime < duration do
                local progress = (GetGameTimer() - startTime) / duration
                progress = progress < 0.5 and 2 * progress * progress or 1 - math.pow(-2 * progress + 2, 2) / 2

                local newX = currentCamPos.x + (targetCamX - currentCamPos.x) * progress
                local newY = currentCamPos.y + (targetCamY - currentCamPos.y) * progress
                local newZ = currentCamPos.z + (targetCamZ - currentCamPos.z) * progress

                SetCamCoord(cam, newX, newY, newZ)
                PointCamAtCoord(cam, targetLocation.x, targetLocation.y, targetLocation.z + 2.0)

                RequestCollisionAtCoord(newX, newY, newZ)

                Wait(0)
            end

            SetCamCoord(cam, targetCamX, targetCamY, targetCamZ)
            PointCamAtCoord(cam, targetLocation.x, targetLocation.y, targetLocation.z + 2.0)
            SetCamFov(cam, 50.0)
        end)
    end

    Wait(500)
    if cinematicThread then
        cinematicThread = nil
    end

    if currentPed and DoesEntityExist(currentPed) then
        ClearPedTasks(currentPed)
        DeleteEntity(currentPed)
        currentPed = nil
    end

    inCharSelection = false
    lastSelectedCitizenid = nil

    Wait(1500)

    inSpawnSelector = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openSpawnSelector',
        data = {
            locations = Config.SpawnLocations,
            lastLocation = lastLocation
        }
    })

    -- Sadece bir kere fade in yap (en son olarak)
    Wait(100)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('qrp-multicharacter:client:openSpawnSelector', function(lastLocation)
    CloseCharacterSelection()
    Wait(500)
    OpenSpawnSelector(lastLocation)
end)

RegisterNetEvent('qrp-multicharacter:client:characterDeleted', function(characters)
    charData = characters
    SendNUIMessage({
        action = 'openUI',
        data = {
            characters = charData,
            maxCharacters = Config.MaxCharacters
        }
    })
end)

RegisterNetEvent('qrp-multicharacter:client:spawnPlayer', function(citizenid, spawnData)
    CloseCharacterSelection()

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    local coords = spawnData or Config.DefaultSpawn

    Wait(500)

    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    FreezeEntityPosition(ped, false)

    DoScreenFadeIn(500)

    if spawnData and spawnData.isNew and Config.Appearance.openOnCreate then
        Wait(1000)
        if Config.Appearance.script == "qb-clothing" then
            TriggerEvent('qb-clothing:client:openMenu')
        elseif Config.Appearance.script == "illenium-appearance" then
            exports['illenium-appearance']:openUI()
        elseif Config.Appearance.script == "fivem-appearance" then
            exports['fivem-appearance']:startPlayerCustomization()
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if inCharSelection then
        CloseCharacterSelection()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if inCharSelection then
        CloseCharacterSelection()
    end
end)



exports('OpenCharacterSelection', OpenCharacterSelection)
exports('CloseCharacterSelection', CloseCharacterSelection)
