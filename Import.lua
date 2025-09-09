local BaseURL = 'https://raw.githubusercontent.com/moon-rblx/Project-Madara/refs/heads/main/Data/'

return {
    Islands = loadstring(game:HttpGet(BaseURL .. '/' .. game.GameId .. '/' .. game.PlaceId .. '/Islands.lua'))(),
    Mobs = loadstring(game:HttpGet(BaseURL .. '/' .. game.GameId .. '/' .. game.PlaceId .. '/Mobs.lua'))()
}