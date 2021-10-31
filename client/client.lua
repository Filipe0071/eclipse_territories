RegisterNetEvent("esx:playerLoaded") 
AddEventHandler("esx:playerLoaded", function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent("esx:playerLogout") 
AddEventHandler("esx:playerLogout", function(xPlayer)
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    ESX.PlayerData.job = job
    if lastZone then
        TriggerServerEvent("eclipse_territories:LeaveZone", lastZone, ESX.PlayerData.job.name)
        lastZone = false
    end
end)

local StopInfluence = false

Start = function()
    for k, v in pairs(Territories) do
        local count = 0
        Territories[k].blips = {}
        for _, area in pairs(Territories[k].areas) do
            local blipHandle = Utils.AddAreaBlip(area.location.x, area.location.y, area.location.z, area.height, area.width, area.heading, BlipColors[v.control], math.floor(v.influence), true, area.display)
            local blip = TableCopy(Utils.GetBlip(blipHandle))
            Territories[k].blips[blipHandle] = blip
        end
    end
    Update()
end

TableCopy = function(tab)
    local r = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
            r[k] = TableCopy(v)
        else
            r[k] = v
        end
    end
    return r
end

Update = function()
    if Config.ShowDebugText then
        testText = Utils.drawTextTemplate()
        testText.x = 0.50
        testText.y = 0.95
    end
    while true do
        local closest = GetClosestZone()
        local area = Territories[closest]
        local dead = DeathCheck(lastZone)
        if not dead then
            CheckLocation(closest)
            UpdateBlips()
            if Config.ShowDebugText and area then
                testText.colour1 = colorsRGB[TextColors[area.control]][1]
                testText.colour2 = colorsRGB[TextColors[area.control]][2]
                testText.colour3 = colorsRGB[TextColors[area.control]][3]
                testText.colour4 = math.floor(area.influence*2.5)
                testText.text = "Zona: "..closest.." | Organização: "..area.control:sub(1, 1):upper()..area.control:sub(2).." | Influencia: "..math.floor(area.influence).."%"
                Utils.drawText(testText)
            end
        else
            if lastZone then
                if ESX.PlayerData.job and ESX.PlayerData.job.name and GangLookup[ESX.PlayerData.job.name] then
                    TriggerServerEvent("eclipse_territories:LeaveZone", lastZone, ESX.PlayerData.job.name)
                    lastZone = false
                end
            end
        end
        Wait(0)
    end
end

CheckLocation = function(closest)
    local area = Territories[closest]
    local plyPed = GetPlayerPed(-1)
    local plyPos = GetEntityCoords(plyPed)
    local plyHp = GetEntityHealth(plyPed)
    if closest then
        if plyHp > 100 then
            if not lastZone or lastZone ~= closest then
                if lastZone then
                    TriggerServerEvent("eclipse_territories:LeaveZone", lastZone, ESX.PlayerData.job.name)
                end
                if not StopInfluence then
                    lastZone = closest
                    if ESX.PlayerData.job and ESX.PlayerData.job.name and GangLookup[ESX.PlayerData.job.name] then
                        TriggerServerEvent("eclipse_territories:EnterZone", closest, ESX.PlayerData.job.name)
                    end
                end
            else
                if lastZone and StopInfluence then     
                    if ESX.PlayerData.job and ESX.PlayerData.job.name and GangLookup[ESX.PlayerData.job.name] then
                        TriggerServerEvent("eclipse_territories:LeaveZone", lastZone, ESX.PlayerData.job.name)
                    end
                end
            end
        end
    else
        if lastZone then
            if ESX.PlayerData.job and ESX.PlayerData.job.name and GangLookup[ESX.PlayerData.job.name] then
                TriggerServerEvent("eclipse_territories:LeaveZone", lastZone, ESX.PlayerData.job.name)
            end
            lastZone = false
        end
    end
end

DeathCheck = function(zone)
    local plyPed = GetPlayerPed(-1)
    local plyHp = GetEntityHealth(plyPed)
    local dead = IsPedFatallyInjured(plyPed)
    if isDead then
        if not dead then
            isDead = false
        end
    else
        if dead and zone then
            isDead = true
            local killer = NetworkGetEntityKillerOfPlayer(PlayerId())
            local killerId = GetPlayerByEntityID(killer)
            if killer ~= plyPed and killerId ~= nil and NetworkIsPlayerActive(killerId) then
                local serverId = GetPlayerServerId(killerId)
                if serverId and serverId ~= -1 then
                    TriggerServerEvent("eclipse_territories:GotMurdered", serverId, zone)
                end
            end
        end
    end
    return isDead
end

UpdateBlips = function()
    for k, v in pairs(Territories) do
        if v.blips then
            for handle, blip in pairs(v.blips) do
                if Config.DisplayZoneForAll or PlayerInGang() then
                    if blip.color ~= BlipColors[v.control] or blip.alpha ~= math.floor(v.influence) then
                        Utils.SetBlip(handle, "alpha", math.floor(v.influence))
                        Utils.SetBlip(handle, "color", BlipColors[v.control])
                        local b = TableCopy(Utils.GetBlip(handle))
                        Territories[k].blips[handle] = b
                    end
                else
                    if blip.alpha ~= 0 then
                        Utils.SetBlip(handle, "alpha", 0)
                        local b = TableCopy(Utils.GetBlip(handle))
                        Territories[k].blips[handle] = b
                    end
                end
            end
        end
    end
end

GetClosestZone = function()
    local closest
    local thisZone = GetNameOfZone(GetEntityCoords(GetPlayerPed(-1)))
    for k, v in pairs(Territories) do
        if v.zone == thisZone then
            closest = k
        end
    end
    return (closest or false)
end

Sync = function(tab)
    for k, v in pairs(tab) do
        Territories[k].influence = v.influence
        Territories[k].control = v.control
    end
end

GetPlayerByEntityID = function(id)
    for i = 0, Config.MaxPlayerCount do
        if (NetworkIsPlayerActive(i) and GetPlayerPed(i) == id) then
            return i
        end
    end
    return nil
end

PlayerInGang = function()
    if not GetPlayerData or (not ESX.PlayerData.job) or (not ESX.PlayerData.job.name) then
        return false
    end
    if GangLookup[ESX.PlayerData.job.name] then
        return true
    else
        return false
    end
end

Citizen.CreateThread(Start)

local isCuffed = false

GotCuffed = function()
    isCuffed = not isCuffed
    local zone = (isCuffed and GetClosestZone())
    if zone then
        TriggerServerEvent("eclipse_territories:CuffSuccess", zone)
    end
end

GetPlayerData = function()
    return ESX.GetPlayerData()
end

Utils.event(1, Sync, "eclipse_territories:Sync")
Utils.event(1, GotCuffed, "eclipse_territories:GotCuffed")