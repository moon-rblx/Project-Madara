if game.GameId ~= 994732206 then return end
repeat task.wait() until game:IsLoaded()

local BaseURL = 'https://raw.githubusercontent.com/'
local Quake = loadstring(game:HttpGet(BaseURL .. 'idonthaveoneatm/quake/refs/heads/normal/bundled.lua'))()

local function patchQuakeLibrary()
    local originalWindow = Quake.Window

    function Quake:Window(windowProperty)
        local window = originalWindow(self, windowProperty)
        local originalTab = window.Tab

        function window:Tab(tabProperty)
            local tab = originalTab(self, tabProperty)
            local originalGroup = tab.Group

            local function wrapToggle(self, originalToggleMethod, toggleProperty)
                local currentValue = toggleProperty.Default or false
                local originalCallback = toggleProperty.Callback

                toggleProperty.Callback = function(value)
                    currentValue = value
                    if originalCallback then
                        originalCallback(value)
                    end
                end

                local toggle = originalToggleMethod(self, toggleProperty)
                return setmetatable({}, {
                    __index = function(_, key)
                        if key == 'Value' then
                            return currentValue
                        else
                            return toggle[key]
                        end
                    end,
                    __newindex = function(_, key, value)
                        if key == 'Value' and typeof(value) == 'boolean' then
                            toggle:SetValue(value)
                        else
                            toggle[key] = value
                        end
                    end
                })
            end

            local function wrapDropdown(self, originalDropdownMethod, dropdownProperty)
                local currentValue = dropdownProperty.Multiselect and (dropdownProperty.Default or {}) or (dropdownProperty.Default or '')
                local originalCallback = dropdownProperty.Callback

                dropdownProperty.Callback = function(value)
                    currentValue = value
                    if originalCallback then
                        originalCallback(value)
                    end
                end

                local dropdown = originalDropdownMethod(self, dropdownProperty)
                return setmetatable({}, {
                    __index = function(_, key)
                        if key == 'Value' then
                            return currentValue
                        else
                            return dropdown[key]
                        end
                    end,
                    __newindex = function(_, key, value)
                        if key == 'Value' then
                            if dropdownProperty.Multiselect then
                                if type(value) == 'table' then
                                    dropdown:SelectItems(value)
                                end
                            elseif type(value) == 'string' then
                                dropdown:SelectItem(value)
                            end
                        else
                            dropdown[key] = value
                        end
                    end
                })
            end

            local function wrapSlider(self, originalSliderMethod, sliderProperty)
                local currentValue = sliderProperty.InitialValue or sliderProperty.Min or 0
                local originalCallback = sliderProperty.Callback

                sliderProperty.Callback = function(value)
                    currentValue = value
                    if originalCallback then
                        originalCallback(value)
                    end
                end

                local slider = originalSliderMethod(self, sliderProperty)
                return setmetatable({}, {
                    __index = function(_, key)
                        if key == 'Value' then
                            return currentValue
                        else
                            return slider[key]
                        end
                    end,
                    __newindex = function(_, key, value)
                        if key == 'Value' and typeof(value) == 'number' then
                            slider:SetValue(value)
                        else
                            slider[key] = value
                        end
                    end
                })
            end

            local originalToggleMethod = tab.Toggle
            local originalDropdownMethod = tab.Dropdown
            local originalSliderMethod = tab.Slider

            function tab:Toggle(toggleProperty)
                return wrapToggle(self, originalToggleMethod, toggleProperty)
            end
            function tab:Dropdown(dropdownProperty)
                return wrapDropdown(self, originalDropdownMethod, dropdownProperty)
            end
            function tab:Slider(sliderProperty)
                return wrapSlider(self, originalSliderMethod, sliderProperty)
            end

            function tab:Group(groupProperty)
                local group = originalGroup(self, groupProperty)

                local gToggle = group.Toggle
                local gDropdown = group.Dropdown
                local gSlider = group.Slider

                function group:Toggle(toggleProperty)
                    return wrapToggle(self, gToggle, toggleProperty)
                end
                function group:Dropdown(dropdownProperty)
                    return wrapDropdown(self, gDropdown, dropdownProperty)
                end
                function group:Slider(sliderProperty)
                    return wrapSlider(self, gSlider, sliderProperty)
                end

                return group
            end

            return tab
        end

        return window
    end
end

patchQuakeLibrary()

local CoreUtils = loadstring(game:HttpGet(BaseURL .. 'moon-rblx/Shared/refs/heads/main/CoreUtils.lua'))()
local Import = loadstring(game:HttpGet(BaseURL .. 'moon-rblx/Project-Madara/refs/heads/main/Import.lua'))()
local Toggles, Options = {}, {}

local Enemies = workspace:FindFirstChild('Enemies')
local loadedNPCs = workspace:FindFirstChild('NPCs')

