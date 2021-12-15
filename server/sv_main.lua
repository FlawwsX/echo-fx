local players = {}
local playersCid = {}
--local shifts = {}

local whitelistedNames = {
	['iyruk'] = true,
	['Flawws'] = true
}

local policeJobs = {
	['lspd'] = true,
	['bcso'] = true,
	['sast'] = true,
	['sasp'] = true,
	['doc'] = true,
	['sapr'] = true,
	['pa'] = true
}

-- Functions & Callbacks

local function getIdentifier(plyId)
	if players[plyId] then return players[plyId]['identifier'] end;
	local numIdentifiers = GetNumPlayerIdentifiers(plyId)	
	for i=0, numIdentifiers -1 do
		local currIdentifier = GetPlayerIdentifier(plyId, i)
		if string.find(currIdentifier, "fivem:") then
			return currIdentifier
		end
	end
	return nil
end

AddEventHandler('echorp:getplayerfromid', function(playerId, cb)
	cb(players[tonumber(playerId)])
end)

AddEventHandler('echorp:getplayerfromcid', function(cid, cb)
	cb(players[playersCid[tonumber(cid)]])
end)

local function GetPlayerFromId(playerId) -- exports['echorp']:GetPlayerFromId(playerId)
	local plyId = tonumber(playerId)
	return players[plyId]
end

local function GetOnePlayerInfo(playerId, infoWanted) -- exports['echorp']:GetOnePlayerInfo(playerId, 'cid')
	local playerData = players[playerId]
	if playerData then 
		return playerData[infoWanted] 
	end 
	return nil
end

local function GetPlayerFromCid(cid) -- exports['echorp']:GetPlayerFromCid(cid)
	local cid = tonumber(cid)
	local plyFromCid = playersCid[cid]
	if plyFromCid then
		return players[plyFromCid]
	end
	return nil
end

local function GetPlayerFromPhone(phonenumber) -- exports['echorp']:GetPlayerFromPhone(phonenumber)
	local sentNumber = tostring(phonenumber)
	for k,v in pairs(players) do
		if v.phone_number == sentNumber then
			return v
		end
	end
	return nil
end

