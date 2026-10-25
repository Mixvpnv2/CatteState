---@diagnostic disable: undefined-global, deprecated, undefined-field

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Camera = cloneref(game:GetService("Workspace").CurrentCamera)
local SoundService = cloneref(game:GetService("SoundService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))
local workspace = cloneref(game:GetService("Workspace"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Stats = cloneref(game:GetService("Stats"))
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local CFrameNew = CFrame.new
local _CFramenew = CFrame.new
local _IsDescendantOf = game.IsDescendantOf
local _FindFirstChild = game.FindFirstChild
local _FindFirstChildOfClass = game.FindFirstChildOfClass
local _Raycast = workspace.Raycast

--Risky = true, Tooltip = 'Risky',

local g = getinfo or debug.getinfo
local d = false
local h = {}

local x, y

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
    
        if typeof(a) == "function" and not x then
            x = a
            
            local o; o = hookfunction(x, function(c, f, n)
                if c ~= "_" then
                    if d then
                        warn(`Adonis AntiCheat flagged\nMethod: {c}\nInfo: {f}`)
                    end
                end
                
                return true
            end)

            table.insert(h, x)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f)
                if d then
                    warn(`Adonis AntiCheat tried to kill (fallback): {f}`)
                end
            end)

            table.insert(h, y)
        end
    end
end

local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...

    if x and a == x then
        if d then
            warn(`zins | adonis bypassed`)
        end

        return coroutine.yield(coroutine.running())
    end
    
    return o(...)
end))

setthreadidentity(7)

warn("Loaded")
local repo = 'https://raw.githubusercontent.com/Mixvpnv2/ProtogenLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({

    Title = 'CatteState Universal',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.15
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Player = Window:AddTab('Player'),
    Misc = Window:AddTab('Misc'),
    Visuals = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local Combat = Tabs.Combat:AddLeftGroupbox('Combat')
local VisualCombat = Tabs.Combat:AddRightGroupbox('VisualCombat')

local AimBotEnabled = false
local WallCheckEnabled = false
local TeamCheckEnabled = false
local AimSmooth = 1
local TargetPartSetting = "Head"

local IsHoldingKey = false
local AimKey = Enum.UserInputType.MouseButton2
local FOVRadius = 100 
local FOVNumSides = 64
local FOVVisible = true

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.new(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

local function updateFOV()
    local currentCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
    if currentCamera and FOVVisible and AimBotEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        FOVCircle.Radius = FOVRadius
        FOVCircle.NumSides = FOVNumSides
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end

local function isVisible(targetPart, character)
    if not WallCheckEnabled then return true end
    
    local currentCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
    if not currentCamera then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.IgnoreWater = true

    local origin = currentCamera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)

    return raycastResult == nil
end

local function getTargetPart(character)
    if TargetPartSetting == "Head" then
        return character:FindFirstChild("Head")
    elseif TargetPartSetting == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif TargetPartSetting == "All" then
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local currentCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
    if not currentCamera then return nil end

    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if TeamCheckEnabled and player.Team == LocalPlayer.Team and player.Team ~= nil then 
                continue 
            end

            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                
                local targetPart = getTargetPart(player.Character)
                if targetPart then
                    local screenPos, onScreen = currentCamera:WorldToViewportPoint(targetPart.Position)
                    
                    if onScreen then
                        local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        if magnitude <= FOVRadius and magnitude < shortestDistance then
                            if isVisible(targetPart, player.Character) then
                                shortestDistance = magnitude
                                closestPlayer = player
                            end
                        end
                    end
                end

            end
        end
    end
    return closestPlayer
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == AimKey then
        IsHoldingKey = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimKey then
        IsHoldingKey = false
    end
end)

RunService.RenderStepped:Connect(function()
    updateFOV() 
    
    if not AimBotEnabled or not IsHoldingKey then return end

    local currentCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
    if not currentCamera then return end

    local targetPlayer = getClosestPlayerInFOV()
    if targetPlayer and targetPlayer.Character then
        local targetPart = getTargetPart(targetPlayer.Character)
        if targetPart then
            local targetPos = targetPart.Position
            local currentCFrame = currentCamera.CFrame
            local targetCFrame = CFrame.new(currentCamera.CFrame.Position, targetPos)
            currentCamera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / (AimSmooth * 2))
        end
    end
end)

Combat:AddToggle('AimnBot', { 
    Text = 'Aim Assist', 
    Default = false, 
    Callback = function(Value) AimBotEnabled = Value end 
})

Combat:AddToggle('WallCheck', { 
    Text = 'Wall Check', 
    Default = false, 
    Callback = function(Value) WallCheckEnabled = Value end 
})

Combat:AddToggle('TeamCheck', { 
    Text = 'Team Check', 
    Default = false, 
    Callback = function(Value) TeamCheckEnabled = Value end 
})

Combat:AddSlider('AimnBotSmooth', { 
    Text = 'AimnBot Smooth', 
    Default = 1, Min = 1, Max = 30, Rounding = 1, Compact = false,   --Suffix = "",
    Callback = function(Value) AimSmooth = Value end 
})

Combat:AddDropdown('AimBotPart', { 
    Values = { 'Head', 'Torso', 'All' }, 
    Default = 1, Multi = false, Text = 'Target Part', 
    Callback = function(Value) TargetPartSetting = Value end 
})

Combat:AddToggle('AimBotFOVVisible', { 
    Text = 'Show FOV Circle', 
    Default = true, 
    Callback = function(Value) FOVVisible = Value end 
})

Combat:AddSlider('AimBotFOVRadius', { 
    Text = 'FOV Size', 
    Default = 100, Min = 10, Max = 500, Rounding = 0, Compact = false, 
    Callback = function(Value) FOVRadius = Value end 
})

Combat:AddSlider('AimBotFOVNumSides', { 
    Text = 'FOV NumSides', 
    Default = 64, Min = 2, Max = 64, Rounding = 0, Compact = false, 
    Callback = function(Value) FOVNumSides = Value end 
})

Combat:AddLabel('Color'):AddColorPicker('ColorPicker', {
    Default = Color3.new(255, 255, 255), 
    Title = 'Some color', 
    Transparency = 0, 
    Callback = function(Value)
        FOVCircle.Color = Value 
    end
})

local Humanoid = Tabs.Player:AddLeftGroupbox('LocalPlayer')
local Character = Tabs.Player:AddRightGroupbox('Character')

local DisguiseActive = false
local DisguiseUserId = ""
local HeadHideActive = false

