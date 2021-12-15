local Blips = {}
local SavedKVP = {}

exports('createBlip', function(params)
	local blip = 0
	if params['group'] and params['group'] ~= "" then
		if not Blips[params['group']] then Blips[params['group']] = {} end -- Create the group if it's not been used before.
		
		local displayType = SavedKVP[params['group']]
		if not displayType then
			displayType = GetResourceKvpInt("hidden-blip-"..params['group'])
			if displayType == 0 then
				SetResourceKvpInt("hidden-blip-"..params['group'], 2)
				displayType = 2
			end
			SavedKVP[params['group']] = displayType
		end

		blip = AddBlipForCoord(params['coords'])    
		SetBlipSprite(blip, params['sprite'])
		SetBlipScale(blip, params['scale'] or 0.8)
		SetBlipColour(blip, params['color'] or 0)
		SetBlipDisplay(blip, displayType)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(params['text'])
		EndTextCommandSetBlipName(blip)
		SetBlipAsShortRange(blip, params['scale'] or false)

		Blips[params['group']][#Blips[params['group']]+1] = {blip = blip, resource = params['resource']}
	else
		blip = AddBlipForCoord(params['coords'])    
		SetBlipSprite(blip, params['sprite'])
		SetBlipScale(blip, params['scale'] or 0.8)
		SetBlipColour(blip, params['color'] or 0)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(params['text'])
		EndTextCommandSetBlipName(blip)
		SetBlipAsShortRange(blip, params['scale'] or false)
	end
	return blip
end)

--[[
		exports['echorp']:createBlip({
		resource = GetCurrentResourceName(),
		group = "General",
		coords = prisonCoords,
		sprite = 188,
		scale = 0.8,
		color = 6,
		shortrange = true,
		text = 'Bolingbroke Penitentiary'
	})
]]

exports('getGroups', function()
	local Groups = {}
	for k,v in pairs(Blips) do
		Groups[k] = true
	end
	return Groups
end)

exports('toggleBlipGroup', function(group)
	local new = 0
	if GetResourceKvpInt("hidden-blip-"..group) == 1 then
		SetResourceKvpInt("hidden-blip-"..group, 2)
		new = 2
	else
		SetResourceKvpInt("hidden-blip-"..group, 1)
		new = 1
	end

	SavedKVP[group] = new

	for k,v in pairs(Blips) do
		if k == group then
			for i=1, #Blips[k] do
				SetBlipDisplay(Blips[k][i]['blip'], SavedKVP[group])
			end
		end
	end

	if SavedKVP[group] == 1 then
		exports['erp_notifications']:SendAlert('inform', 'Blips hidden.')
	elseif SavedKVP[group] == 2 then
		exports['erp_notifications']:SendAlert('inform', 'Blips visible.')
	end

	return true
end)

AddEventHandler('onResourceStop', function(resourceName)
  for k,v in pairs(Blips) do
		if v.resource == resourceName then
			RemoveBlip(v.blip)
		end
	end
end)