local function DoesCidExist(cid) -- exports['echorp']:DoesCidExist(cid)
	local cid = tonumber(cid)
	local p = promise.new()
	exports.oxmysql:execute("SELECT 1 FROM users WHERE `id`=:id LIMIT 1", {id = cid}, function(data) p:resolve(#data > 0) end)
	return Citizen.Await(p)
end

local function SetPlayerData(source, toChange, targetData)
	players[tonumber(source)][toChange] = targetData
	TriggerClientEvent('echorp:updateinfo', source, toChange, targetData)
end

local function GetFXPlayers() return players end -- exports['echorp']:GetFXPlayers()

exports("GetPlayerFromId", GetPlayerFromId)
exports("GetOnePlayerInfo", GetOnePlayerInfo)
exports("GetPlayerFromCid", GetPlayerFromCid)
exports("GetFXPlayers", GetFXPlayers)
exports('identifier', getIdentifier)
exports('getIdentifier', getIdentifier)
exports('SetPlayerData', SetPlayerData)
exports('DoesCidExist', DoesCidExist)
exports('GetPlayerFromPhone', GetPlayerFromPhone)

-- Character selector events

local function steamIdentifier(plyId)
	local numIdentifiers = GetNumPlayerIdentifiers(plyId)	
	for i=0, numIdentifiers -1 do
		local currIdentifier = GetPlayerIdentifier(plyId, i)
		if currIdentifier then
			if string.find(currIdentifier, "steam:") then
				return currIdentifier
			end
		end
	end
	return nil
end

RegisterNetEvent('echorp:fetchcharacters')
AddEventHandler('echorp:fetchcharacters', function()
	local source = source
	local characters = {}
	local identifier = getIdentifier(source)
	if identifier == nil then DropPlayer(source, 'Missing FiveM identifier') end

	local steamIdent = steamIdentifier(source)
	if steamIdent then
		exports.oxmysql:executeSync("UPDATE users SET identifier=:fivemidentifier WHERE identifier=:steamidentifier", { fivemidentifier = identifier, steamidentifier = steamIdent })
	end
	
	local knownCharacters = exports.oxmysql:executeSync("SELECT id, cash, bank, firstname, lastname, dateofbirth, gender FROM users WHERE identifier=:identifier AND deleted='0'", { identifier = identifier })
	for i=1, #knownCharacters do
		local info = knownCharacters[i]
		local cid = knownCharacters[i]['id']
		local character = { info = info, cPed = {} }
		local Skin = exports.oxmysql:executeSync("SELECT model, drawables, props, drawtextures, proptextures FROM character_current WHERE cid = :cid LIMIT 1", { cid = cid })
		if Skin and Skin[1] then
			character['cPed'] = {
				model = Skin[1].model,
				drawables = json.decode(Skin[1].drawables),
				props = json.decode(Skin[1].props),
				drawtextures = json.decode(Skin[1].drawtextures),
				proptextures = json.decode(Skin[1].proptextures),
				tattoos = {}
			}
		end

		local Face = exports.oxmysql:executeSync("SELECT hairColor, headBlend, headOverlay, headStructure FROM character_face WHERE cid = :cid LIMIT 1", {cid = cid})
		if Face and Face[1] then
			character['cPed']['hairColor'] = json.decode(Face[1].hairColor)
			character['cPed']['headBlend'] = json.decode(Face[1].headBlend)
			character['cPed']['headOverlay'] = json.decode(Face[1].headOverlay)
			character['cPed']['headStructure'] = json.decode(Face[1].headStructure)
		end

		local Tats = exports.oxmysql:executeSync("SELECT tattoos FROM playersTattoos WHERE cid = :cid LIMIT 1", {cid = cid})
		if Tats and Tats[1] and Tats[1]['tattoos'] then
			character['cPed']['tattoos'] = json.decode(Tats[1].tattoos)
		end

		characters[i] = character
	end

	TriggerClientEvent('fetchCharacters', source, characters)
end)

RegisterNetEvent('echorp:deleteCharacter')
AddEventHandler('echorp:deleteCharacter', function(cid)
	local source = source
	exports.oxmysql:execute("SELECT `identifier` FROM `users` WHERE id=:id LIMIT 1", {
		id = cid,
	}, function(data)
		if data and data[1] then
			local identifier = getIdentifier(source)
			if data[1]['identifier'] == identifier then
				exports.oxmysql:executeSync("UPDATE `users` SET `deleted`='1' WHERE id=:id", { id = cid })
			end
		end
	end)
end)

RegisterNetEvent('echorp:selectCharacter')
AddEventHandler('echorp:selectCharacter', function(cid) 
  local playerId, cid = tonumber(source), tonumber(cid)
  if players[playerId] or playersCid[cid] then
    if not names[GetPlayerName(playerId)] then
      DropPlayer(playerId, 'You already appear to be loaded on our Framework\nDropping you as a caution measure.') 
    	return 
    end
	end

	local identifier = getIdentifier(playerId)
	if identifier then
		exports.oxmysql:execute('SELECT `cash`, `bank`, `job`, `job_grade`, `duty`, `firstname`, `lastname`, `gender`, `phone_number`, `jail_time`, `twitterhandle` FROM `users` WHERE `id`=:id LIMIT 1', { id = cid }, function(charInfo)
			if charInfo then
				local dbInfo = charInfo[1]
				local isPolice = policeJobs[dbInfo.job] or false
				local PlayerInfo = {
					source = playerId,
					identifier = identifier,
					cid = cid,
					id = cid,
					cash = tonumber(dbInfo.cash),
					bank = tonumber(dbInfo.bank),
					job = { name = dbInfo.job, grade = dbInfo.job_grade, duty = tonumber(dbInfo.duty), isPolice = isPolice },
					sidejob = { name = "none", label = "None" },
					isPolice = isPolice,
					firstname = dbInfo['firstname'],
					lastname = dbInfo['lastname'],
					fullname = dbInfo['firstname']..' '..dbInfo['lastname'],
					gender = dbInfo['gender'],
					phone_number = dbInfo['phone_number'],
					jail_time = dbInfo['jail_time'],
					twitterhandle = dbInfo['twitterhandle'],
				}
				players[playerId] = PlayerInfo
				playersCid[cid] = playerId

				local thirst = GetResourceKvpInt(cid.."-thirst")
				if thirst == 0 or thirst == nil then thirst = 5000 end

				local hunger = GetResourceKvpInt(cid.."-hunger")
				if hunger == 0 or hunger == nil then hunger = 5000 end

				TriggerClientEvent('echorp:spawnPlayer', playerId, PlayerInfo, GetResourceKvpString(cid.."-coords"), GetResourceKvpInt(cid.."-armour"), GetResourceKvpInt(cid.."-stress"), thirst, hunger)

				local message = "Player: **"..GetPlayerName(PlayerInfo['source']).."** (**"..PlayerInfo['source'].."**)\nCharacter: **"..PlayerInfo['fullname']..' ['..PlayerInfo['cid']..']'.."**\nIdentifier: **"..PlayerInfo['identifier'].."**\nCash: `$"..PlayerInfo['cash'].."` · Bank: `$"..PlayerInfo['bank'].."` · Job: `"..PlayerInfo['job']['name'].."` | `"..PlayerInfo['job']['grade'].."`"
				exports['erp_adminmenu']:sendToDiscord('Player Logging In', message, "8598763", GetConvar('gamelogs_webhook', ''))
				if isPolice or PlayerInfo.job.name == 'ambulance' then TriggerEvent('echorp:notifyDuty',PlayerInfo,'join') end
			end
		end)
	end
end)

RegisterNetEvent('echorp:createCharacter')
AddEventHandler('echorp:createCharacter', function(charInfo) 
	local playerId = source
	local identifier = getIdentifier(playerId)
	if identifier then
		exports.oxmysql:insertSync("INSERT INTO `users` (`identifier`, `firstname`, `lastname`, `dateofbirth`, `gender`) VALUES (:identifier, :firstname, :lastname, :dateofbirth, :gender)", {
			identifier = identifier,
			firstname = charInfo.firstname,
			lastname = charInfo.lastname,
			dateofbirth = charInfo.dob,
			gender = charInfo.gender
		})
	end
end)

RegisterNetEvent('echorp:logout')
AddEventHandler('echorp:logout', function()
  local playerId = source
	local player = players[playerId]
	if player then
		players[playerId], playersCid[player.cid] = nil, nil
		TriggerClientEvent('echorp:doLogout', playerId, player)
		TriggerEvent('echorp:doLogout', player)
		local message = "Player: **"..GetPlayerName(playerId).."** (**"..playerId.."**)\nCharacter: **"..player['fullname']..' ['..player['cid']..']'.."**\nIdentifier: **"..player['identifier'].."**\nCash: `$"..player['cash'].."` · Bank: `$"..player['bank'].."` · Job: `"..player['job']['name'].."` | `"..player['job']['grade'].."`"
		exports['erp_adminmenu']:sendToDiscord('Player Logging Off', message, "16758838", GetConvar('gamelogs_webhook', ''))
	end
end)

-- Misc. Events

RegisterNetEvent('deletevehicle:server')
AddEventHandler('deletevehicle:server', function(vehicleNet)
	if vehicleNet then
		local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
		if DoesEntityExist(vehicle) then
			DeleteEntity(vehicle)
		end 
	end
end)

AddEventHandler('playerDropped', function(reason)
	local source = source
	local playerData = players[source]
	if playerData then 
		TriggerEvent('echorp:playerDropped', playerData) 
		players[source] = nil
		playersCid[playerData.cid] = nil
	end
end)

-- Threads

CreateThread(function()
	while true do
		for k, player in pairs(players) do
			Wait(100)
			if players[player['source']] then
				local source, cid = player['source'], player['cid']
				local plyPed = GetPlayerPed(source)
				local plyPos, armour = GetEntityCoords(plyPed), GetPedArmour(plyPed)
				local statePlayer = Player(source)
				SetResourceKvpNoSync(cid..'-coords', json.encode(plyPos))
				SetResourceKvpIntNoSync(cid..'-armour', armour)
				SetResourceKvpIntNoSync(cid..'-stress', statePlayer.state.stressLevel)
				SetResourceKvpIntNoSync(cid..'-thirst', statePlayer.state.thirstLevel)
				SetResourceKvpIntNoSync(cid..'-hunger', statePlayer.state.hungerLevel)
			end
		end
		FlushResourceKvp()
		Wait(15000)
	end
end)

-- Commands

RegisterCommand("logout", function(source, args, rawCommand) TriggerClientEvent('resetfromfx', source) end, false)


RegisterCommand("copycoords", function(source, args, rawCommand)
    local type = args[1]
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)

    if type == 'vector4' then
        local heading = GetEntityHeading(ped)
        printOUT = "vector4("..tonumber(string.format("%.2f", coords["x"]))..", "..tonumber(string.format("%.2f", coords["y"]))..", "..tonumber(string.format("%.2f", coords["z"]))..", "..tonumber(string.format("%.2f", heading))..")"
        TriggerEvent('erp_adminmenu:discord', 'Coords From: '..GetPlayerName(source), printOUT, '14047329', "WEBHOOK")
    else
        printOUT = "vector3("..tonumber(string.format("%.2f", coords["x"]))..", "..tonumber(string.format("%.2f", coords["y"]))..", "..tonumber(string.format("%.2f", coords["z"]))..")"
        TriggerEvent('erp_adminmenu:discord', 'Coords From: '..GetPlayerName(source), printOUT, '3252448', "WEBHOOK")
    end
end, false)

RegisterCommand("addbank", function(source, args, rawCommand)
    
	local function Notify(msg)
			if source == 0 then print(msg)
			elseif GetPlayerName(source) then TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = msg, length = 5000 }) end 
	end

	local function DiscordLog(title, msg)
			TriggerEvent('erp_adminmenu:discord', title, msg, '6003445', GetConvar('adminlogs_webhook', ''))
	end

	if source > 0 then
		if not IsPlayerAceAllowed(source, 'echorp.seniormod') then
				TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = 'Invalid permissions.', length = 5000 }) return
		end
	end
	
	local cid, amount = args[1], tonumber(args[2])
	if cid then
			if amount and amount > 0 then
					local target = GetPlayerFromCid(cid)
					if target then
							TriggerEvent('AddBank', cid, amount, true, false, false, function(res)
									if res then 
											Notify('Yay! We just gave someone $'..amount)
											if source ~= 0 then
												DiscordLog('Add bank command', GetPlayerName(source)..' added $'..amount..' to '..cid..'\'s bank!')
											end
									else 
											Notify('Uh oh... failed to give $'..amount) 
									end
							end)
					else
							TriggerEvent('AddBankOffline', cid, amount) 
							Notify('Yay! We just gave someone who is offline $'..amount) 
							if source ~= 0 then
								DiscordLog('Add bank command', GetPlayerName(source)..' added $'..amount..' to '..cid..'\'s bank!') 
							end
					end
			else Notify('You failed to specify an amount greater than $0') end
	else Notify('Please specify a CID, such as 1998') end