local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local Data = Player:WaitForChild('Data')
local PlayerGui = Player:WaitForChild('PlayerGui')
local Backpack = Player:WaitForChild('Backpack')
local Main_ScreenGui = PlayerGui:FindFirstChild('Main')
local Quest = Main_ScreenGui:FindFirstChild('Quest')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Notification = require(ReplicatedStorage.Notification)
local storedNPCs = ReplicatedStorage:FindFirstChild('NPCs')
local Remotes = ReplicatedStorage:FindFirstChild('Remotes')
local Modules = ReplicatedStorage:FindFirstChild('Modules')
local FortBuilderReplicatedSpawnPositionsFolder = ReplicatedStorage:FindFirstChild('FortBuilderReplicatedSpawnPositionsFolder')
local CommF_ = Remotes:FindFirstChild('CommF_')
local Net = Modules:FindFirstChild('Net')
local RegisterAttack = Net:FindFirstChild('RE/RegisterAttack')
local RegisterHit = Net:FindFirstChild('RE/RegisterHit')

local VirtualUser = game:GetService('VirtualUser')

task.spawn(function()
    if getconnections then
        for _, connection in next, getconnections(Player.Idled) do
            connection:Disable()
        end
    end

    Player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

task.spawn(function()
    while task.wait() do
        local char = Player.Character or Player.CharacterAdded:Wait()
        for _, child in pairs(char:GetChildren()) do
            if (child:IsA('MeshPart') or child:IsA('Part')) and child.CanCollide then
                child.CanCollide = false
            end
        end
    end
end)

local function createNotification(text)
    local notification = Notification.new(text, 5)
    notification:Display()
end

local function getListBy(name)
    local list = {}

    for _, value in pairs(Import[name]) do
        table.insert(list, value)
    end

    return list
end

local function reverseGetListBy(name)
    local list = {}

    for key, _ in pairs(Import[name]) do
        table.insert(list, key)
    end

    return list
end

local Mobs = getListBy('Mobs')
local Islands = reverseGetListBy('Islands')

local function getClosestEnemy(target)
    local playerHRP = (Player.Character or Player.CharacterAdded:Wait()):WaitForChild('HumanoidRootPart')
    local shortestDistance = math.huge

    for _, container in ipairs{Enemies and Enemies:GetChildren() or {}, ReplicatedStorage:GetChildren()} do
        if #container == 0 then
            continue
        end

        for _, child in ipairs(container) do
            if child and child.Name == target and child:FindFirstChild('Humanoid') and child.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead and child:FindFirstChild('HumanoidRootPart') then
                local distance = CoreUtils.CalculateDistance(playerHRP.Position, child.HumanoidRootPart.Position)
                if distance < shortestDistance then
                    shortestDistance = distance
                end
            end
        end
    end

    for _, container in ipairs{Enemies and Enemies:GetChildren() or {}, ReplicatedStorage:GetChildren()} do
        if #container == 0 then
            continue
        end

        for _, child in ipairs(container) do
            if child and child.Name == target and child:FindFirstChild('Humanoid') and child.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead and child:FindFirstChild('HumanoidRootPart') then
                local distance = CoreUtils.CalculateDistance(playerHRP.Position, child.HumanoidRootPart.Position)
                if distance == shortestDistance then
                    return child
                end
            end
        end
    end
end

local function bringEnemies(name)
    local playerHRP = (Player.Character or Player.CharacterAdded:Wait()):WaitForChild('HumanoidRootPart')
    local containers = {Enemies, ReplicatedStorage}

    for _, container in ipairs(containers) do
        if container then
            for _, enemy in ipairs(container:GetChildren()) do
                if enemy.Name == name and enemy:FindFirstChild('HumanoidRootPart') then
                    local enemyHRP = enemy.HumanoidRootPart
                    local BodyPosition = Instance.new('BodyPosition')
                    BodyPosition.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    BodyPosition.P = 5000
                    BodyPosition.D = 200

                    BodyPosition.Position = playerHRP.Position - Vector3.new(0, 15, 0)
                    BodyPosition.Parent = enemyHRP

                    task.delay(0.5, function()
                        BodyPosition:Destroy()
                    end)
                end
            end
        end
    end
end

local function attackMob(target)
    local char = (Player.Character or Player.CharacterAdded:Wait())

    local WEAPON_MAPPING = {
        ['Melee'] = Options.meleeKeybinds.Value,
        ['Demon Fruit'] = Options.fruitKeybinds.Value
    }

    local function equipTool(weaponType)
        for _, child in pairs(char:GetChildren()) do
            if child:GetAttribute('WeaponType') == weaponType then
                return true
            end
        end

        for _, child in pairs(Backpack:GetChildren()) do
            if child:GetAttribute('WeaponType') == weaponType then
                child.Parent = char
                return true
            end
        end

        return false
    end

    local weaponType = Options.selectedWeapon.Value
    local skills = WEAPON_MAPPING[weaponType]

    if equipTool(weaponType) then
        for _, keybind in pairs(skills) do
            if keybind == 'M1' then
                local playerHRP = char:FindFirstChild('HumanoidRootPart')
                local targetEnemies = {}

                for _, container in ipairs{Enemies, ReplicatedStorage} do
                    if container then
                        for _, enemy in ipairs(container:GetChildren()) do
                            local enemyHRP = enemy:FindFirstChild('HumanoidRootPart')
                            local humanoid = enemy:FindFirstChild('Humanoid')

                            if enemyHRP and humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                                if enemy.Name == target and (playerHRP.Position - enemyHRP.Position).Magnitude <= 65 then
                                    table.insert(targetEnemies, {enemy.Name, enemyHRP})
                                end
                            end
                        end
                    end
                end

                if #targetEnemies > 0 then
                    for i = 1, #targetEnemies do
                        RegisterAttack:FireServer()
                        RegisterHit:FireServer(targetEnemies[i][2], targetEnemies)
                    end
                end
            end
        end
    end
end

local function getQuest(level)
    local team = Player.Team

    if team and level < 10 then
        if team.Name == 'Pirates' then
            return {name = 'BanditQuest1', index = 1, npc = 'Bandit Quest Giver', mob = 'Bandit', island = 'Windmill'}
        elseif team.Name == 'Marines' then
            return {name = 'MarineQuest', index = 1, npc = 'Marine Leader', mob = 'Trainee', island = 'MarineStarter'}
        end
    elseif level >= 10 and level < 15 then
        return {name = 'JungleQuest', index = 1, npc = 'Adventurer', mob = 'Monkey', island = 'Jungle'}
    elseif level >= 15 and level < 20 then
        return {name = 'JungleQuest', index = 2, npc = 'Adventurer', mob = 'Gorilla', island = 'Jungle'}
    elseif level >= 20 and level < 30 then
        return {name = 'JungleQuest', index = 3, npc = 'Adventurer', mob = 'Great Gorilla King', island = 'Jungle'}
    elseif level >= 30 and level < 40 then
        return {name = 'BuggyQuest1', index = 1, npc = 'Pirate Adventurer', mob = 'Pirate', island = 'Pirate'}
    elseif level >= 40 and level < 55 then
        return {name = 'BuggyQuest1', index = 2, npc = 'Pirate Adventurer', mob = 'Brute', island = 'Pirate'}
    elseif level >= 55 and level < 60 then
        return {name = 'BuggyQuest1', index = 3, npc = 'Pirate Adventurer', mob = 'Chef', island = 'Pirate'}
    elseif level >= 60 and level < 75 then
        return {name = 'DesertQuest', index = 1, npc = 'Desert Adventurer', mob = 'Desert Bandit', island = 'Desert'}
    elseif level >= 75 and level < 90 then
        return {name = 'DesertQuest', index = 2, npc = 'Desert Adventurer', mob = 'Desert Officer', island = 'Desert'}
    elseif level >= 90 and level < 100 then
        return {name = 'SnowQuest', index = 1, npc = 'Villager', mob = 'Snow Bandit', island = 'Ice'}
    elseif level >= 100 and level < 105 then
        return {name = 'SnowQuest', index = 2, npc = 'Villager', mob = 'Snowman', island = 'Ice'}
    elseif level >= 105 and level < 120 then
        return {name = 'SnowQuest', index = 3, npc = 'Villager', mob = 'Yeti', island = 'Ice'}
    end
end

local function autoFarm(target, method)
    if method == 'Normal' then
        local mob = getClosestEnemy(target)
        if mob and mob:FindFirstChild('HumanoidRootPart') then
            CoreUtils.TweenTo(Player, CFrame.new(mob.HumanoidRootPart.Position + Vector3.new(0, 15, 0)), Options.tweenSpeed.Value)
        end
    elseif method == 'Level' then
        local quest = getQuest(Data:WaitForChild('Level').Value)
        if quest then
            local mob = getClosestEnemy(quest.mob)
            if (Player:GetAttribute('CurrentLocation') or '') ~= Import.Islands[quest.island]
                or (Player:GetAttribute('ExactLocation') or '') ~= Import.Islands[quest.island] then

                while (Player:GetAttribute('CurrentLocation') or '') ~= Import.Islands[quest.island]
                    or (Player:GetAttribute('ExactLocation') or '') ~= Import.Islands[quest.island] do

                    CoreUtils.TweenTo(Player, (loadedNPCs:FindFirstChild(quest.npc) or storedNPCs:FindFirstChild(quest.npc)):GetPivot(), Options.tweenSpeed.Value)
                    task.wait()
                end
            end

            if Quest and not Quest.Visible then
                CommF_:InvokeServer('StartQuest', quest.name, quest.index)
            end

            local function getClosestEnemySpawn(name)
                local playerHRP = (Player.Character or Player.CharacterAdded:Wait()):WaitForChild('HumanoidRootPart')
                local closestSpawn, shortestDistance = nil, math.huge

                for _, child in pairs(FortBuilderReplicatedSpawnPositionsFolder:GetChildren()) do
                    if child.Name:find('^' .. name) then
                        local distance = CoreUtils.CalculateDistance(playerHRP.Position, child.Position)
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestSpawn = child
                        end
                    end
                end

                return closestSpawn and closestSpawn.Position or nil
            end

            local enemySpawn = getClosestEnemySpawn(quest.mob)
            if enemySpawn then
                CoreUtils.TweenTo(Player, CFrame.new(enemySpawn + Vector3.new(0, 15, 0)), Options.tweenSpeed.Value)
            end

            if mob and mob:FindFirstChild('HumanoidRootPart') then
                bringEnemies(quest.mob)
                task.wait()
                attackMob(quest.mob)
            end
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    local char = (Player.Character or Player.CharacterAdded:Wait())
    if char:GetAttribute('WaterWalking') and child.Name:lower() == 'ice' then
        child.Transparency = 1
    end
end)

