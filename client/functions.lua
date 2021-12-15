PlayerData = {}

RegisterNetEvent('echorp:updateinfo')
AddEventHandler('echorp:updateinfo', function(toChange, targetData) 
    PlayerData[toChange] = targetData
end)

exports('moneyInfo', function(str) return { cash = PlayerData['cash'], bank = PlayerData['bank'] } end)
exports('mycash', function(str) return PlayerData['cash'] end)
exports('mybank', function(str) return PlayerData['bank'] end)

function GetPlayerData() return PlayerData end
exports('GetPlayerData', GetPlayerData) -- exports['echorp']:GetPlayerData()

RegisterKeyMapping('maincontrol', '(Framework) Main Control', 'keyboard', 'E')

RegisterCommand('maincontrol', function()
    TriggerEvent('echorp:maincontrol')
end)