local disguiseConnection = nil
local charConnections = {}
local cloned = {}
local heartbeatConnection = nil 
local currentDisguiseToken = 0

local function notify(title, text, duration)

end

local function cleanCharConnections()
    for _, conn in pairs(charConnections) do
        if conn then conn:Disconnect() end
    end
    charConnections = {}
end

local function removeDisguiseItems(character)
    if not character then return end
    
    for _, v in pairs(character:GetChildren()) do
        if v:GetAttribute("Disguise") or v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
            v:Destroy()
        end
    end
    
    for _, v in pairs(character:GetDescendants()) do
        if v:GetAttribute("Disguise") then
            v:Destroy()
        end
    end
end

local function itemAdded(obj, manual)
    if not DisguiseActive then return end
    if cloned[obj] or obj:GetAttribute("Disguise") then return end 

    if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
        obj:ClearAllChildren()
        task.defer(obj.Destroy, obj)
        return
    end

    if obj:IsA("Accessory") or manual then
        task.defer(function()
            if obj and obj.Parent and not cloned[obj] and not obj:GetAttribute("Disguise") then
                obj:ClearAllChildren()
                obj:Destroy()
            end
        end)
        return
    end
end

local function applyDisguise(character)
    if not DisguiseActive or not character or not character.Parent then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    currentDisguiseToken = currentDisguiseToken + 1
    local myToken = currentDisguiseToken

    table.clear(cloned)
    removeDisguiseItems(character)

    local targetId = (DisguiseUserId == "" and 172570441) or tonumber(DisguiseUserId)
    if not targetId then return end

    local success, description = pcall(function()
        return game:GetService("Players"):GetHumanoidDescriptionFromUserIdAsync(targetId)
    end)

    if myToken ~= currentDisguiseToken then 
        if description then description:Destroy() end
        return 
    end

    if not success or not description then
        notify("Disguise", "Err ID", 3)
        return
    end

    if not DisguiseActive then
        description:Destroy()
        return
    end

    character.Archivable = true
    local clone = character:Clone()
    clone.Parent = game

    local originalDescription = humanoid:FindFirstChildOfClass('HumanoidDescription') or { HeightScale = 1 }
    description.HeightScale = originalDescription.HeightScale

    local applySuccess = false
    for i = 1, 3 do
        if myToken ~= currentDisguiseToken then break end

        applySuccess = pcall(function()
            clone:FindFirstChildOfClass('Humanoid'):ApplyDescriptionResetAsync(description)
        end)
        
        if applySuccess and clone:FindFirstChildOfClass("Accessory") then
            break
        end
        task.wait(0.1)
    end

    if myToken ~= currentDisguiseToken or not applySuccess then
        clone:Destroy()
        description:Destroy()
        return
    end

    cleanCharConnections()
    charConnections.ItemAdded = character.DescendantAdded:Connect(itemAdded)

    for _, obj in character:GetDescendants() do
        itemAdded(obj)
    end

    for _, obj in clone:GetChildren() do
        if myToken ~= currentDisguiseToken then break end

        if obj:IsA('Accessory') then
            cloned[obj] = true
            obj:SetAttribute("Disguise", true)

            for _, objd in obj:GetDescendants() do
                if objd:IsA('Weld') and objd.Part1 then
                    objd.Part1 = character:FindFirstChild(objd.Part1.Name)
                elseif objd:IsA('RigidConstraint') and objd.Attachment1 then
                    objd.Attachment1 = character:FindFirstChild(objd.Attachment1.Name, true)
                end
            end
            
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                handle.CanQuery = false
                handle.CanTouch = false
            end

            if obj.ClassName == "Accessory" and (obj:FindFirstChild("FaceFrontAttachment", true) or obj.Name:lower():find("face") or obj.Name:lower():find("ear")) then
                local realHead = character:FindFirstChild("Head")
                if realHead then
                    obj.Parent = realHead
                else
                    obj.Parent = character
                end
            else
                obj.Parent = character
            end
            
        elseif obj:IsA('Shirt') or obj:IsA('Pants') or obj:IsA('ShirtGraphic') or obj:IsA('BodyColors') then
            cloned[obj] = true
            obj:SetAttribute("Disguise", true)
            obj.Parent = character
            
            if obj:IsA("Shirt") or obj:IsA("Pants") then
                local propertyName = obj:IsA("Shirt") and "ShirtTemplate" or "PantsTemplate"
                local originalTemplate = obj[propertyName]

                local connection
                connection = obj:GetPropertyChangedSignal(propertyName):Connect(function()
                    if DisguiseActive and obj and obj.Parent then
                        obj[propertyName] = originalTemplate
                    else
                        if connection then connection:Disconnect() end
                    end
                end)
                
                table.insert(charConnections, connection)
            end
        end
    end

    description:Destroy()
    clone:ClearAllChildren()
    clone:Destroy()
end

local function onCharacterAdded(character)
    if not DisguiseActive then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if character and character.Parent and humanoid then
        task.wait(0.8)
        if character and character.Parent then
            applyDisguise(character)
        end
    end
end

local function startLoopUpdate()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    
    heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local lPlayer = game:GetService("Players").LocalPlayer
        if not lPlayer or not lPlayer.Character then return end
        local char = lPlayer.Character
        
        if HeadHideActive then
            local head = char:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                if head.Transparency ~= 1 then
                    head.Transparency = 1
                end
                
                local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
                if face and face.Transparency ~= 1 then
                    face.Transparency = 1
                end
            end
        end
        
        if DisguiseActive then
            for _, obj in pairs(char:GetChildren()) do
                if (obj:IsA("Shirt") or obj:IsA("Pants")) and not cloned[obj] and not obj:GetAttribute("Disguise") then
                    obj:Destroy()
                end
            end
        end
    end)
end

Character:AddToggle('DisguiseToggle', {
    Text = 'Disguise',
    Default = false,
    Callback = function(Value)
        DisguiseActive = Value

        if Value then
            local lPlayer = game:GetService("Players").LocalPlayer
            if lPlayer and lPlayer.Character then
                applyDisguise(lPlayer.Character)
            end
            disguiseConnection = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
            startLoopUpdate()
            notify("Disguise", "Enabled", 2)
        else
            cleanCharConnections()
            if disguiseConnection then
                disguiseConnection:Disconnect()
                disguiseConnection = nil
            end
            if heartbeatConnection and not HeadHideActive then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
            table.clear(cloned)
            local lPlayer = game:GetService("Players").LocalPlayer
            if lPlayer and lPlayer.Character then
                removeDisguiseItems(lPlayer.Character)
            end
            notify("Disguise", "Disabled", 2)
        end
    end
})

