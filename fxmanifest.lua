fx_version "cerulean"

game "gta5"

client_scripts {"colors-rgb.lua", "config.lua", "utils.lua", "client/client.lua"}

server_scripts {"@mysql-async/lib/MySQL.lua", "config.lua", "utils.lua", "server/main.lua"}

shared_scripts {"@eclipse_core/imports.lua"}