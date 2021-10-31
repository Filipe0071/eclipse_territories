Config = {
    ShowDebugText = true,
    InfluenceTick = 5000,
    DisplayZoneForAll = false,
    MaxPlayerCount = 48,
    SqlSaveTimer = 5,
    SmackCheaters = true,
    PoliceJobs = {"dpls"},
    GangJobs = {"groove", "ballas", "bloods"}
}

BlipColors = {dpls = 0, groove = 2, ballas = 83, bloods = 75}
TextColors = {dpls = "white", groove = "green", ballas = "purple", bloods = "red"}

Territories = {
    ["Groove"] = {
        control = "ballas",
        influence = 100.0,
        zone = "DAVIS",
        areas = {
            [1] = {location = vector3(56.70, -1818.36, 27.66), width = 390.0, height = 210.0, heading = 50, display = 3},
        },
    },
    ["ForumDrive"] = {
        control = "groove",
        influence = 100.0,
        zone = "CHAMH",
        areas = {
            [1] = {location = vector3(-147.9323, -1600.784, 38.29156), width = 200.0, height = 280.0, heading = 50, display = 3},
        },
    },
    ["Rancho"] = {
        control = "bloods",
        influence = 100.0,
        zone = "RANCHO",
        areas = {
            [1] = {location = vector3(320.2412, -2039.633, 28.96141), width = 298.5, height = 210.0, heading = 50, display = 3},
        },
    },
}

GangLookup = {}

for k, v in pairs(Config.GangJobs) do
    GangLookup[v] = true
end

for k, v in pairs(Config.PoliceJobs) do
    GangLookup[v] = true
end

PoliceLookup = {}

for k, v in pairs(Config.PoliceJobs) do
    PoliceLookup[v] = true
end