Character:AddInput('DisguiseUserId', {
    Text = 'User ID',
    Placeholder = 'Id User',
    Default = '',
    Callback = function(Value)
        DisguiseUserId = Value
        if DisguiseActive then
            local lPlayer = game:GetService("Players").LocalPlayer
            if lPlayer and lPlayer.Character then
                applyDisguise(lPlayer.Character)
            end
        end
    end
})

Character:AddToggle('HeadPartHideToggle', {
    Text = 'Head Part Hide',
    Default = false,
    Callback = function(Value)
        HeadHideActive = Value
        
        if lPlayer and lPlayer.Character then
            local head = lPlayer.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                head.Transparency = Value and 1 or 0
                
                local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
                if face then
                    face.Transparency = Value and 1 or 0
                end
            end
        end
        
        if Value or DisguiseActive then
            startLoopUpdate()
        elseif heartbeatConnection and not DisguiseActive and not Value then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end 
})

Character:AddToggle('Notify', {
    Text = 'Test Library Notify',
    Default = false,
    Callback = function(v)
        if Library and Library.Notify then
            if v then
                Library:Notify("TESTTESTTESTTESTTESTTESTTESTTESTTESTTEST", 5)
            else
                Library:Notify("DISABLEDDISABLEDDISABLEDDISABLEDDISABLED", 5)
            end
        end
    end
})

local Mode = Tabs.Player:AddRightGroupbox('Idk')

local Fly = false
local FlySpeed = 10
local FlyMethod = "BodyVelocity"
local FLYING = false

local flyConn = nil
local keyDownConn = nil
local keyUpConn = nil
local charConn = nil
local JesusConnection
local JesusPlate
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}

local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function cleanupBodyMovers(root)
    if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v.Name == "FlyBV" or v.Name == "FlyBG" then
            v:Destroy()
        end
    end
end

function NOFLY()
    FLYING = false
    Fly = false

    if flyConn then flyConn:Disconnect() flyConn = nil end
    if keyDownConn then keyDownConn:Disconnect() keyDownConn = nil end
    if keyUpConn then keyUpConn:Disconnect() keyUpConn = nil end

    CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        cleanupBodyMovers(getRoot(char))
    end
end

local function getMoveVector(cam)
    local move = Vector3.zero
    if CONTROL.F ~= 0 or CONTROL.B ~= 0 then
        move = move + cam.CFrame.LookVector * (CONTROL.F + CONTROL.B)
    end
    if CONTROL.L ~= 0 or CONTROL.R ~= 0 then
        move = move + cam.CFrame.RightVector * (CONTROL.L + CONTROL.R)
    end
    if CONTROL.Q ~= 0 or CONTROL.E ~= 0 then
        move = move + Vector3.new(0, CONTROL.Q + CONTROL.E, 0)
    end
    if move.Magnitude > 0 then
        return move.Unit
    end
    return Vector3.zero
end

function sFLY()
    NOFLY()
    Fly = true
    FLYING = true

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid", 5)
    local root = getRoot(char)
    if not humanoid or not root then
        NOFLY()
        return
    end

    cleanupBodyMovers(root)

    local BG, BV
    if FlyMethod == "BodyVelocity" then
        BG = Instance.new("BodyGyro")
        BG.Name = "FlyBG"
        BG.P = 9e4
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = root.CFrame
        BG.Parent = root

        BV = Instance.new("BodyVelocity")
        BV.Name = "FlyBV"
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        BV.Velocity = Vector3.zero
        BV.Parent = root
    end

    humanoid.PlatformStand = true

    keyDownConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not FLYING then return end
        local k = input.KeyCode
        if k == Enum.KeyCode.W then CONTROL.F = 1
        elseif k == Enum.KeyCode.S then CONTROL.B = -1
        elseif k == Enum.KeyCode.A then CONTROL.L = -1
        elseif k == Enum.KeyCode.D then CONTROL.R = 1
        elseif k == Enum.KeyCode.E then CONTROL.Q = 1
        elseif k == Enum.KeyCode.Q then CONTROL.E = -1
        end
    end)

    keyUpConn = UserInputService.InputEnded:Connect(function(input)
        local k = input.KeyCode
        if k == Enum.KeyCode.W then CONTROL.F = 0
        elseif k == Enum.KeyCode.S then CONTROL.B = 0
        elseif k == Enum.KeyCode.A then CONTROL.L = 0
        elseif k == Enum.KeyCode.D then CONTROL.R = 0
        elseif k == Enum.KeyCode.E then CONTROL.Q = 0
        elseif k == Enum.KeyCode.Q then CONTROL.E = 0
        end
    end)

    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not FLYING then return end

        char = LocalPlayer.Character
        humanoid = char and char:FindFirstChildOfClass("Humanoid")
        root = getRoot(char)
        if not char or not humanoid or not root then
            NOFLY()
            return
        end

        humanoid.PlatformStand = true
        local cam = workspace.CurrentCamera
        local dir = getMoveVector(cam)
        local speed = FlySpeed

        if FlyMethod == "CFrame" then
            if dir.Magnitude > 0 then
                root.CFrame = root.CFrame + dir * speed * dt * 3
            end
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)

        elseif FlyMethod == "Velocity" then
            if dir.Magnitude > 0 then
                root.AssemblyLinearVelocity = dir * speed * 3
            else
                root.AssemblyLinearVelocity = Vector3.zero
            end

        elseif FlyMethod == "BodyVelocity" then
            if not BV or not BV.Parent or not BG or not BG.Parent then
                NOFLY()
                return
            end
            if dir.Magnitude > 0 then
                BV.Velocity = dir * speed
            else
                BV.Velocity = Vector3.zero
            end
            BG.CFrame = cam.CFrame
        end
    end)
end

if charConn then charConn:Disconnect() end
charConn = LocalPlayer.CharacterAdded:Connect(function()
    if Fly then
        task.wait(0.5)
        if Fly then sFLY() end
    end
end)

Mode:AddToggle('Fly', {
    Text = 'Fly',
    Default = false,
    Risky = true,
    Tooltip = 'Risky',
    Callback = function(Value)
        if Value then sFLY() else NOFLY() end
    end
})

Mode:AddDropdown('FlyMethod', {
    Text = 'Fly Method',
    Values = {'CFrame', 'Velocity', 'BodyVelocity'},
    Default = 3,
    Multi = false,
    Callback = function(Value)
        FlyMethod = Value
        if Fly then
            sFLY()
        end
    end
})