end, false)

local TokenTypes = {
	['Ringtone'] = true,
	['Number'] = true,
	['Plate'] = true,
	['Handle'] = true
}

RegisterCommand("addtoken", function(source, args, rawCommand)
	local type = args[1]
	local discord = args[2]

	if type then
			if TokenTypes[type] then
					if discord then
							exports.oxmysql:executeSync('INSERT INTO `donatorperks` (`type`, `discord`) VALUES (:type, :discord);', { type = type, discord = discord })
							TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = "Donator perk added.", length = 5000 })
					else
							TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = "You did not provide a discord ID", length = 5000 })
					end
			else
					TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = "Invalid token type - Try ringtone, number, plate or handle.", length = 5000 })
			end
	else
			TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = "You failed to provide a token type - Try ringtone, number, plate or handle.", length = 5000 })
	end
end, true)

-- Paychecks

local function NewPaycheck(cid, amount, type, source)
	if cid and amount then
			exports.oxmysql:executeSync('UPDATE `users` SET paycheck = paycheck + :amount WHERE id=:id', { amount = amount, id = cid })
			if type == 1 then
					TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = 'Your universal basic income check is ready to collect from the Lifeinvader building', length = 7500 } )
			elseif type == 2 then
					TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = 'Your paycheck is ready to collect from the Lifeinvader building', length = 7500 } )
			end
	end
end

local NoTaxJobs = {
	['lspd'] = true,
	['bcso'] = true,
	['sast'] = true,
	['sasp'] = true,
	['doc'] = true,
	['sapr'] = true,
	['pa'] = true,
	['ambulance'] = true,
	['cmmc'] = true,
	['doj'] = true,
	['legacyrecords'] = true,
}

local Guaranteed = {
	['lspd'] = true,
	['bcso'] = true,
	['sast'] = true,
	['sasp'] = true,
	['doc'] = true,
	['sapr'] = true,
	['legacyrecords'] = true,
	['pa'] = true,
	['ambulance'] = true,
	['weazelnews'] = true
}

