local BaseURL = 'https://raw.githubusercontent.com/'

return {
    Islands = loadstring(game:HttpGet(BaseURL .. ''))(),
    Mobs = loadstring(game:HttpGet(BaseURL .. ''))()
}