Mode:AddLabel('FlyKeybind'):AddKeyPicker('FlyKey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Fly',
    Callback = function(Value)
        if Value then sFLY() else NOFLY() end
    end
})

Mode:AddSlider('FlySpeed', {
    Text = 'Fly Speed',
    Default = 10,
    Min = 0,
    Max = 40,
    Rounding = 1,
    Callback = function(Value)
        FlySpeed = Value
    end
})

local states = {}
for _, v in Enum.HumanoidStateType:GetEnumItems() do
    if v.Name ~= 'None' then
        table.insert(states, v.Name)
    end
end

local HumSpooferConnection

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

Mode:AddToggle('HumSpooferToggle', {
    Text = 'Enable HumSpoofer',
    Default = false,
    Risky = true,
    Tooltip = 'Risky',
    Callback = function(Value)
        if Value then
            if HumSpooferConnection then HumSpooferConnection:Disconnect() end
            
            HumSpooferConnection = RunService.Heartbeat:Connect(function()
                local hum = getHumanoid()
                if hum then
                    local selectedState = Options.HumStateDropdown.Value
                    if selectedState and Enum.HumanoidStateType[selectedState] then
                        sethiddenproperty(hum, 'NetworkHumanoidState', Enum.HumanoidStateType[selectedState].Value)
                    end

                    if Toggles.ReplaceJumpToggle.Value then
                        sethiddenproperty(hum, 'JumpReplicate', Toggles.JumpStateToggle.Value)
                    end
                end
            end)
        else
            if HumSpooferConnection then
                HumSpooferConnection:Disconnect()
                HumSpooferConnection = nil
            end
        end
    end
})

Mode:AddDropdown('HumStateDropdown', {
    Values = states,
    Default = 1,
    Multi = false,
    Text = 'Humanoid State',
    Tooltip = 'Select which state to spoof on the server',
    Callback = function(Value) end
})

Mode:AddToggle('ReplaceJumpToggle', {
    Text = 'Replace Jump',
    Default = false,
    Tooltip = 'Replace the current jump state on the server',
    Callback = function(Value) end
})

local JumpDepbox = Mode:AddDependencyBox()

JumpDepbox:AddToggle('JumpStateToggle', {
    Text = 'Jump State',
    Default = false,
    Tooltip = 'Force jump state on server',
    Callback = function(Value) end
})

JumpDepbox:SetupDependencies({
    { Toggles.ReplaceJumpToggle, true }
})




Mode:AddToggle('Jesus', {
    Text = 'Jesus',
    Default = false,
    Callback = function(Value)
        if Value then
            if JesusConnection then JesusConnection:Disconnect() end
            if JesusPlate then JesusPlate:Destroy() end

            local player = game:GetService("Players").LocalPlayer
            local runService = game:GetService("RunService")
            local terrain = workspace:FindFirstChildWhichIsA('Terrain')
            
            params.FilterDescendantsInstances = {terrain}

            JesusPlate = Instance.new('Part')
            JesusPlate.CanQuery = false
            JesusPlate.CanTouch = false
            JesusPlate.Anchored = true
            JesusPlate.Size = Vector3.new(6, 1, 6)
            JesusPlate.Transparency = 1
            JesusPlate.Parent = workspace

            JesusConnection = runService.PreSimulation:Connect(function()
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                
                if root and humanoid and JesusPlate then
                    local raycastResult = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
                    
                    if raycastResult and raycastResult.Material == Enum.Material.Water then
                        JesusPlate.CFrame = CFrame.new(raycastResult.Position - Vector3.new(0, 0.5, 0))
                    else
                        JesusPlate.CFrame = CFrame.new(10000, 10000, 10000)
                    end
                else
                    if JesusConnection then JesusConnection:Disconnect() end
                    if JesusPlate then JesusPlate:Destroy() end
                end
            end)
        else
            if JesusConnection then
                JesusConnection:Disconnect()
                JesusConnection = nil
            end
            if JesusPlate then
                JesusPlate:Destroy()
                JesusPlate = nil
            end
        end
    end
})

Tabs.lol = {
    toggles = { WalkSpeed = false, JumpPower = false, JumpHeight = false, HipHeight = false, MaxSlopeAngle = false },
    sliders = { WalkSpeed = 16, JumpPower = 40, JumpHeight = 7.2, HipHeight = 2, MaxSlopeAngle = 58, TPWalkSpeed = 2 }
}

local TPWalkConnection
local Data = Tabs.lol

RunService.PreSimulation:Connect(function()
    if LocalPlayer.Character then
        local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            if Data.toggles.WalkSpeed then
                Humanoid.WalkSpeed = Data.sliders.WalkSpeed
            end

            if Data.toggles.JumpPower then
                Humanoid.JumpPower = Data.sliders.JumpPower
            end

            if Data.toggles.JumpHeight then
                Humanoid.JumpHeight = Data.sliders.JumpHeight
            end

            if Data.toggles.HipHeight then
                Humanoid.HipHeight = Data.sliders.HipHeight
            end

            if Data.toggles.MaxSlopeAngle then
                Humanoid.MaxSlopeAngle = Data.sliders.MaxSlopeAngle
            end
        end
    end
end)


Humanoid:AddToggle('WalkSpeedToggle', {
    Text = 'WalkSpeed', Default = false, Risky = true, Tooltip = 'Risky',
    Callback = function(v) Data.toggles.WalkSpeed = v end
})

Humanoid:AddToggle('JumpPowerToggle', {
    Text = 'JumpPower', Default = false, Risky = true, Tooltip = 'Risky',
    Callback = function(v) Data.toggles.JumpPower = v end
})

Humanoid:AddToggle('JumpHeightToggle', {
    Text = 'JumpHeight', Default = false, Risky = true, Tooltip = 'Risky',
    Callback = function(v) Data.toggles.JumpHeight = v end
})

Humanoid:AddToggle('HipHeightToggle', {
    Text = 'HipHeight', Default = false, Risky = true, Tooltip = 'Risky',
    Callback = function(v) Data.toggles.HipHeight = v end
})

Humanoid:AddToggle('MaxSlopeAngleToggle', {
    Text = 'MaxSlopeAngle', Default = false, Risky = true, Tooltip = 'Risky',
    Callback = function(v) Data.toggles.MaxSlopeAngle = v end
})

Humanoid:AddSlider('WalkSpeed', {
    Text = 'WalkSpeed', Default = 16, Min = 1, Max = 100, Rounding = 1, Suffix = "",
    Callback = function(v) Data.sliders.WalkSpeed = v end
})

