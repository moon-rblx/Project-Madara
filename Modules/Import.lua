local Sea = workspace:GetAttribute('MAP')

local Modules = {}
local BaseURL = 'https://raw.githubusercontent.com/'

Modules.Mobs = loadstring(game:HttpGet(BaseURL .. 'moon-rblx/Project-Madara/refs/heads/main/Data/994732206/Sea1/Mobs.lua'))()


return Modules
