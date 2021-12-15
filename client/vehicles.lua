RegisterNetEvent('echorp:vehicleSpawned')
AddEventHandler('echorp:vehicleSpawned', function(vehicle, keys, warp)
    local spawnedVehicle = NetworkGetEntityFromNetworkId(vehicle)

    SetEntityAsMissionEntity(spawnedVehicle, true, false)
	SetVehicleHasBeenOwnedByPlayer(spawnedVehicle, true)
	SetVehicleNeedsToBeHotwired(spawnedVehicle, false)

    if spawnedVehicle then
        if keys then TriggerEvent('keys:addNew', spawnedVehicle, GetVehicleNumberPlateText(spawnedVehicle)) end
        if warp then SetPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1) end
    end
end)

AddEventHandler('echorp:getvehicledata', function(vehicle, cb)
    if vehicle == nil or vehicle == 0 then vehicle = GetVehiclePedIsIn(PlayerPedId(), false) end
    if DoesEntityExist(vehicle) then
        local VehicleData = {}
        local WheelNumber = GetVehicleNumberOfWheels(vehicle)

        VehicleData['model'] = GetEntityModel(vehicle)
        VehicleData['plate'] = MathTrim(GetVehicleNumberPlateText(vehicle))
        VehicleData['plateIndex'] = GetVehicleNumberPlateTextIndex(vehicle)

        VehicleData['bodyHealth'] = MathRound(GetVehicleBodyHealth(vehicle), 1)
        VehicleData['engineHealth'] = MathRound(GetVehicleEngineHealth(vehicle), 1)
        VehicleData['petrolHealth'] = MathRound(GetVehiclePetrolTankHealth(vehicle), 1)

        VehicleData['dirtLevel'] = MathRound(GetVehicleDirtLevel(vehicle), 1)
        VehicleData['fuelLevel'] = exports["erp-fuel"]:GetFuel(vehicle)

        VehicleData['color1'], VehicleData['color2'] = GetVehicleColours(vehicle)

        VehicleData['color1Custom'] = {}
        VehicleData['color1Custom'][1], VehicleData['color1Custom'][2], VehicleData['color1Custom'][3] = GetVehicleCustomPrimaryColour(vehicle)
        
        VehicleData['color2Custom'] = {}
        VehicleData['color2Custom'][1], VehicleData['color2Custom'][2], VehicleData['color2Custom'][3] = GetVehicleCustomSecondaryColour(vehicle)

        VehicleData['color1Type'] = GetVehicleModColor_1(vehicle)
        VehicleData['color2Type'] = GetVehicleModColor_2(vehicle)

        VehicleData['pearlescentColor'], VehicleData['wheelColor'] = GetVehicleExtraColours(vehicle)

        VehicleData['livery'] = GetVehicleLivery(vehicle)
        VehicleData['roofLivery'] = GetVehicleRoofLivery(vehicle)

        -- New = 23/02/2021
        VehicleData['interiorColor'] = GetVehicleInteriorColour(vehicle)
        VehicleData['dashColor'] = GetVehicleDashboardColour(vehicle)
        VehicleData['doorStatus'] = {}

        for doorIndex=0, GetNumberOfVehicleDoors(vehicle) do
            local doorNumber = tonumber(doorIndex)
            if IsVehicleDoorDamaged(vehicle, doorNumber) == false then
                VehicleData['doorStatus'][doorNumber] = 0
            else
                VehicleData['doorStatus'][doorNumber] = 1
            end
        end

        VehicleData['FbumperBrokenOff'] = IsVehicleBumperBrokenOff(vehicle, true)
        VehicleData['BbumperBrokenOff'] = IsVehicleBumperBrokenOff(vehicle, false)

        VehicleData['wheels'] = GetVehicleWheelType(vehicle)

        VehicleData['tyreSmokeColor'] = {}
        VehicleData['tyreSmokeColor']['r'], VehicleData['tyreSmokeColor']['g'], VehicleData['tyreSmokeColor']['b'] = GetVehicleTyreSmokeColor(vehicle)

        VehicleData['windowTint'] = GetVehicleWindowTint(vehicle)
        VehicleData['xenonColor'] = GetVehicleXenonLightsColour(vehicle)

        VehicleData['neonsEnabled'] = { [1] = IsVehicleNeonLightEnabled(vehicle, 0), [2] = IsVehicleNeonLightEnabled(vehicle, 1), [3] = IsVehicleNeonLightEnabled(vehicle, 2), [4] = IsVehicleNeonLightEnabled(vehicle, 3) }

        VehicleData['neonColor'] = {}
        VehicleData['neonColor']['r'], VehicleData['neonColor']['g'], VehicleData['neonColor']['b'] = GetVehicleNeonLightsColour(vehicle)

        VehicleData['extras'] = {}
        VehicleData['WheelInfo'] = {}

        for wheel=0, WheelNumber do
            VehicleData['WheelInfo'][wheel] = {
                health = GetVehicleWheelHealth(vehicle, wheel),
                burst = IsVehicleTyreBurst(vehicle, wheel, false)
            }
            print(json.encode(VehicleData['WheelInfo']))
        end

        for extraId=0, 20 do
			if DoesExtraExist(vehicle, extraId) then
				local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
				VehicleData['extras'][tostring(extraId)] = state
			end
		end

        VehicleData['modSpoilers'] = GetVehicleMod(vehicle, 0)
		VehicleData['modFrontBumper'] = GetVehicleMod(vehicle, 1)
		VehicleData['modRearBumper'] = GetVehicleMod(vehicle, 2)
		VehicleData['modSideSkirt'] = GetVehicleMod(vehicle, 3)
		VehicleData['modExhaust'] = GetVehicleMod(vehicle, 4)
		VehicleData['modFrame'] = GetVehicleMod(vehicle, 5)
		VehicleData['modGrille'] = GetVehicleMod(vehicle, 6)
		VehicleData['modHood'] = GetVehicleMod(vehicle, 7)
		VehicleData['modFender'] = GetVehicleMod(vehicle, 8)
		VehicleData['modRightFender'] = GetVehicleMod(vehicle, 9)
		VehicleData['modRoof'] = GetVehicleMod(vehicle, 10)

		VehicleData['modEngine'] = GetVehicleMod(vehicle, 11)
		VehicleData['modBrakes'] = GetVehicleMod(vehicle, 12)
		VehicleData['modTransmission'] = GetVehicleMod(vehicle, 13)
		VehicleData['modHorns'] = GetVehicleMod(vehicle, 14)
		VehicleData['modSuspension'] = GetVehicleMod(vehicle, 15)
		VehicleData['modArmor'] = GetVehicleMod(vehicle, 16)

        VehicleData['modLivery'] = GetVehicleMod(vehicle, 48)

		VehicleData['modTurbo'] = IsToggleModOn(vehicle, 18)
		VehicleData['modSmokeEnabled'] = IsToggleModOn(vehicle, 20)
		VehicleData['modXenon'] = IsToggleModOn(vehicle, 22)

		VehicleData['modFrontWheels'] = GetVehicleMod(vehicle, 23)
        VehicleData['modBackWheels'] = GetVehicleMod(vehicle, 24)

		VehicleData['modPlateHolder'] = GetVehicleMod(vehicle, 25)
		VehicleData['modVanityPlate'] = GetVehicleMod(vehicle, 26)
		VehicleData['modTrimA'] = GetVehicleMod(vehicle, 27)
		VehicleData['modOrnaments'] = GetVehicleMod(vehicle, 28)
		VehicleData['modDashboard'] = GetVehicleMod(vehicle, 29)
		VehicleData['modDial'] = GetVehicleMod(vehicle, 30)
		VehicleData['modDoorSpeaker'] = GetVehicleMod(vehicle, 31)
		VehicleData['modSeats'] = GetVehicleMod(vehicle, 32)
		VehicleData['modSteeringWheel']  = GetVehicleMod(vehicle, 33)
		VehicleData['modShifterLeavers'] = GetVehicleMod(vehicle, 34)
		VehicleData['modAPlate'] = GetVehicleMod(vehicle, 35)
		VehicleData['modSpeakers'] = GetVehicleMod(vehicle, 36)
		VehicleData['modTrunk'] = GetVehicleMod(vehicle, 37)
		VehicleData['modHydrolic'] = GetVehicleMod(vehicle, 38)
		VehicleData['modEngineBlock'] = GetVehicleMod(vehicle, 39)
		VehicleData['modAirFilter'] = GetVehicleMod(vehicle, 40)
		VehicleData['modStruts'] = GetVehicleMod(vehicle, 41)
		VehicleData['modArchCover'] = GetVehicleMod(vehicle, 42)
		VehicleData['modAerials'] = GetVehicleMod(vehicle, 43)
		VehicleData['modTrimB'] = GetVehicleMod(vehicle, 44)
		VehicleData['modTank'] = GetVehicleMod(vehicle, 45)
        VehicleData['modWindows'] = GetVehicleMod(vehicle, 46)
        
        cb(VehicleData)
    else
        cb({})
    end
end)