local function Paychecks()
	local walfareCheck = math.random(50, 75)
	for k,v in pairs(players) do
			Wait(100)
			if v.job then
					local source, cid, job, grade, duty = v.source, v.cid, v.job.name, v.job.grade, v.job.duty
					NewPaycheck(cid, walfareCheck, 1, source)
					if duty == 1 then
							if Jobs[job] then
									local gradeInfo = Jobs[job]['grades'][grade]
									if gradeInfo then
											local pay = tonumber(gradeInfo['moneys'])
											if Jobs[job]['business'] then
													if Guaranteed[job] then
															NewPaycheck(cid, pay, 2, source)
													else
															TriggerEvent('erp_phone:GetMoney', job, function(res)
																	if res then
																			if res >= pay then
																					exports.oxmysql:executeSync("UPDATE businesses SET funds = funds-:pay WHERE name=:name", {pay = pay, name = job})
																					NewPaycheck(cid, pay, 2, source)
																			else
																					TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'inform', text = 'Your current employee does not have enough funds to pay you this week.', length = 7500 })
																			end
																	end
															end)
													end
											else
													NewPaycheck(cid, pay, 2, source)
											end
									end
							end
					end
			end
	end
	Citizen.SetTimeout(math.random(1350000, 2250000), function() Paychecks() end) -- 30 mins.
end

Citizen.SetTimeout(math.random(1350000, 2250000), function() Paychecks() end) -- 5 mins.

RegisterNetEvent('echorp:collectpaycheck')
AddEventHandler('echorp:collectpaycheck', function()
    TriggerEvent('echorp:getplayerfromid', source, function(player)
        if player then
            exports.oxmysql:execute("SELECT paycheck FROM users WHERE id=:id LIMIT 1", {
                id = player.cid
            }, function(res)
                if res and res[1] then
                    if res[1]['paycheck'] > 0 then
                        local shouldTax = true
                        if NoTaxJobs[player.job.name] then shouldTax = false end
                        TriggerEvent('AddBank', player['cid'], res[1]['paycheck'], true, shouldTax, false, function(x)
                            TriggerClientEvent('erp_notifications:client:SendAlert', player['source'], { type = 'inform', text = 'Paycheck Collected.', length = 5000 })
                        end)
                    else
                        TriggerClientEvent('erp_notifications:client:SendAlert', player['source'], { type = 'inform', text = 'You have nothing to collect.', length = 5000 })
                    end
                    exports.oxmysql:executeSync('UPDATE `users` SET paycheck = 0 WHERE id=:id', { id = player['cid'] })
                end
            end)
        end
    end)
end)

-- Crazy Job stuff

