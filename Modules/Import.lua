local Sea = workspace:GetAttribute('MAP')

local Modules = {}
local BaseURL = 'https://bloxsync.com/'

Modules.Mobs = loadstring(game:HttpGet(BaseURL .. 'PM/Data/' .. game.GameId .. '/' .. Sea .. '/Mobs.lua'))()

return Modules