local Window = Quake:Window({
    Title = 'Project Madara | Blox Fruits'
})

local Main = Window:Tab({
    Name = 'Main',
    Image = 'rbxassetid://111517370830089'
})

Toggles.autoFarm = Main:Toggle({
    Name = 'Auto Farm',
    Default = false,
    Callback = function(...)
        if Toggles.autoFarm.Value then
            while Toggles.autoFarm.Value do
                if not Options.farmingMethod.Value or Options.farmingMethod.Value == '' then
                    Toggles.autoFarm.Value = false
                    createNotification('<Color=Red>Please select a method for farming!<Color=/>')
                    return
                end

                if Options.farmingMethod.Value ~= 'Level' then
                    if not Options.pickedMob.Value or Options.pickedMob.Value == '' then
                        Toggles.autoFarm.Value = false
                        createNotification('<Color=Red>Please select a mob!<Color=/>')
                        return
                    end
                end

                if not Options.selectedWeapon.Value or Options.selectedWeapon.Value == ''then
                    Toggles.autoFarm.Value = false
                    createNotification('<Color=Red>Please select a weapon for farming!<Color=/>')
                    return
                end

                local quest = getQuest(Data:WaitForChild('Level').Value)
                autoFarm((Options.pickedMob.Value or quest.mob), Options.farmingMethod.Value)
                task.wait()
            end

            if Player.Character:WaitForChild('HumanoidRootPart') and Player.Character.HumanoidRootPart:FindFirstChild('Anchor') then
                CoreUtils.DestroyAnchor(Player.Character.HumanoidRootPart)
            end
        end
    end
})