AddEventHandler('echorp:SetVehicleData', function(vehicle, VehicleData, forceFuel, cb)
    if type(VehicleData) == 'string' then VehicleData = json.decode(VehicleData) end
    if vehicle == nil or vehicle == 0 then vehicle = GetVehiclePedIsIn(PlayerPedId(), false) end
    if DoesEntityExist(vehicle) then
        --if GetEntityModel(vehicle) == VehicleData['model'] then 
            local WheelNumber = GetVehicleNumberOfWheels(vehicle)
            SetVehicleModKit(vehicle, 0)
            if VehicleData['plate'] then SetVehicleNumberPlateText(vehicle, VehicleData['plate']) end
            if VehicleData['plateIndex'] then SetVehicleNumberPlateTextIndex(vehicle, VehicleData['plateIndex']) end
            if VehicleData['bodyHealth'] then SetVehicleBodyHealth(vehicle, VehicleData['bodyHealth']) end
            if VehicleData['engineHealth'] then SetVehicleEngineHealth(vehicle, VehicleData['engineHealth']) end
            if VehicleData['petrolHealth'] then SetVehiclePetrolTankHealth(vehicle, VehicleData['petrolHealth']) end
            if VehicleData['dirtLevel'] then SetVehicleDirtLevel(vehicle, VehicleData['dirtLevel']) end
            if type(forceFuel) == 'boolean' then if VehicleData['fuelLevel'] then exports["erp-fuel"]:SetFuel(vehicle, VehicleData['fuelLevel']) end
            else exports["erp-fuel"]:SetFuel(vehicle, forceFuel) end

            if VehicleData['color1'] or VehicleData['color2'] then
                
                if VehicleData['color1'] and VehicleData['color2'] then 
                    ClearVehicleCustomPrimaryColour(vehicle)
                    ClearVehicleCustomSecondaryColour(vehicle)
                    SetVehicleColours(vehicle, VehicleData['color1'], VehicleData['color2'])
                elseif VehicleData['color2'] then 
                    ClearVehicleCustomSecondaryColour(vehicle)
                    SetVehicleColours(vehicle, 0, VehicleData['color2'])
                elseif VehicleData['color1'] then 
                    ClearVehicleCustomPrimaryColour(vehicle)
                    SetVehicleColours(vehicle, VehicleData['color1'], 0) 
                end
            end

            if VehicleData['color1Custom'] then
                SetVehicleCustomPrimaryColour(vehicle, VehicleData['color1Custom'][1], VehicleData['color1Custom'][2], VehicleData['color1Custom'][3])
            end

            if VehicleData['color2Custom'] then
                SetVehicleCustomSecondaryColour(vehicle, VehicleData['color2Custom'][1], VehicleData['color2Custom'][2], VehicleData['color2Custom'][3])
            end

            
            if (VehicleData.color1Type) then
                SetVehicleModColor_1(vehicle, VehicleData.color1Type)
            end

            if (VehicleData.color2Type) then
                SetVehicleModColor_2(vehicle, VehicleData.color2Type)
            end

            if VehicleData['pearlescentColor'] or VehicleData['wheelColor'] then
                if VehicleData['pearlescentColor'] and VehicleData['wheelColor'] then 
                    SetVehicleExtraColours(vehicle, VehicleData['pearlescentColor'], VehicleData['wheelColor'])
                elseif VehicleData['wheelColor'] then 
                    SetVehicleExtraColours(vehicle, 0, VehicleData['wheelColor'])
                elseif VehicleData['pearlescentColor'] then 
                    SetVehicleExtraColours(vehicle, VehicleData['pearlescentColor'], 0) 
                end
            end

            if VehicleData['xenonColor'] then SetVehicleXenonLightsColour(vehicle, VehicleData['xenonColor']) end
            if VehicleData['wheels'] then SetVehicleWheelType(vehicle, VehicleData['wheels']) end
            if VehicleData['tyreSmokeColor'] then SetVehicleTyreSmokeColor(vehicle, VehicleData['tyreSmokeColor']['r'], VehicleData['tyreSmokeColor']['g'], VehicleData['tyreSmokeColor']['b']) end
            if VehicleData['windowTint'] then SetVehicleWindowTint(vehicle, VehicleData['windowTint'])  end
            if VehicleData['neonsEnabled'] then for i=1, #VehicleData['neonsEnabled'] do local new = i - 1 SetVehicleNeonLightEnabled(vehicle, new, VehicleData['neonsEnabled'][i]) end end
            if VehicleData['neonColor'] then SetVehicleNeonLightsColour(vehicle, VehicleData['neonColor']['r'], VehicleData['neonColor']['g'], VehicleData['neonColor']['b']) end

            if VehicleData['extras'] then
                for extraId, toggle in pairs(VehicleData['extras']) do
                    if toggle then SetVehicleExtra(vehicle, tonumber(extraId), 0)
                    else SetVehicleExtra(vehicle, tonumber(extraId), 1) end
                end
            end

            if VehicleData['modSpoilers'] then SetVehicleMod(vehicle, 0, VehicleData['modSpoilers'], false) end
            if VehicleData['modFrontBumper'] then SetVehicleMod(vehicle, 1, VehicleData['modFrontBumper'], false) end
            if VehicleData['modRearBumper'] then SetVehicleMod(vehicle, 2, VehicleData['modRearBumper'], false) end
            if VehicleData['modSideSkirt'] then SetVehicleMod(vehicle, 3, VehicleData['modSideSkirt'], false) end
            if VehicleData['modExhaust'] then SetVehicleMod(vehicle, 4, VehicleData['modExhaust'], false) end
            if VehicleData['modFrame'] then SetVehicleMod(vehicle, 5, VehicleData['modFrame'], false) end
            if VehicleData['modGrille'] then SetVehicleMod(vehicle, 6, VehicleData['modGrille'], false) end
            if VehicleData['modHood'] then SetVehicleMod(vehicle, 7, VehicleData['modHood'], false) end
            if VehicleData['modFender'] then SetVehicleMod(vehicle, 8, VehicleData['modFender'], false) end
            if VehicleData['modRightFender'] then SetVehicleMod(vehicle, 9, VehicleData['modRightFender'], false) end
            if VehicleData['modRoof'] then SetVehicleMod(vehicle, 10, VehicleData['modRoof'], false) end
            if VehicleData['modEngine'] then SetVehicleMod(vehicle, 11, VehicleData['modEngine'], false) end
            if VehicleData['modBrakes'] then SetVehicleMod(vehicle, 12, VehicleData['modBrakes'], false) end
            if VehicleData['modTransmission'] then SetVehicleMod(vehicle, 13, VehicleData['modTransmission'], false) end
            if VehicleData['modHorns'] then SetVehicleMod(vehicle, 14, VehicleData['modHorns'], false) end
            if VehicleData['modSuspension'] then SetVehicleMod(vehicle, 15, VehicleData['modSuspension'], false) end
            if VehicleData['modArmor'] then SetVehicleMod(vehicle, 16, VehicleData['modArmor'], false) end
            if VehicleData['modTurbo'] then ToggleVehicleMod(vehicle, 18, VehicleData['modTurbo']) end
            if VehicleData['modSmokeEnabled'] then ToggleVehicleMod(vehicle, 20, VehicleData['modSmokeEnabled']) end
            if VehicleData['modXenon'] then ToggleVehicleMod(vehicle, 22, VehicleData['modXenon']) end
            if VehicleData['modFrontWheels'] then SetVehicleMod(vehicle, 23, VehicleData['modFrontWheels'], false) end
            if VehicleData['modBackWheels'] then SetVehicleMod(vehicle, 24, VehicleData['modBackWheels'], false) end
            if VehicleData['modPlateHolder'] then SetVehicleMod(vehicle, 25, VehicleData['modPlateHolder'], false) end
            if VehicleData['modVanityPlate'] then SetVehicleMod(vehicle, 26, VehicleData['modVanityPlate'], false) end
            if VehicleData['modTrimA'] then SetVehicleMod(vehicle, 27, VehicleData['modTrimA'], false) end
            if VehicleData['modTrimB'] then SetVehicleMod(vehicle, 44, VehicleData['modTrimB'], false) end
            if VehicleData['modOrnaments'] then SetVehicleMod(vehicle, 28, VehicleData['modOrnaments'], false) end
            if VehicleData['modDashboard'] then SetVehicleMod(vehicle, 29, VehicleData['modDashboard'], false) end
            if VehicleData['modDial'] then SetVehicleMod(vehicle, 30, VehicleData['modDial'], false) end
            if VehicleData['modDoorSpeaker'] then SetVehicleMod(vehicle, 31, VehicleData['modDoorSpeaker'], false) end
            if VehicleData['modSeats'] then SetVehicleMod(vehicle, 32, VehicleData['modSeats'], false) end
            if VehicleData['modSteeringWheel'] then SetVehicleMod(vehicle, 33, VehicleData['modSteeringWheel'], false) end
            if VehicleData['modShifterLeavers'] then SetVehicleMod(vehicle, 34, VehicleData['modShifterLeavers'], false) end
            if VehicleData['modAPlate'] then SetVehicleMod(vehicle, 35, VehicleData['modAPlate'], false) end
            if VehicleData['modSpeakers'] then SetVehicleMod(vehicle, 36, VehicleData['modSpeakers'], false) end
            if VehicleData['modTrunk'] then SetVehicleMod(vehicle, 37, VehicleData['modTrunk'], false) end
            if VehicleData['modHydrolic'] then SetVehicleMod(vehicle, 38, VehicleData['modHydrolic'], false) end
            if VehicleData['modEngineBlock'] then SetVehicleMod(vehicle, 39, VehicleData['modEngineBlock'], false) end
            if VehicleData['modAirFilter'] then SetVehicleMod(vehicle, 40, VehicleData['modAirFilter'], false) end
            if VehicleData['modStruts'] then SetVehicleMod(vehicle, 41, VehicleData['modStruts'], false) end
            if VehicleData['modArchCover'] then SetVehicleMod(vehicle, 42, VehicleData['modArchCover'], false) end
            if VehicleData['modAerials'] then SetVehicleMod(vehicle, 43, VehicleData['modAerials'], false) end
            if VehicleData['modTank'] then SetVehicleMod(vehicle, 45, VehicleData['modTank'], false) end
            if VehicleData['modWindows'] then SetVehicleMod(vehicle, 46, VehicleData['modWindows'], false) end

            if VehicleData['modLivery'] then 
                SetVehicleMod(vehicle, 48, VehicleData['modLivery'], false)  
            end

            if VehicleData['livery'] then
                SetVehicleLivery(vehicle, VehicleData['livery'])
            end

            if VehicleData['roofLivery'] then 
                SetVehicleRoofLivery(vehicle, VehicleData['roofLivery']) 
            end

            if VehicleData['interiorColor'] then SetVehicleInteriorColour(vehicle, VehicleData['interiorColor']) end
            if VehicleData['dashColor'] then SetVehicleDashboardColour(vehicle, VehicleData['dashColor']) end

            if VehicleData['doorStatus'] then
                for door, status in pairs(VehicleData['doorStatus']) do
                    if status == 1 then
                        SetVehicleDoorBroken(vehicle, tonumber(door), true)
                    end
                end
            end

            if VehicleData['FbumperBrokenOff'] then SetVehicleDoorBroken(vehicle, 4, true) end
            if VehicleData['BbumperBrokenOff'] then SetVehicleDoorBroken(vehicle, 5, true) end

            if VehicleData['WheelInfo'] then 
                for wheel=0, WheelNumber do
                    local wheelNum = tostring(wheel)
                    if VehicleData['WheelInfo'][wheelNum] then
                        if VehicleData['WheelInfo'][wheelNum]['health'] then
                            SetVehicleWheelHealth(vehicle, wheel, VehicleData['WheelInfo'][wheelNum]['health'])
                        end
                        if VehicleData['WheelInfo'][wheelNum]['burst'] == 1 then
                            print("Bursting tyre:", wheelNum)
                            SetVehicleTyreBurst(vehicle, wheel, true, 10000.0)
                        end
                    end
                end 
            end
            --if VehicleData['windowStatus'] then for i=1, 8 do if not VehicleData['windowStatus'][i] then SmashVehicleWindow(vehicle, i) end end end    

            cb(true)
        --end
    else
        cb(false)
    end
end)