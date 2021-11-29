Init = function()
    if not Config then
        return
    end
    Wait(1000)
    Start()
    MySQL.Async.fetchAll("SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME=@tableName", {["@tableName"] = "eclipse_territories"}, function(data)
        if data and type(data) == "table" then
            MySQL.Async.fetchAll("SELECT * FROM eclipse_territories", {}, function(retData)
                if retData and type(retData) == "table" and retData[1] then
                    for k, v in pairs(retData) do
                        if v and v.zone and v.control and v.influence and Territories[v.zone] then
                            Territories[v.zone].control = v.control
                            Territories[v.zone].influence = v.influence
                        end
                    end
                end
            end)
        end
    end)
end

Start = function()
    if Territories and type(Territories) == "table" then
        for k, v in pairs(Territories) do
            Territories[k].players = {}
        end
    end
end

Update = function()
    while true do
        local now = GetGameTimer()
        if (not lastTime) or (now - lastTime > (Config and Config.InfluenceTick or 5000)) then
            lastTime = now
            TallyUp()
        end
        if (not lastSave) or (now - lastSave > (Config and Config.SqlSaveTimer or 5)*60*1000) then
            lastSave = now
            MySQL.Async.fetchAll("SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME=@eclipse_territories", {["@eclipse_territories"] = "eclipse_territories"}, function(retData)
                if retData and type(retData) == "table" and retData[1] then
                    if Territories and type(Territories) == "table" then
                        for k, v in pairs(Territories) do
                            if v and type(v) == "table" and v.control and v.influence then
                                MySQL.Async.execute("UPDATE eclipse_territories SET control=@control,influence=@influence WHERE zone=@zone", {["@control"] = v.control, ["@influence"] = v.influence, ["@zone"] = k})
                            end
                        end
                    end
                end
            end)
        end
        Wait(0)
    end
end

TallyUp = function()
    local doUpdate = false
    if not Territories or not type(Territories) == "table" then
        return
    end
    for k, v in pairs(Territories) do
        if v and type(v) == "table" and v.control and v.influence then
            local mostMembers, memberCount, isDraw = GetActiveMembers(v)
            if mostMembers then
                if isDraw then
                    if v.control == mostMembers or v.control == isDraw then
                    else
                        doUpdate = true
                        v.influence = math.max(0.0, v.influence - 1.0)
                    end
                else
                    if v.control == mostMembers then
                        doUpdate = true
                        v.influence = math.min(100.0, v.influence + 1.0)
                    else
                        doUpdate = true
                        v.influence = math.max(0.0, v.influence - 1.0)
                        if v.influence <= 0.0 then
                            v.control = mostMembers
                        end
                    end
                end
            end
        end
    end
    if doUpdate then
        TriggerClientEvent("eclipse_territories:Sync", -1, Territories)
    end
end

GetActiveMembers = function(tab)
    local scores = {}
    if not tab or type(tab) ~= "table" or not tab.players or type(tab.players) ~= "table" then
        return
    end
    for k, v in pairs(tab.players) do
        if v then
            if not scores[v] then
                scores[v] = 1
            else
                scores[v] = scores[v] + 1
            end
        end
    end
    local isDraw = false
    local highest, highestScore
    for k, v in pairs(scores) do
        if not highestScore or v >= highestScore then
            if not highestScore or v > highestScore then
                highestScore = v
                highest = k
                isDraw = false
            else
                isDraw = k
            end
        end
    end
    return highest, highestScore, isDraw
end

EnterZone = function(zone, job)
    local _source = source
    if not Territories or type(Territories) ~= "table" or not Territories[zone] or type(Territories[zone]) ~= "table" or not Territories[zone].players then
        return
    end
    Territories[zone].players[_source] = job
end

LeaveZone = function(zone, job)
    local _source = source
    if not Territories or type(Territories) ~= "table" or not Territories[zone] or type(Territories[zone]) ~= "table" or not Territories[zone].players then
        return
    end
    Territories[zone].players[_source] = nil
end

GetPlayer = function(player)
    local xPlayer = ESX.GetPlayerFromId(player)
    while not xPlayer do
        xPlayer = ESX.GetPlayerFromId(player)
        Wait(0)
    end
    return xPlayer
end

GetPlayerGang = function(source)
    local xPly = GetPlayer(_source)
    local job = xPly.job.name
    if GangLookup[job] then
        return job.name
    else
        return false
    end
end

PlayerKilled = function(killer, zone)
    local _source = source
    local slayer = killer
    local sourceGang = GetPlayerGang(source)
    local killerGang = GetPlayerGang(killer)
    if not sourceGang or not killerGang then
        return
    end
    local doSync = false
    local influencer = false
    if GangLookups and sourceGang and killerGang then
        local v = Territories[zone]
        if not v or type(v) ~= "table" or not v.control or not v.influence then
            return
        end
        if v.control == sourceGang then
            v.influence = math.max(0, v.influence - 10)
            doSync = true
            influencer = v.control
        elseif v.control == killerGang then
            v.influence = math.min(100, v.influence + 10)
            doSync = true
            influencer = v.control
        end
    elseif killerGang then
        local v = Territories[zone]
        if not v then
            return
        end
        if v.control == killerGang then
            v.influence = math.min(100, v.influence + 5)
            doSync = true
            influencer = v.control
        end
    elseif sourceGang then
        local v = Territories[zone]
        if not v then
            return
        end
        if v.control == sourceGang then
            v.influence = math.max(0, v.influence - 5)
            doSync = true
            influencer = v.control
        end
    end
    if doSync then
        TriggerClientEvent("eclipse_territories:Sync", -1, Territories)
    end
end

PlayerDropped = function()
    for zone, territory in pairs(Territories) do
        for server_id, gang in pairs(territory.players) do
            if server_id == source then
                Territories[zone].players[server_id] = nil
                return
            end
        end
    end
end

Utils.event(1, EnterZone, "eclipse_territories:EnterZone")
Utils.event(1, LeaveZone, "eclipse_territories:LeaveZone")
Utils.event(1, PlayerKilled, "eclipse_territories:GotMurdered")
Utils.event(1, PlayerDropped, "playerDropped")

Citizen.CreateThread(Init)