Humanoid:AddSlider('JumpPower', {
    Text = 'JumpPower', Default = 40, Min = 30, Max = 120, Rounding = 1,  -- Suffix = "",
    Callback = function(v) Data.sliders.JumpPower = v end
})

Humanoid:AddSlider('JumpHeight', {
    Text = 'JumpHeight', Default = 7.2, Min = 3.5, Max = 100, Rounding = 1,  -- Suffix = "",
    Callback = function(v) Data.sliders.JumpHeight = v end
})

Humanoid:AddSlider('HipHeightS', {
    Text = 'HipHeight', Default = 2, Min = 0, Max = 6.3, Rounding = 1, Suffix = "",
    Callback = function(v) Data.sliders.HipHeight = v end
})

Humanoid:AddSlider('MaxSlopeAngleS', {
    Text = 'MaxSlopeAngle', Default = 58, Min = 1, Max = 90, Rounding = 1, Suffix = "",
    Callback = function(v) Data.sliders.MaxSlopeAngle = v end
})

Humanoid:AddToggle('MoveDirection', {
    Text = 'MoveDirection',
    Default = false,
    Callback = function(v)
        if v then
            if TPWalkConnection then TPWalkConnection:Disconnect() end
            
            TPWalkConnection = RunService.Heartbeat:Connect(function(delta)
                if LocalPlayer and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                        LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * Data.sliders.TPWalkSpeed * delta * 10)
                    end
                end
            end)
        else
            if TPWalkConnection then
                TPWalkConnection:Disconnect()
                TPWalkConnection = nil
            end
        end
    end
})

Humanoid:AddSlider('MoveDirectionSpeed', {
    Text = 'MoveDirection Speed',
    Default = 2,
    Min = 1,
    Max = 50,
    Rounding = 1, 
    Suffix = "",
    Callback = function(v)
        Data.sliders.TPWalkSpeed = v
    end
})




local Misc = Tabs.Misc:AddLeftGroupbox('Client')
local MiscServer = Tabs.Misc:AddLeftGroupbox('Server')


local infJumpConnection = nil
local infJumpDebounce = false

Misc:AddToggle('InfJump', {
    Text = 'Infjump',
    Default = false,  
    Risky = true,
    Tooltip = 'Risky',

    Callback = function(state)
        if state then
            if infJumpConnection then 
                infJumpConnection:Disconnect() 
            end
            
            infJumpDebounce = false
            
            infJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                local player = game.Players.LocalPlayer
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and not infJumpDebounce then
                    infJumpDebounce = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait() 
                    infJumpDebounce = false
                end
            end)
        else
            if infJumpConnection then
                infJumpConnection:Disconnect()
                infJumpConnection = nil
            end
        end
    end
})

Misc:AddToggle('RemoveGrasss', {
    Text = 'Remove Grass',
    Default = false,  
    Callback = function(first)
        sethiddenproperty(game:GetService("Workspace").Terrain, "Decoration", not first)
    end
})

local proximityActive = false
local promptConnections = {}
local originalValues = {}
local descendantConnection = nil

local function setInstantPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    if originalValues[prompt] == nil then
        originalValues[prompt] = prompt.HoldDuration
    end
    
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12.5
end

local function restorePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    local original = originalValues[prompt]
    if original ~= nil then
        prompt.HoldDuration = original
        originalValues[prompt] = nil
    end
end

local function setupProximityPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if promptConnections[prompt] then return end
    
    setInstantPrompt(prompt)
    
    local connection = prompt:GetPropertyChangedSignal("HoldDuration"):Connect(function()
        if proximityActive and prompt.HoldDuration ~= 0 then
        if proximityActive and prompt.MaxActivationDistance ~= 12.5 then
            setInstantPrompt(prompt)
        end
    end
end)
    
    promptConnections[prompt] = connection
end

local function scanAndSetupAll()
    for _, v in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            setupProximityPrompt(v)
        end
    end
end

local function restoreAllPrompts()
    for prompt, original in pairs(originalValues) do
        if prompt and prompt:IsA("ProximityPrompt") then
            prompt.HoldDuration = original
        end
    end
    originalValues = {}
end

local function cleanupAll()
    for prompt, conn in pairs(promptConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    promptConnections = {}
    
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end
end

Misc:AddToggle('ProximityToggle', {
    Text = 'Remove CoolDown Proximity',
    Default = false,
    
    Callback = function(Value)
        proximityActive = Value
        
        if Value then
        
            scanAndSetupAll()
            
            descendantConnection = game:GetService("Workspace").DescendantAdded:Connect(function(descendant)
                if proximityActive and descendant:IsA("ProximityPrompt") then
                    setupProximityPrompt(descendant)
                end
            end)
            
        else

            restoreAllPrompts()
            
            cleanupAll()
        end
    end
})

local robloxFcScript = nil

local function stopRobloxFC()
    if robloxFcScript then
        pcall(function()
            robloxFcScript:SetAttribute("FreecamEnabled", false)
        end)
        robloxFcScript = nil
    end
    local gui = LocalPlayer.PlayerGui:FindFirstChild("Freecam")
    if gui then
        pcall(function() gui:Destroy() end)
    end
end

local function startRobloxFC()
    stopRobloxFC()

    local ok, err = pcall(function()
        if not LocalPlayer.PlayerGui:FindFirstChild("Freecam") then
            local gui = Instance.new("ScreenGui")
            gui.ResetOnSpawn = false
            gui.Name = "Freecam"
            gui.Parent = LocalPlayer.PlayerGui
        end

        local fcScript = CoreGui.RobloxGui.Modules.Server.FreeCamera.FreeCamera
        getrenv().require(fcScript)
        fcScript:SetAttribute("FreecamEnabled", true)
        robloxFcScript = fcScript
    end)

    if not ok then
        warn("Roblox FC failed:", err)
        if Options and Options.RobloxFC then
            Options.RobloxFC:SetValue(false)
        end
    end
end

Misc:AddToggle('RobloxFC', {
    Text = 'Roblox Freecam',
    Default = false,
    Callback = function(Value)
        if Value then
            startRobloxFC()
        else
            stopRobloxFC()
        end
    end
})

shared.DebugSettings = shared.DebugSettings or { Enabled = false, Delta = 0 }

local debugGui = CoreGui:FindFirstChild("Debug")
local debugLabel

if not debugGui then
    local sg = Instance.new("ScreenGui")
    sg.Name = "Debug"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    debugLabel = Instance.new("TextLabel")
    debugLabel.Name = "Debug"
    debugLabel.Size = UDim2.new(0, 250, 0, 150)
    debugLabel.Position = UDim2.new(0, 15, 0, 15)
    debugLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    debugLabel.BackgroundTransparency = 1
    debugLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugLabel.TextSize = 14
    debugLabel.Font = Enum.Font.Code
    debugLabel.TextXAlignment = Enum.TextXAlignment.Left
    debugLabel.TextYAlignment = Enum.TextYAlignment.Top
    debugLabel.Visible = false
    debugLabel.Parent = sg

    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, 6)
    uc.Parent = debugLabel

    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(32, 35, 96)
    st.Thickness = 1
    st.Parent = debugLabel

    local up = Instance.new("UIPadding")
    up.PaddingLeft = UDim.new(0, 8)
    up.PaddingTop = UDim.new(0, 8)
    up.Parent = debugLabel
