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
local Map = workspace:FindFirstChild('Map')
local loadedNPCs = workspace:FindFirstChild('NPCs')

local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local Data = Player:WaitForChild('Data')
local PlayerGui = Player:WaitForChild('PlayerGui')
local Main_ScreenGui = PlayerGui:FindFirstChild('Main')
local Quest = Main_ScreenGui:FindFirstChild('Quest')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Notification = require(ReplicatedStorage.Notification)
local Quests = require(ReplicatedStorage.Quests)
local Remotes = ReplicatedStorage:FindFirstChild('Remotes')
local CommF_ = Remotes:FindFirstChild('CommF_')
local storedNPCs = ReplicatedStorage:FindFirstChild('NPCs')

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

local function attackMob(target)

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
    end
end

local function autoFarm(target, method)
    if method == 'Normal' then
        local mob = getClosestEnemy(target)
        if mob and mob:FindFirstChild('HumanoidRootPart') then
            CoreUtils.TweenTo(Player, CFrame.new(mob.HumanoidRootPart.Position + Vector3.new(0, 10, 0)), Options.tweenSpeed.Value)
        end

    elseif method == 'Level' then
        local quest = getQuest(Data:WaitForChild('Level').Value)
        if quest then
            if (Player:GetAttribute('CurrentLocation') or '') ~= Import.Islands[quest.island]
                or (Player:GetAttribute('ExactLocation') or '') ~= Import.Islands[quest.island] then

                while (Player:GetAttribute('CurrentLocation') or '') ~= Import.Islands[quest.island]
                    or (Player:GetAttribute('ExactLocation') or '') ~= Import.Islands[quest.island] do

                    CoreUtils.TweenTo(Player, Map[quest.island]:GetPivot(), Options.tweenSpeed.Value)
                    task.wait()
                end
            end

            if Quest and not Quest.Visible then
                CommF_:InvokeServer('StartQuest', quest.name, quest.index)
            end

            attackMob(getClosestEnemy(quest.mob))
        end
    end
end

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
    Default = '',
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

Options.meleeKeybinds = Skills:Dropdown({
    Name = 'Melee Skills',
    Items = {'M1', 'Z', 'X', 'C', 'V', 'F'},
    Default = '',
    Multiselect = true,
    Callback = function(values)
        if #values > 0 then
            Options.fruitKeybinds.Value = {}
        end
    end
})

Options.fruitKeybinds = Skills:Dropdown({
    Name = 'Fruit Skills',
    Items = {'M1', 'Z', 'X', 'C', 'V', 'F'},
    Default = '',
    Multiselect = true,
    Callback = function(values)
        if #values > 0 then
            Options.meleeKeybinds.Value = {}
        end
    end
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