function Initialize()
    CreateThread(function()
        Wait(1000)
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        exports.spawnmanager:setAutoSpawn(false)
        --TransitionToBlurred(500)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
        SetCamRot(cam, 0.0, 0.0, -45.0, 2)
        SetCamCoord(cam, -682.0, -1092.0, 226.0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)

        local player = PlayerId() local ped = PlayerPedId()
        if IsEntityVisible(ped) then SetEntityVisible(ped, false) end
        SetEntityCollision(ped, false)
        FreezeEntityPosition(ped, true)
        SetPlayerInvincible(player, true)
        if not IsPedFatallyInjured(ped) then ClearPedTasksImmediately(ped) end
        SetEntityCoords(ped, vector3(-288.24+math.random(1, 100), -907.95+math.random(1, 100), 676.92+math.random(1, 100)))
        TriggerEvent("echorp:spawnInitialized")
        DoScreenFadeIn(500)
        while IsScreenFadingIn() do Wait(0) end
    end)
end

-- 3
RegisterNetEvent('echorp:spawnPlayer')
AddEventHandler('echorp:spawnPlayer', function(PlayerInfo, kvpCoords, kvpArmour, kvpStress, kvpThirst, kvpHunger)
    PlayerData = PlayerInfo
    if kvpCoords == nil then 
        x, y, z = -206.19, -1013.78, 30.13
    else 
        if string.find(kvpCoords, "vector3") then -- Temporary, remove in a couple of days :P
            x, y, z = -206.19, -1013.78, 30.13
        else
            local coords = json.decode(kvpCoords) 
            x, y, z = coords.x, coords.y, coords.z 
            oldCoords = kvpCoords
        end
    end
    if x == 0 then x, y, z = -206.19, -1013.78, 30.13 end
    --print("Known Spawn x - y - z", x, y, z)
    exports.spawnmanager:spawnPlayer({
        x = x,
        y = y,
        z = z,
        heading = 90.0,
        skipFade = true
    }, function()
        local plyPed = PlayerPedId()
        TriggerServerEvent('clothing:checkIfNew', kvpArmour, kvpStress, kvpThirst, kvpHunger)
        TriggerServerEvent('echorp:playerSpawned', PlayerData)
        TriggerEvent('echorp:playerSpawned', PlayerData)
    end)
end)

-- 1.
CreateThread(function()
	while true do
		Wait(1000)
        if NetworkIsSessionStarted() then
            Initialize()
			return
		end
	end
end)