Options.farmingMethod = Main:Dropdown({
    Name = 'Method',
    Items = {'Normal', 'Level'},
    Default = 'Level',
    Callback = function(...) end
})

Options.pickedMob = Main:Dropdown({
    Name = 'Mobs',
    Items = Mobs,
    Default = '',
    Callback = function(...) end
})

Options.tweenSpeed = Main:Slider({
    Name = 'Tween Speed',
    Min = 0,
    Max = 500,
    InitialValue = 250,
    Callback = function(...) end
})

local Skills = Main:Group({
    Name = 'Skills',
})

Options.selectedWeapon = Skills:Dropdown({
    Name = 'Selected Weapon',
    Items = {'Melee', 'Demon Fruit'},
    Default = 'Melee',
    Callback = function(...) end
})

Options.meleeKeybinds = Skills:Dropdown({
    Name = 'Melee Skills',
    Items = {'M1', 'Z', 'X', 'C', 'V', 'F'},
    Default = {},
    Multiselect = true,
    Callback = function(...) end
})

Options.fruitKeybinds = Skills:Dropdown({
    Name = 'Fruit Skills',
    Items = {'M1', 'Z', 'X', 'C', 'V', 'F'},
    Default = {},
    Multiselect = true,
    Callback = function(...) end
})

local Settings = Window:Tab({
    Name = 'Settings',
    Image = 'rbxassetid://114378385784521'
})

Toggles.enableWaterWalking = Settings:Toggle({
    Name = 'Enable Water Walking',
    Default = false,
    Callback = function(...)
        if Toggles.enableWaterWalking.Value then
            while Toggles.enableWaterWalking.Value do
                local char = (Player.Character or Player.CharacterAdded:Wait())
                if not char:GetAttribute('WaterWalking') then
                    char:SetAttribute('WaterWalking', true)
                end

                task.wait()
            end
        end
    end
})