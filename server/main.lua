local QBCore = exports['qb-core']:GetCoreObject()

local playerBuckets = {}

local function SetPlayerToBucket(source, bucketId)
    if Config.Camera.cinematic and Config.Camera.cinematic.useBucket then
        SetPlayerRoutingBucket(source, bucketId)
        SetRoutingBucketPopulationEnabled(bucketId, false)
        playerBuckets[source] = bucketId
    end
end

local function RemovePlayerFromBucket(source)
    if playerBuckets[source] then
        SetPlayerRoutingBucket(source, 0)
        playerBuckets[source] = nil
    end
end

local function GetPlayerCharacters(license)
    local result = MySQL.query.await('SELECT * FROM players WHERE license = ?', {license})

    if result then
        for i = 1, #result do
            local char = result[i]

            if char.metadata then
                local metadata = type(char.metadata) == 'string' and json.decode(char.metadata) or char.metadata

                local playTime = metadata and metadata.playtime or 0

                if not metadata then
                    metadata = {}
                end

                metadata.playtime = playTime
                result[i].metadata = json.encode(metadata)
            else
                local metadata = { playtime = 0 }
                result[i].metadata = json.encode(metadata)
            end
        end
    end

    return result or {}
end

local function GiveStarterItems(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Config.StartingItems and #Config.StartingItems > 0 then
        for _, v in pairs(Config.StartingItems) do
            local info = {}
            if v.item == 'id_card' then
                info.citizenid = Player.PlayerData.citizenid
                info.firstname = Player.PlayerData.charinfo.firstname
                info.lastname = Player.PlayerData.charinfo.lastname
                info.birthdate = Player.PlayerData.charinfo.birthdate
                info.gender = Player.PlayerData.charinfo.gender
                info.nationality = Player.PlayerData.charinfo.nationality
            end
            Player.Functions.AddItem(v.item, v.amount, false, info)
        end
    end
end

local function DeleteCharacter(source, citizenid)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')

    if not license or not citizenid then
        return false
    end

    local result = MySQL.scalar.await('SELECT license FROM players WHERE citizenid = ?', {citizenid})

    if not result or result ~= license then
        TriggerClientEvent('QBCore:Notify', src, 'Bu karakteri silemezsiniz!', 'error')
        return false
    end

    QBCore.Player.DeleteCharacter(src, citizenid)

    TriggerClientEvent('QBCore:Notify', src, 'Karakter silindi!', 'success')

    return true
end

local function SelectCharacter(source, citizenid)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')

    if not license or not citizenid then
        return false
    end

    local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? AND license = ?', {citizenid, license})

    if not result or #result == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Karakter bulunamadı!', 'error')
        return false
    end

    QBCore.Player.Login(src, citizenid)

    return true
end

RegisterNetEvent('qrp-multicharacter:server:selectCharacter', function(citizenid)
    local src = source

    RemovePlayerFromBucket(src)

    if SelectCharacter(src, citizenid) then
        local result = MySQL.query.await('SELECT position FROM players WHERE citizenid = ?', {citizenid})
        local lastPosition = nil
        if result and result[1] and result[1].position then
            local pos = json.decode(result[1].position)
            if pos and pos.x then
                lastPosition = pos
            end
        end

        TriggerClientEvent('qrp-multicharacter:client:transitionToSpawnSelector', src, lastPosition)
    end
end)

RegisterNetEvent('qrp-multicharacter:server:createCharacter', function(data)
    local src = source

    RemovePlayerFromBucket(src)

    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data

    if Config.StartingMoney then
        newData.money = {
            cash = Config.StartingMoney.cash,
            bank = Config.StartingMoney.bank
        }
    end

    if QBCore.Player.Login(src, false, newData) then
        Wait(500)

        print('^2[qrp-multicharacter]^7 ' .. GetPlayerName(src) .. ' yeni karakter oluşturdu!')

        GiveStarterItems(src)

        TriggerClientEvent('qrp-multicharacter:client:closeNUI', src)

        if Config.Appearance.openOnCreate then
            Wait(1000)
            if Config.Appearance.script == "qb-clothing" then
                TriggerClientEvent('qb-clothing:client:openMenu', src)
            elseif Config.Appearance.script == "illenium-appearance" then
                exports['illenium-appearance']:startPlayerCustomization(src)
            elseif Config.Appearance.script == "fivem-appearance" then
                exports['fivem-appearance']:startPlayerCustomization(src)
            end
        end

        Wait(6000)
        TriggerClientEvent('qrp-multicharacter:client:openSpawnSelector', src, nil)
    end
end)

RegisterNetEvent('qrp-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source

    if not Config.DeleteCharacter.enabled then return end

    if DeleteCharacter(src, citizenid) then
        local license = QBCore.Functions.GetIdentifier(src, 'license')
        local characters = GetPlayerCharacters(license)
        TriggerClientEvent('qrp-multicharacter:client:characterDeleted', src, characters)
    end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    Wait(0)

    deferrals.update('Karakter bilgileri yükleniyor...')

    local license = QBCore.Functions.GetIdentifier(src, 'license')

    if not license then
        deferrals.done('Lisans bulunamadı!')
        return
    end

    deferrals.done()
end)

RegisterNetEvent('qrp-multicharacter:server:requestCharacters', function()
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')

    if not license then return end

    if Config.Camera.mode == "cinematic" and Config.Camera.cinematic.useBucket then
        SetPlayerToBucket(src, Config.Camera.cinematic.bucketId)
    end

    local characters = GetPlayerCharacters(license)

    TriggerClientEvent('qrp-multicharacter:client:openCharacterSelection', src, characters)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    RemovePlayerFromBucket(src)
end)

QBCore.Functions.CreateCallback('qrp-multicharacter:server:getAppearance', function(source, cb, citizenid)
    if not citizenid then
        cb(nil)
        return
    end

    local appearanceData = nil

    if Config.Appearance.script == "qb-clothing" then
        local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = 1', {citizenid})
        if result and result[1] then
            appearanceData = {
                model = result[1].model,
                components = json.decode(result[1].skin or "{}"),
                props = json.decode(result[1].skin or "{}")
            }
        end

    elseif Config.Appearance.script == "illenium-appearance" then
        local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ?', {citizenid})
        if result and result[1] then
            local skin = json.decode(result[1].skin or "{}")
            appearanceData = skin
        end

    elseif Config.Appearance.script == "fivem-appearance" then
        local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ?', {citizenid})
        if result and result[1] then
            appearanceData = json.decode(result[1].skin or "{}")
        end
    end

    cb(appearanceData)
end)

exports('GetPlayerCharacters', GetPlayerCharacters)
exports('DeleteCharacter', DeleteCharacter)
exports('SelectCharacter', SelectCharacter)

if Config.Debug then
    print('^2[qrp-multicharacter]^7 Server started successfully!')
end