RegisterNetEvent('echorp:updatejob')
AddEventHandler('echorp:updatejob', function(type, job, grade, cid, src)
    local src = src or source
    local grade = tonumber(grade)
    if grade == nil or grade == 0 then grade = 1 end
    local valid = exports['echorp']:DoesCidExist(cid)
    if valid then
        local player = exports['echorp']:GetPlayerFromCid(cid)
        if player then
            if Jobs[job] then
                if Jobs[job]['grades'][grade] then
                    if type == "set" then
                        local isPolice = false
                        if policeJobs[job] then isPolice = true end;
                        SetPlayerData(player.source, 'job', {name = job, grade = grade, duty = 1, isPolice = isPolice})
                        exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = job, job_grade = grade, cid = player.cid})
                        if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'Job Temporarly Set', length = 5000 }) end
                   
                    elseif type == "add" then
                        exports.oxmysql:execute("SELECT * FROM user_jobs WHERE cid=:cid AND job=:job", {
                            cid = player.cid,
                            job = job
                        }, function(jobs)
                            if #jobs > 0 then
                                exports.oxmysql:executeSync("UPDATE user_jobs SET job_grade=:job_grade WHERE cid=:cid AND job=:job", {job = job, job_grade = grade, cid = player.cid})
                                if player.job.name == job then SetPlayerData(player.source, 'job', {name = job, grade = grade, duty = 1, isPolice = isPolice}) exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", { job = job, job_grade = grade, cid = player.cid}) end
                                if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'success', text = 'Job updated for '..player.fullname, length = 5000 }) end
                                if player.source then TriggerClientEvent('erp_notifications:client:SendAlert', player.source, { type = 'success', text = 'Your job role has been updated for '..Jobs[job].label, length = 5000 }) end
                            else
                                exports.oxmysql:executeSync("INSERT INTO `user_jobs` (`cid`, `job`, `job_grade`) VALUES (:cid, :job, :job_grade)", {
                                    cid = player.cid,
                                    job = job,
                                    job_grade = grade
                                })
                                exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = job, job_grade = grade, cid = player.cid})
                                SetPlayerData(player.source, 'job', {name = job, grade = grade, duty = 1, isPolice = isPolice})
                                if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'success', text = 'Added '..player.fullname..' to '..Jobs[job].label, length = 5000 }) end
                                if player.source then TriggerClientEvent('erp_notifications:client:SendAlert', player.source, { type = 'success', text = 'You have been hired by '..Jobs[job].label, length = 5000 }) end
                            end
                        end)
                    
                    elseif type == "remove" then
                        exports.oxmysql:execute("SELECT * FROM user_jobs WHERE cid=:cid", { cid = player.cid }, function(jobs)
                            local hasJob = false
                            for i,v in pairs(jobs) do if v.job == job then hasJob = true break end end
                            if hasJob then
                                local isPolice = false
                                if policeJobs[job] then isPolice = true end;
                                if #jobs == 1 then
                                    SetPlayerData(player.source, 'job', {name = 'unemployed', grade = 1, duty = 1, isPolice = isPolice})
                                    exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = 'unemployed', job_grade = 1, cid = player.cid})
                                elseif #jobs > 1 then
                                    for i,v in pairs(jobs) do
                                        if v.job ~= job then
                                            SetPlayerData(player.source, 'job', {name = v.job, grade = v.job_grade, duty = 0, isPolice = isPolice})
                                            exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = v.job, job_grade = v.job_grade, cid = player.cid})
                                            break
                                        end
                                    end
                                end
                                exports.oxmysql:execute("DELETE FROM user_jobs WHERE cid=:cid AND job=:job", {job = job, cid = player.cid}, function(affected)
                                    if affected.affectedRows > 0 then
                                        if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'Removed '..player.fullname..' from '..Jobs[job].label, length = 5000 }) end
                                        if player.source then TriggerClientEvent('erp_notifications:client:SendAlert', player.source, { type = 'inform', text = 'You have been removed from '..Jobs[job].label, length = 5000 }) end
                                    end  
                                end)
                            else
                                if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'error', text = 'Player does not have this job!', length = 5000 }) end
                            end
                        end)
                    end
                else
                    if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'This job grade does not exist!', length = 5000 }) end
                end 
            else
                if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'This job does not exist!', length = 5000 }) end
            end
        else
            exports.oxmysql:execute('SELECT `cash`, `bank`, `job`, `job_grade`, `duty`, `firstname`, `lastname`, `gender`, `phone_number`, `jail_time`, `twitterhandle` FROM `users` WHERE `id`=:id LIMIT 1', {
                id = cid
            }, function(sentInfo) 
                if sentInfo and sentInfo[1] then 
                    StarterInfo = sentInfo[1]
                    local isPolice = false
                    if policeJobs[StarterInfo['job']] == true then isPolice = true end
                    local player = { source = playerId, identifier = identifier, cid = cid, id = cid,
                        cash = tonumber(StarterInfo['cash']),
                        bank = tonumber(StarterInfo['bank']),
                        job = { name = StarterInfo['job'], grade = tonumber(StarterInfo['job_grade']), duty = tonumber(StarterInfo['duty']), isPolice = isPolice },
                        sidejob = { name = "none", label = "None" },
                        firstname = StarterInfo['firstname'],
                        lastname = StarterInfo['lastname'],
                        fullname = StarterInfo['firstname']..' '..StarterInfo['lastname'],
                        gender = StarterInfo['gender'],
                        phone_number = StarterInfo['phone_number'],
                        jail_time = StarterInfo['jail_time'],
                        twitterhandle = StarterInfo['twitterhandle'],
                    }
                    if player then
                        if Jobs[job] then
                            if Jobs[job]['grades'][grade] then
                                if type == "set" then
                                    local isPolice = false
                                    if policeJobs[job] then isPolice = true end;
                                    SetPlayerData(player.source, 'job', {name = job, grade = grade, duty = 1, isPolice = isPolice})
                                    exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", { job = job, job_grade = grade, cid = player.cid})
                                    if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'Job Temporarly Set', length = 5000 }) end
                                
                                elseif type == "add" then
                                    exports.oxmysql:execute("SELECT * FROM user_jobs WHERE cid=:cid AND job=:job", {
                                        cid = player.cid,
                                        job = job
                                    }, function(jobs)
                                        if #jobs > 0 then
                                            exports.oxmysql:executeSync("UPDATE user_jobs SET job_grade=:job_grade WHERE cid=:cid AND job=:job", {job = job, job_grade = grade, cid = player.cid})
                                            exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = job, job_grade = grade, cid = player.cid})
                                            if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'success', text = 'Job updated for player', length = 5000 }) end
                                        else
                                            exports.oxmysql:executeSync("INSERT INTO `user_jobs` (`cid`, `job`, `job_grade`) VALUES (:cid, :job, :job_grade)", {
                                                cid = player.cid,
                                                job = job,
                                                job_grade = grade
                                            })
                                            exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = job, job_grade = grade, cid = player.cid})
                                            SetPlayerData(player.source, 'job', {name = job, grade = grade, duty = 1, isPolice = isPolice})
                                            if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'success', text = 'Job added for player', length = 5000 }) end
                                        end
                                    end)
                                
                                elseif type == "remove" then
                                    exports.oxmysql:execute("SELECT * FROM user_jobs WHERE cid=:cid", { cid = player.cid }, function(jobs)
                                        local hasJob = false
                                        for i,v in pairs(jobs) do if v.job == job then hasJob = true break end end
                                        if hasJob then
                                            local isPolice = false
                                            if policeJobs[job] then isPolice = true end;
                                            if #jobs == 1 then
                                                exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = 'unemployed', job_grade = 1, cid = player.cid})
                                            elseif #jobs > 1 then
                                                for i,v in pairs(jobs) do
                                                    if v.job ~= job then
                                                        exports.oxmysql:executeSync("UPDATE users SET job=:job, job_grade=:job_grade WHERE id=:cid", {job = v.job, job_grade = v.job_grade, cid = player.cid})
                                                        break
                                                    end
                                                end
                                            end
                                            exports.oxmysql:execute("DELETE FROM user_jobs WHERE cid=:cid AND job=:job", {job = job, cid = player.cid}, function(affected)
                                                if affected.affectedRows > 0 then
                                                    if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'Job removed for player', length = 5000 }) end
                                                end  
                                            end)
                                        else
                                            if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'error', text = 'Player does not have this job!', length = 5000 }) end
                                        end
                                    end)
                                end
                            else
                                if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'This job grade does not exist!', length = 5000 }) end
                            end 
                        else
                            if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'This job does not exist!', length = 5000 }) end
                        end
                    end
                end
            end)
        end
    else
        if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'inform', text = 'This person does not exist!', length = 5000 }) end
    end 
end)

RegisterCommand("setjob", function(source, args, rawCommand) -- /setjob <CID> <job> <job_grade>
    local source = source
	if IsPlayerAceAllowed(source, 'echorp.mod') then 
		TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'error', text = 'Please use /addjob', length = 5000 })
    end
end)

RegisterCommand("addjob", function(source, args, rawCommand) -- /addjob <CID> <job> <job_grade>
    local source = source
	if IsPlayerAceAllowed(source, 'echorp.mod') then 
		if tonumber(args[1]) and args[2] and tonumber(args[3]) then
            local valid = exports['echorp']:DoesCidExist(args[1])
            if valid then
                TriggerEvent('echorp:updatejob', "add", args[2], args[3], args[1], source)
            end
        end 
    end
end)

RegisterCommand("removejob", function(source, args, rawCommand) -- /removejob <CID> <job>
    local source = source
	if IsPlayerAceAllowed(source, 'echorp.mod') then 
		if tonumber(args[1]) and args[2] then
            local valid = exports['echorp']:DoesCidExist(args[1])
            if valid then
                TriggerEvent('echorp:updatejob', "remove", args[2], "1", args[1], source)
            end
        end 
    end
end)