else
    debugLabel = debugGui:FindFirstChild("Debug")
end

MiscServer:AddToggle('DebugToggle', {
    Text = 'Enable Debug',
    Default = false,
    Callback = function(Value)
        shared.DebugSettings.Enabled = Value
        if debugLabel then
            debugLabel.Visible = Value
        end
    end
})

task.spawn(function()
    while true do
        local delta = RunService.RenderStepped:Wait()
        
        if not shared.DebugSettings.Enabled then 
            continue 
        end

        shared.DebugSettings.Delta = delta

        local localPlayer = Players.LocalPlayer
        local character = localPlayer and localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")

        if hrp and debugLabel then
            local serverStats = Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerStatsItem")
            local pingItem = serverStats and serverStats:FindFirstChild("Data Ping")
            local currentPing = pingItem and math.floor(pingItem:GetValue()) or 0

            local mouseLoc = UserInputService:GetMouseLocation()
            
            debugLabel.Text = string.format(
                "Players: %d\n" ..
                "Ping: %d ms\n" ..
                "Time: %s\n" ..
                "Mouse X: %.2f, Y: %.2f\n" ..
                "Pos X: %.2f\n" ..
                "Pos Y: %.2f\n" ..
                "Pos Z: %.2f\n" ..
                "Memory: %.2f MB",
                #Players:GetPlayers(),
                currentPing,
                os.date("%X"),
                mouseLoc.X, mouseLoc.Y,
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z,
                Stats:GetTotalMemoryUsageMb()
            )
        end
    end
end)

local connection = nil