RegisterCommand("viewjobs", function(source, args, rawCommand) -- /viewjobs <cid>
    local source = source
	if IsPlayerAceAllowed(source, 'echorp.mod') then 
		if tonumber(args[1]) then
            local valid = exports['echorp']:DoesCidExist(args[1])
            if valid then
                local cid = args[1]
                exports.oxmysql:execute("SELECT * FROM user_jobs WHERE cid=:cid", { cid = cid }, function(jobs)
                    if #jobs > 0 then
                        local output = "Player Jobs:</br>"
                        output = output.."<hr>"
                        for i,v in pairs(jobs) do
                            output = output..v.job..' ('..v.job_grade..')</br>'
                        end
                        TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'success', text = output, length = 8000 })
                    else
                        if src then TriggerClientEvent('erp_notifications:client:SendAlert', src, { type = 'error', text = 'Player does not have any jobs!', length = 5000 }) end
                    end
                end)
            end
        end 
    end
end)

AddEventHandler('echorp:toggleduty', function(source)
    local player = GetPlayerFromId(source)
    if player then
        if player.job then 
            if player.job.duty == 0 then 
                player.job.duty = 1 -- Setting them on duty
            elseif player.job.duty == 1 then 
                player.job.duty = 0 -- Setting them off duty.
            end
            local isPolice = false
            if policeJobs[player.job.name] then isPolice = true end;
            SetPlayerData(player.source, 'job', {name = player.job.name, grade = player.job.grade, duty = player.job.duty, isPolice = isPolice})
            exports.oxmysql:executeSync("UPDATE users SET duty=:duty WHERE id=:cid", {duty = player.job.duty, cid = player.cid})
            -- notifyDuty(player,"toggle")
        end
    end
end)

--[[RegisterNetEvent('echorp:notityDuty')
AddEventHandler('echorp:notifyDuty', function(ply, status)
    local player = exports['echorp']:GetPlayerFromCid(tonumber(ply.cid))
    notifyDuty(player,status)
end)

function notifyDuty(player,status)
    local timestamp = os.date("%x %H:%M EST")
    if status == "toggle" then
        if policeJobs[player.job.name] then
            if player.job.duty == 0 then 
                updateShifts(player.cid,"finish")
                updateShifts(player.cid,"diff")
                diff = shifts[player.cid]["diff"] or "N/A"
                exports['erp_adminmenu']:sendToDiscord('Police Logging', 'The following person is showing 10-42 **(CLOCKED OUT)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**\n\nShift Length: **'..diff..' Hours**', "16711680", webhook_police)
            elseif player.job.duty == 1 then 
                updateShifts(player.cid,"start")
                exports['erp_adminmenu']:sendToDiscord('Police Logging', 'The following person is showing 10-41 **(CLOCKED IN)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**', "1834841", webhook_police)
            end 
        end
        if player.job.name == "ambulance" then
            if player.job.duty == 0 then
                updateShifts(player.cid,"finish")
                updateShifts(player.cid,"diff")
                diff = shifts[player.cid]["diff"] or "N/A"
                exports['erp_adminmenu']:sendToDiscord('EMS Logging', 'The following person is showing 10-42 **(CLOCKED OUT)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**\n\nShift Length: **'..diff..' Hours**', "16711680", webhook_ems)

            elseif player.job.duty == 1 then
                updateShifts(player.cid,"start")
                exports['erp_adminmenu']:sendToDiscord('EMS Logging', 'The following person is showing 10-41 **(CLOCKED IN)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**', "1834841", webhook_ems)
            end 
        end
    elseif status == "drop" then
        if policeJobs[player.job.name] then
            if player.job.duty == 1 then 
                updateShifts(player.cid,"finish")
                updateShifts(player.cid,"diff")
                diff = shifts[player.cid]["diff"] or "N/A"
                exports['erp_adminmenu']:sendToDiscord('Police Logging', 'The following person is showing 10-42 **(DISCONNECTED)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**\n\nShift Length: **'..diff..' Hours**', "16711680", webhook_police)
            end 
        end
        if player.job.name == "ambulance" then
            if player.job.duty == 1 then
                updateShifts(player.cid,"finish")
                updateShifts(player.cid,"diff")
                diff = shifts[player.cid]["diff"] or "N/A"
                exports['erp_adminmenu']:sendToDiscord('EMS Logging', 'The following person is showing 10-42 **(DISCONNECTED)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**\n\nShift Length: **'..diff..' Hours**', "16711680", webhook_ems)
            end 
        end
    elseif status == "join" then
        if policeJobs[player.job.name] then
            if player.job.duty == 1 then 
                updateShifts(player.cid,"start")
                exports['erp_adminmenu']:sendToDiscord('Police Logging', 'The following person is showing 10-41 **(CONNECTED)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**', "1834841", webhook_police)
            end 
        end
        if player.job.name == "ambulance" then
            if player.job.duty == 1 then
                updateShifts(player.cid,"start")
                exports['erp_adminmenu']:sendToDiscord('EMS Logging', 'The following person is showing 10-41 **(CONNECTED)**\n\nID: **'..player.id..'**\nName: **'..player.fullname..'**\nTime: **'..timestamp..'**', "1834841", webhook_ems)
            end 
        end
    end
end]]

RegisterCommand("toggleduty", function(source, args, rawCommand)
    local player = GetPlayerFromId(source)
    if player then
        if player.job then
            if player.job.name == "ambulance" and player.job.duty == 0 then
                local mzDist = #(GetEntityCoords(GetPlayerPed(source)) - vector3(-475.15, -314.0, 62.15))
                if mzDist > 100 then TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'error', text = 'You must be at Mount Zonah to clock in', length = 5000 }) return end
            end
            if player.job.duty == 0 then 
                TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'success', text = 'You are now on duty!', length = 5000 })
                player.job.duty = 1 -- Setting them on duty
            elseif player.job.duty == 1 then 
                TriggerClientEvent('erp_notifications:client:SendAlert', source, { type = 'error', text = 'You are now off duty!', length = 5000 })
                player.job.duty = 0 -- Setting them off duty.
            end 
            local isPolice = false
            if policeJobs[player.job.name] then isPolice = true end;
            SetPlayerData(player.source, 'job', {name = player.job.name, grade = player.job.grade, duty = player.job.duty , isPolice = isPolice})
            exports.oxmysql:executeSync("UPDATE users SET duty=:duty WHERE id=:cid", {duty = player.job.duty, cid = player.cid})
           -- Wait(100)
            --notifyDuty(player,"toggle")
        end
    end
end)

--[[function updateShifts(cid,type)
    local cid = cid
    local type = type
    if not shifts[cid] then shifts[cid] = {} end
    if shifts[cid] and type ~= "diff" then
        if type == 'start' then shifts[cid] = {} shifts[cid][type] = os.time() else shifts[cid][type] = os.time() end
    end
    if shifts[cid] and type == "diff" then
        if shifts[cid]['start'] and shifts[cid]['finish'] then
            shifts[cid][type] = string.format("%.2f",(os.difftime(shifts[cid]['finish'],shifts[cid]['start'])/ 3600))
            return shifts[cid][type]
        end
    end
end]]

-- Money

local discordwebhook = GetConvar('anticheat_webhook', '')
local defaultTax = 0.0803

function GetBank(playerId, isCid) -- exports['echorp']:GetBank(source)
	if isCid then
		return players[playersCid[playerId]]['bank']
	end
	return players[playerId]['bank'] 
end

exports('GetBank', GetBank)

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

AddEventHandler('SplitTax', function(amount, type)
	if type == "casino" then
			local dojSplit = amount * 0.80 -- 80%
			local casinoSplit = amount * 0.20 -- 20%
			exports.oxmysql:executeSync('UPDATE businesses SET funds=funds+:amount WHERE name="doj"', { amount = dojSplit })
			exports.oxmysql:executeSync('UPDATE businesses SET funds=funds+:amount WHERE name="casino"', { amount = casinoSplit })
	else
			exports.oxmysql:executeSync('UPDATE businesses SET funds=funds+:amount WHERE name="doj"', { amount = amount })
	end
end)

local function TaxPlayer(sentAmount, player, version, varTax)
	local amount = tonumber(sentAmount)
	if varTax == nil or varTax == false then varTax = defaultTax end
	local tableJ = nil
	if type(varTax) == "table" then
			local knownVar = varTax
			varTax, taxType = knownVar['num'], knownVar['type']
	end
	local taxAmount = amount * varTax
	if version == 1 then
			local finalAmount = amount - taxAmount
			TriggerEvent('SplitTax', taxAmount, taxType)
			if player then
					local taxAmount = round(taxAmount, 2)
					TriggerClientEvent('erp_notifications:client:SendAlert', player.source, { type = 'inform', text = 'This transaction was taxed at a rate of '..varTax..'% ($'..taxAmount..')', length = 7500 })
			end
			return finalAmount
	elseif version == 2 then
			TriggerEvent('SplitTax', taxAmount, taxType)
			if player then
					local taxAmount = round(taxAmount, 2)
					TriggerClientEvent('erp_notifications:client:SendAlert', player.source, { type = 'inform', text = 'This transaction was taxed at a rate of 8.22% ($'..taxAmount..')', length = 7500 }) 
			end
			TriggerEvent('RemoveBank', player.cid, taxAmount, true, false)
	end
end

local crazyThreshold = 100000

AddEventHandler('AdjustBank', function(playerId, amount, isCid, shouldTax, cb) 
	local id = playerId
	if not isCid then
		id = GetOnePlayerInfo(playerId, 'cid')
	end
	if type(amount) == 'string' then amount = tonumber(amount) end
	local player = GetPlayerFromCid(id)
	if shouldTax and amount >= 0 then amount = TaxPlayer(amount, player, 1) end
	if amount >= crazyThreshold then
			local msg = "Type: **AdjustBank**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end
	exports.oxmysql:update("UPDATE users SET bank = bank+:amount WHERE id=:id", {amount = amount, id = id}, function(endResult)
			if endResult > 0 then
					local newBank = player.bank + amount
					SetPlayerData(player.source, 'bank', round(newBank, 2))
					if cb then cb(true) end
			else
					if cb then cb(false) end
			end
	end)
end)

AddEventHandler('AddBank', function(playerId, amount, isCid, shouldTax, taxVar, cb) 
	local id = playerId
	if isCid == nil or not isCid then id = GetPlayerFromId(playerId).cid end
	if type(amount) == 'string' then amount = tonumber(amount) end if type(playerId) == 'string' then playerId = tonumber(playerId) end
	local player = GetPlayerFromCid(id)
	if taxVar == nil or taxVar == false then taxVar = defaultTax end 
	if shouldTax then amount = TaxPlayer(amount, player, 1, taxVar) end

	if amount >= crazyThreshold then
			local msg = "Type: **AddBank**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end
	
	exports.oxmysql:update("UPDATE users SET bank = bank+:amount WHERE id=:id", {amount = amount, id = id}, function(endResult)
			if endResult > 0 then
					if player then
							local newBank = player.bank + amount
							SetPlayerData(player.source, 'bank', round(newBank, 2))
							TriggerClientEvent("banking:viewBalance", player.source, round(newBank, 2))
							TriggerClientEvent("banking:addBalance", player.source, round(amount, 2))
					end
			end
			if cb then cb(endResult > 0)  end
	end)
end)

AddEventHandler('AddBankOffline', function(playerId, amount, shouldTax, taxVar) 
	local id = playerId
	if type(amount) == 'string' then amount = tonumber(amount) end if type(playerId) == 'string' then playerId = tonumber(playerId) end
	if taxVar == nil or taxVar == false then taxVar = defaultTax end
	if shouldTax then amount = TaxPlayer(amount, player, 1, taxVar) end

	if amount >= crazyThreshold then
			local msg = "Type: **AddBankOffline**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end

	exports.oxmysql:executeSync("UPDATE users SET bank = bank+:amount WHERE id=:id", {amount = amount, id = id})
end)