MiscServer:AddToggle('SendFire', {
    Text = 'Send HasRobloxSubscription Paket',
    Default = false,
    Callback = function(Value)
        if Value then
            connection = RunService.Heartbeat:Connect(function()
                game:GetService("Players").LocalPlayer.HasRobloxSubscription = true
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

local hookEnabled = false
local oldIndex

oldIndex = hookmetamethod(game, "__index", function(self, key)
    if hookEnabled and self == LocalPlayer and key == "HasVerifiedBadge" then
        return true
    end
    return oldIndex(self, key)
end)

MiscServer:AddToggle('SendFire', { 
    Text = 'Send HasVerifiedBadge Paket', 
    Default = false, 
    Callback = function(Value) 
        hookEnabled = Value
    end 
})


local Misc = Tabs.Misc:AddRightGroupbox('Mini Misc')

Misc:AddButton({
    Text = 'Dex++',
    Func = function(part)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mixvpnv2/CatteState/refs/heads/main/Dexpp"))()
    end,
    DoubleClick = true, 
})

local Misc = Tabs.Misc:AddRightGroupbox('Camera')

local thirdpersonEnabled = false
local thirdpersonDistance = 10 

pcall(function()
    local __newindex
    __newindex = hookmetamethod(game, "__newindex", function(obj, idx, val)
        if obj == camera and idx == "CFrame" then
            if thirdpersonEnabled then
                val = val + camera.CFrame.LookVector * -thirdpersonDistance
            end
        end
        return __newindex(obj, idx, val)
    end)
end)

local thirdpersonEnabled = false
local thirdpersonDistance = 10

pcall(function()
    local __newindex
    __newindex = hookmetamethod(game, "__newindex", newcclosure(function(obj, idx, val)
        if thirdpersonEnabled and obj == camera and idx == "CFrame" then
            val = val + camera.CFrame.LookVector * -thirdpersonDistance
        end
        return __newindex(obj, idx, val)
    end))
end)

local function setThirdPerson(state)
    thirdpersonEnabled = state and true or false
    if Options and Options.ThirdPersonToggle then
        if Options.ThirdPersonToggle.Value ~= thirdpersonEnabled then
            Options.ThirdPersonToggle:SetValue(thirdpersonEnabled)
        end
    end
end

local ThirdPersonToggle = Misc:AddToggle('ThirdPersonToggle', {
    Text = 'Third Person',
    Default = false,
    Tooltip = 'Enables customizable third person view',
    Callback = function(Value)
        thirdpersonEnabled = Value
    end
})

ThirdPersonToggle:AddKeyPicker('ThirdPersonKey', {
    Default = 'None',
    Mode = 'Toggle',
    SyncToggleState = true,
    Text = 'Third Person',
    NoUI = false,
    Callback = function(Value)
        thirdpersonEnabled = Value
    end,
    ChangedCallback = function(New)
    end
})

Misc:AddSlider('ThirdPersonSlider', {
    Text = 'Third Person Distance',
    Default = 10,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Suffix = "",
    Compact = false,
    Callback = function(Value)
        thirdpersonDistance = Value
    end
})

local Misc = Tabs.Misc:AddLeftGroupbox('Misc')

local Visuals = Tabs.Visuals:AddLeftGroupbox('Visuals')
local World = Tabs.Visuals:AddLeftGroupbox('World Visuals')
local VisualsRight = Tabs.Visuals:AddRightGroupbox('Visuals')

local _esplib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mixvpnv2/CatteState/refs/heads/main/esp"))() --orig  https://raw.githubusercontent.com/SWIMHUBISWIMMING/-/refs/heads/main/library/esp/esp.lua thx swim

local enemysets = _esplib.teamSettings.enemy
local teamsets = _esplib.teamSettings.friendly
local shared = _esplib.sharedSettings

Visuals:AddToggle("EnemyEspEnable", {
    Text = "enable esp",
    Default = false,
    Callback = function(v) enemysets.enabled = v end
})

Visuals:AddToggle("EnemyBox", {
    Text = "box esp",
    Default = false,
    Callback = function(v) enemysets.box = v end
}):AddColorPicker("EnemyBoxColor", {
    Default = Color3.new(1, 1, 1),
    Title = "box color",
    Transparency = 0,
    Callback = function(c) enemysets.boxColor[1] = c end
})

Visuals:AddToggle("EnemyBoxFill", {
    Text = "box fill",
    Default = false,
    Callback = function(v) enemysets.boxFill = v end
}):AddColorPicker("EnemyBoxFillColor", {
    Default = Color3.fromRGB(255, 50, 50),
    Title = "fill color",
    Transparency = 0.5,
    Callback = function(c) enemysets.boxFillColor[1] = c end
})

Visuals:AddToggle("EnemyName", {
    Text = "name esp",
    Default = false,
    Callback = function(v) enemysets.name = v end
}):AddColorPicker("EnemyNameColor", {
    Default = Color3.new(1, 1, 1),
    Title = "name color",
    Transparency = 0,
    Callback = function(c) enemysets.nameColor[1] = c end
})

Visuals:AddToggle("EnemyHealthBar", {
    Text = "health bar esp",
    Default = false,
    Callback = function(v) enemysets.healthBar = v end
})

Visuals:AddToggle("EnemyHealthText", {
    Text = "health text esp",
    Default = false,
    Callback = function(v) enemysets.healthText = v end
}):AddColorPicker("EnemyHealthTextColor", {
    Default = Color3.new(0, 1, 0),
    Title = "health color",
    Transparency = 0,
    Callback = function(c) enemysets.healthTextColor[1] = c end
})

Visuals:AddToggle("EnemyTracer", {
    Text = "tracers esp",
    Default = false,
    Callback = function(v) enemysets.tracer = v end
}):AddColorPicker("EnemyTracerColor", {
    Default = Color3.new(1, 0, 0),
    Title = "tracer color",
    Transparency = 0,
    Callback = function(c) enemysets.tracerColor[1] = c end
})

Visuals:AddDropdown("EnemyTracerOrigin", {
    Values = { "Top", "Bottom", "Mouse" },
    Default = 2,
    Multi = false,
    Text = "tracer origin",
    Callback = function(v) enemysets.tracerOrigin = v end
})

Visuals:AddToggle("EnemyDistance", {
    Text = "distance esp",
    Default = false,
    Callback = function(v) enemysets.distance = v end
}):AddColorPicker("EnemyDistanceColor", {
    Default = Color3.new(1, 1, 1),
    Title = "distance color",
    Transparency = 0,
    Callback = function(c) enemysets.distanceColor[1] = c end
})

Visuals:AddToggle("EnemyChams", {
    Text = "chams",
    Default = false,
    Callback = function(v) enemysets.chams = v end
}):AddColorPicker("EnemyChamsOutline", {
    Default = Color3.new(1, 0, 0),
    Title = "chams outline",
    Transparency = 0,
    Callback = function(c) enemysets.chamsOutlineColor[1] = c end
}):AddColorPicker("EnemyChamsFill", {
    Default = Color3.fromRGB(40, 40, 40),
    Title = "chams fill",
    Transparency = 0.5,
    Callback = function(c) enemysets.chamsFillColor[1] = c end
})

Visuals:AddToggle("EnemyChamsVisible", {
    Text = "chams visible only",
    Default = false,
    Callback = function(v) enemysets.chamsVisibleOnly = v end
})

Visuals:AddToggle("EnemyOOF", {
    Text = "oof arrows",
    Default = false,
    Callback = function(v) enemysets.offScreenArrow = v end
}):AddColorPicker("EnemyOOFColor", {
    Default = Color3.new(1, 1, 1),
    Title = "oof color",
    Transparency = 0,
    Callback = function(c) enemysets.offScreenArrowColor[1] = c end
})

Visuals:AddToggle("EnemyOOFOutline", {
    Text = "oof outline",
    Default = true,
    Callback = function(v) enemysets.offScreenArrowOutline = v end
})

Visuals:AddSlider("EnemyOOFRadius", {
    Text = "oof radius",
    Default = 150, Min = 50, Max = 600, Rounding = 0, Compact = true,
    Callback = function(v) enemysets.offScreenArrowRadius = v end
})

Visuals:AddSlider("EnemyOOFSize", {
    Text = "oof size",
    Default = 15, Min = 5, Max = 40, Rounding = 0, Compact = true,
    Callback = function(v) enemysets.offScreenArrowSize = v end
})

-- Visuals:AddToggle("EnemyLimitDist", {
--     Text = "limit distance",
--     Default = false,
--     Callback = function(v) shared.limitDistance = v end
-- })

-- Visuals:AddSlider("EnemyMaxDist", {
--     Text = "max distance",
--     Default = 1500, Min = 50, Max = 5000, Rounding = 0, Compact = true,
--     Callback = function(v) shared.maxDistance = v end
-- })

VisualsRight:AddToggle("TeamEspEnable", {
    Text = "enable esp",
    Default = false,
    Callback = function(v) teamsets.enabled = v end
})

VisualsRight:AddToggle("TeamBox", {
    Text = "box esp",
    Default = false,
    Callback = function(v) teamsets.box = v end
}):AddColorPicker("TeamBoxColor", {
    Default = Color3.new(0, 1, 0),
    Title = "box color",
    Transparency = 0,
    Callback = function(c) teamsets.boxColor[1] = c end
})

VisualsRight:AddToggle("TeamName", {
    Text = "name esp",
    Default = false,
    Callback = function(v) teamsets.name = v end
}):AddColorPicker("TeamNameColor", {
    Default = Color3.new(1, 1, 1),
    Title = "name color",
    Transparency = 0,
    Callback = function(c) teamsets.nameColor[1] = c end
})

VisualsRight:AddToggle("TeamHealthBar", {
    Text = "health bar esp",
    Default = false,
    Callback = function(v) teamsets.healthBar = v end
})

VisualsRight:AddToggle("TeamHealthText", {
    Text = "health text esp",
    Default = false,
    Callback = function(v) teamsets.healthText = v end
}):AddColorPicker("TeamHealthTextColor", {
    Default = Color3.new(0, 1, 0),
    Title = "health color",
    Transparency = 0,
    Callback = function(c) teamsets.healthTextColor[1] = c end
})

VisualsRight:AddToggle("TeamDistance", {
    Text = "distance esp",
    Default = false,
    Callback = function(v) teamsets.distance = v end
}):AddColorPicker("TeamDistanceColor", {
    Default = Color3.new(1, 1, 1),
    Title = "distance color",
    Transparency = 0,
    Callback = function(c) teamsets.distanceColor[1] = c end
})

VisualsRight:AddToggle("TeamChams", {
    Text = "chams",
    Default = false,
    Callback = function(v) teamsets.chams = v end
}):AddColorPicker("TeamChamsOutline", {
    Default = Color3.new(0, 1, 0),
    Title = "chams outline",
    Transparency = 0,
    Callback = function(c) teamsets.chamsOutlineColor[1] = c end
}):AddColorPicker("TeamChamsFill", {
    Default = Color3.fromRGB(40, 40, 40),
    Title = "chams fill",
    Transparency = 0.5,
    Callback = function(c) teamsets.chamsFillColor[1] = c end
})

_esplib.Load()

local CustomSettings = {
    FreezeTime = false,
    TargetTime = 14,
    AmbientColor = Color3.fromRGB(0, 255, 140),
    OutdoorAmbientColor = Color3.fromRGB(0, 255, 140)
}

World:AddToggle('NoGrass', {
    Text = 'No Grass',
    Default = false, 
    Callback = function(Value)
    sethiddenproperty(Workspace.Terrain, "Decoration", not Value)
    end
})
World:AddToggle('NoShadows', {
    Text = 'No Shadows',
    Default = false, 
    Callback = function(Value)
        if Value then
            Lighting.GlobalShadows = false
        else
            Lighting.GlobalShadows = true
        end
    end
})

if _G.DefaultAtmosphereDensity == nil then
    _G.DefaultAtmosphereDensity = (Lighting and Lighting:FindFirstChildOfClass("Atmosphere") and Lighting:FindFirstChildOfClass("Atmosphere").Density) or 0.3
    _G.DefaultAtmosphereOffset = (Lighting and Lighting:FindFirstChildOfClass("Atmosphere") and Lighting:FindFirstChildOfClass("Atmosphere").Offset) or 0.25
end

World:AddToggle('NoFog', {
    Text = 'No Fog',
    Default = false, 
    Callback = function(Value)
        _G.NoFogEnabled = Value
        
        if not Value and Lighting and Lighting:FindFirstChildOfClass("Atmosphere") then
            Lighting:FindFirstChildOfClass("Atmosphere").Density = _G.DefaultAtmosphereDensity
            Lighting:FindFirstChildOfClass("Atmosphere").Offset = _G.DefaultAtmosphereOffset
        end
    end
})

if _G.NoFogConnection then _G.NoFogConnection:Disconnect() end
_G.NoFogConnection = RunService.RenderStepped:Connect(function()
    if _G.NoFogEnabled and Lighting and Lighting:FindFirstChildOfClass("Atmosphere") then
        Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
        Lighting:FindFirstChildOfClass("Atmosphere").Offset = 0
    end
end)

World:AddToggle('TimeToggle', {
    Text = 'Toggle Time Clock',
    Default = false, 
    Callback = function(Value)
        CustomSettings.FreezeTime = Value
        if Value then
            Lighting.ClockTime = CustomSettings.TargetTime
        end
    end
})

World:AddSlider('TimeSlider', {
    Text = 'Time Clock',
    Default = 14,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Suffix = "",
    Compact = false,
    Callback = function(Value)
        CustomSettings.TargetTime = Value
        if CustomSettings.FreezeTime then
            Lighting.ClockTime = Value
        end
    end
})

World:AddLabel('Ambient'):AddColorPicker('AmbientPicker', {
    Default = Color3.fromRGB(70, 70, 70), 
    Title = 'Ambient color',
    Transparency = 0,
    Callback = function(Value)
        CustomSettings.AmbientColor = Value
        Lighting.Ambient = Value
    end
})

World:AddLabel('OutdoorAmbient'):AddColorPicker('OutdoorAmbientPicker', {
    Default = Color3.fromRGB(70, 70, 70), 
    Title = 'OutdoorAmbient color',
    Transparency = 0,
    Callback = function(Value)
        CustomSettings.OutdoorAmbientColor = Value
        Lighting.OutdoorAmbient = Value
    end
})

local __newindex
__newindex = hookmetamethod(game, "__newindex", newcclosure(function(self, k, v)
    if checkcaller() then 
        return __newindex(self, k, v) 
    end
    
    if self == Lighting then
        if k == "ClockTime" and CustomSettings.FreezeTime then 
            return 
        end
        
        if k == "Ambient" then 
            return 
        end
        if k == "OutdoorAmbient" then 
            return 
        end
        if k == "GlobalShadows" or k == "ExposureCompensation" or k == "Brightness" then
            return
        end
    end
    
    return __newindex(self, k, v)
end))

game:GetService("RunService").Heartbeat:Connect(function()
    if CustomSettings.FreezeTime then
        Lighting.ClockTime = CustomSettings.TargetTime
    end
    Lighting.Ambient = CustomSettings.AmbientColor
    Lighting.OutdoorAmbient = CustomSettings.OutdoorAmbientColor
end)

Library:SetWatermarkVisibility(true)

FrameTimer = tick()
FrameCounter = 0;
FPS = 60;

WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(('CatteState Universal | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

Library.KeybindFrame.Visible = false;

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    Library.Unloaded = true
end)

MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = ']', NoUI = false, Text = 'Menu keybind' })    

MenuGroup:AddButton('Rejoin Insta Rejoin', function()
    if #Players:GetPlayers() <= 1 then
        localPlayer:Kick("\nrejoining")
        task.wait()
        game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
    else
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
    end
end)
MenuGroup:AddButton('Exit Game Insta Exit', function()
    game:Shutdown()
end)
MenuGroup:AddToggle('KeybindShoww', {
    Text = 'Show Keybinds',
    Default = false,  

    Callback = function(first)
        Library.KeybindFrame.Visible = first;
    end
})

MenuGroup:AddSlider('FPSLimit', { 
    Text = 'Fps limit', 
    Default = 240, 
    Min = 60, 
    Max = 240,
    Rounding = 0, 
    Compact = false, 
    Callback = function(value) 
        local fps = math.floor(tonumber(value))
        if fps then
            pcall(setfpscap, fps)
        end
    end 
})


Library.ToggleKeybind = Options.MenuKeybind



ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })


ThemeManager:SetFolder('CatteState')
SaveManager:SetFolder('CatteState/Universal')


SaveManager:BuildConfigSection(Tabs['UI Settings'])


ThemeManager:ApplyToTab(Tabs['UI Settings'])


SaveManager:LoadAutoloadConfig()