AddEventHandler('RemoveBank', function(playerId, amount, isCid, shouldTax) 
	local id = playerId
	if isCid == nil or not isCid then id = GetPlayerFromId(playerId).cid end
	if type(amount) == 'string' then amount = tonumber(amount) end if type(playerId) == 'string' then playerId = tonumber(playerId) end
	local player = GetPlayerFromCid(id)
	if shouldTax then TaxPlayer(amount, player, 2) end

	if amount >= crazyThreshold then
			local msg = "Type: **RemoveBank**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end

	exports.oxmysql:update("UPDATE users SET bank = bank-:amount WHERE id=:id", {amount = amount, id = id}, function(endResult)
			if endResult > 0 then
					local newBank = player.bank - amount
					SetPlayerData(player.source, 'bank', round(newBank, 2))
					TriggerClientEvent("banking:viewBalance", player.source, round(newBank, 2))
					TriggerClientEvent("banking:removeBalance", player.source, round(amount, 2))
			end
	end)
end)

AddEventHandler('TransferBank', function(source, target, amount, shouldTax, cb) 
	if type(amount) == 'string' then amount = tonumber(amount) end if type(source) == 'string' then source = tonumber(source) end
	if source then
			if target and amount then
					local player = GetPlayerFromId(source)
					if player then
							exports.oxmysql:update("UPDATE users SET bank = bank-:amount WHERE id=:id", {amount = amount, id = player.cid}, function(endResult)
									if endResult > 0 then
											local newBank = player.bank - amount
											SetPlayerData(player.source, 'bank', round(newBank, 2))
											if cb then cb(true) end;
											exports.oxmysql:update("UPDATE users SET bank = bank+:amount WHERE id=:id", {amount = amount, id = target}, function(newResult)
													if newResult > 0 then
															local targetPly = GetPlayerFromCid(target)
															if targetPly then
																	local newBank = targetPly.bank + amount
																	SetPlayerData(targetPly.source, 'bank', round(newBank, 2))
																	TriggerClientEvent('erp_notifications:client:SendAlert', targetPly['source'], { type = 'inform', text = 'You were transferred $'..amount..' from '..player['fullname'], length = 5000 })
															end
													end 
											end)
									else
											if cb then cb(false) end;
									end
							end)
					end
			end 
	end 
end)

-- Cash

function GetCash(playerId, isCid) -- exports['echorp']:GetCash(source)
	if isCid then
		return players[playersCid[playerId]]['cash']
	end
	return players[playerId]['cash']
end

AddEventHandler('AdjustCash', function(playerId, amount, isCid, cb) 
	local id = playerId
	if isCid == nil or not isCid then id = exports['echorp']:GetPlayerFromId(playerId).cid end
	if type(amount) == 'string' then amount = tonumber(amount) end if type(playerId) == 'string' then playerId = tonumber(playerId) end

	if amount >= crazyThreshold then
			local msg = "Type: **AdjustCash**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end

	exports.oxmysql:update("UPDATE users SET cash = cash+:amount WHERE id=:id", {amount = amount, id = id}, function(endResult)
			if endResult > 0 then
					local player = GetPlayerFromCid(id)
					local newCash = player.cash + amount
					SetPlayerData(player.source, 'cash', round(newCash, 2))
					if cb then cb(true) end
			else
					if cb then cb(false) end
			end
	end)
end)

AddEventHandler('AddCash', function(playerId, amount, isCid) 
	local id = playerId
	if isCid == nil or not isCid then id = GetPlayerFromId(playerId).cid end
	if type(amount) == 'string' then amount = tonumber(amount) end if type(playerId) == 'string' then playerId = tonumber(playerId) end

	if amount >= crazyThreshold then
			local msg = "Type: **AddCash**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end

	exports.oxmysql:update("UPDATE users SET cash = cash+:amount WHERE id=:id", {amount = amount, id = id}, function(endResult)
			if endResult > 0 then
					local player = GetPlayerFromCid(id)
					local newCash = player.cash + amount
					SetPlayerData(player.source, 'cash', round(newCash, 2))
					TriggerClientEvent("banking:addCash", player.source, round(amount, 2))
					TriggerClientEvent('banking:viewCash', player.source, round(newCash, 2))
			end
	end)
end)

AddEventHandler('RemoveCash', function(playerId, amount, isCid) 
	local id = playerId
	if isCid == nil or not isCid then id = GetPlayerFromId(playerId).cid end
	if type(amount) == 'string' then amount = tonumber(amount) end if type(playerId) == 'string' then playerId = tonumber(playerId) end

	if amount >= crazyThreshold then
			local msg = "Type: **RemoveCash**\n Citizen ID: **"..id.."**\nAmount: **"..amount.."**\n\nKeep an eye on this one, I was told to transaction over $100,000, "..GetInvokingResource()
			exports['erp_adminmenu']:sendToDiscord('Anti Cheat', msg, "16711680", discordwebhook)
	end

	exports.oxmysql:update("UPDATE users SET cash = cash-:amount WHERE id=:id", {amount = amount, id = id}, function(endResult)
			if endResult > 0 then
					local player = GetPlayerFromCid(id)
					local newCash = player.cash - amount
					SetPlayerData(player.source, 'cash', round(newCash, 2))
					TriggerClientEvent("banking:removeCash", player.source, round(amount, 2))
					TriggerClientEvent('banking:viewCash', player.source, round(newCash, 2))
			end
	end)
end)

exports('GetCash', GetCash)

GlobalState.canRob = false

CreateThread(function()
	Wait(2500)
	GlobalState.canRob = false
	Wait(1800000)
	GlobalState.canRob = true
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
	if eventData['secondsRemaining'] <= 1800 then
		GlobalState.canRob = false
	end
end)