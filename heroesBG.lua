-- Heroes Battlegrounds: Inf Dashes + Combat Aimlock (BodyGyro Bypass)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Evitar duplicados de la interfaz
if CoreGui:FindFirstChild("HeroesBattlegrounds_Premium") then
    CoreGui:FindFirstChild("HeroesBattlegrounds_Premium"):Destroy()
end

-- Variables de control
local FollowEnabled = false
local CdBypassEnabled = false
local CurrentTarget = nil
local heartbeatConnection = nil
local isMinimized = false

-- Lista de Cooldowns a borrar
local foldersToDelete = {
    "DASHCD", "SideDashCounter", "ForwardDashCD", "DashPunchCD",
    "DontAllowBlocking", "RecentSideDash", "TRUECANTSIDEDASH",
    "CantPunchOnCLIENT", "DownSlamCD", "RecentStun",
    "RecentStunNoAction", "recentdashok", "RagdollCancelCD",
    "M1CD", "AttackCD", "SwingCD", "PunchCD", "HitCooldown", "IsAttacking"
}

-- === INTERFAZ GRÁFICA ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HeroesBattlegrounds_Premium"
ScreenGui.ResetOnSpawn = false

local success, err = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 270)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1
UIStroke.Color = Color3.fromRGB(45, 45, 55)
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -75, 0, 45)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Heroes BG: Combat Aim + Dashes"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -34, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Parent = MainFrame
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -64, 0, 10)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 205)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.Parent = MainFrame
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -45)
ContentFrame.Position = UDim2.new(0, 0, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local TargetIndicator = Instance.new("TextLabel")
TargetIndicator.Size = UDim2.new(1, -28, 0, 28)
TargetIndicator.Position = UDim2.new(0, 14, 0, 5)
TargetIndicator.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
TargetIndicator.Text = "Target: None"
TargetIndicator.TextColor3 = Color3.fromRGB(240, 90, 90)
TargetIndicator.Font = Enum.Font.GothamBold
TargetIndicator.TextSize = 12
TargetIndicator.Parent = ContentFrame
Instance.new("UICorner", TargetIndicator).CornerRadius = UDim.new(0, 6)

local TargetStroke = Instance.new("UIStroke")
TargetStroke.Thickness = 1
TargetStroke.Color = Color3.fromRGB(120, 40, 40)
TargetStroke.Parent = TargetIndicator

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(1, -28, 0, 32)
NameBox.Position = UDim2.new(0, 14, 0, 42)
NameBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
NameBox.PlaceholderText = "Write name..."
NameBox.Text = ""
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
NameBox.Font = Enum.Font.Gotham
NameBox.TextSize = 12
NameBox.Parent = ContentFrame
Instance.new("UICorner", NameBox).CornerRadius = UDim.new(0, 6)

local AimlockButton = Instance.new("TextButton")
AimlockButton.Size = UDim2.new(1, -28, 0, 36)
AimlockButton.Position = UDim2.new(0, 14, 0, 84)
AimlockButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
AimlockButton.Text = "Aimlock: OFF"
AimlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimlockButton.Font = Enum.Font.GothamBold
AimlockButton.TextSize = 13
AimlockButton.Parent = ContentFrame
Instance.new("UICorner", AimlockButton).CornerRadius = UDim.new(0, 6)

local CooldownButton = Instance.new("TextButton")
CooldownButton.Size = UDim2.new(1, -28, 0, 36)
CooldownButton.Position = UDim2.new(0, 14, 0, 128)
CooldownButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CooldownButton.Text = "Inf Dashes: OFF"
CooldownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CooldownButton.Font = Enum.Font.GothamBold
CooldownButton.TextSize = 13
CooldownButton.Parent = ContentFrame
Instance.new("UICorner", CooldownButton).CornerRadius = UDim.new(0, 6)

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Size = UDim2.new(1, 0, 0, 25)
CreditLabel.Position = UDim2.new(0, 0, 1, -25)
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "Created By ChrisXTM"
CreditLabel.Font = Enum.Font.GothamBold
CreditLabel.TextSize = 13
CreditLabel.Parent = ContentFrame

-- Rainbow Credit
RunService.RenderStepped:Connect(function()
    CreditLabel.TextColor3 = Color3.fromHSV((tick() % 4) / 4, 0.9, 1)
end)

-- === LÓGICA DE LIMPIEZA DE GIRO ===
local function CleanUpGyro()
    local myChar = LocalPlayer.Character
    if myChar then
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local gyro = myHRP:FindFirstChild("AimGyro")
            if gyro then gyro:Destroy() end
        end
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        if myHum then myHum.AutoRotate = true end
    end
end

-- === LÓGICA DE OBJETIVO ===
local function SetTarget(player)
    CurrentTarget = player
    if player then
        TargetIndicator.Text = "Target: " .. player.Name
        TargetIndicator.TextColor3 = Color3.fromRGB(50, 220, 130)
        TargetStroke.Color = Color3.fromRGB(40, 120, 70)
    else
        TargetIndicator.Text = "Target: None"
        TargetIndicator.TextColor3 = Color3.fromRGB(240, 90, 90)
        TargetStroke.Color = Color3.fromRGB(120, 40, 40)
        CleanUpGyro()
    end
end

NameBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and NameBox.Text ~= "" then
        local text = string.lower(NameBox.Text)
        local found = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and string.find(string.lower(p.Name), text) then
                found = p
                break
            end
        end
        SetTarget(found)
    end
end)

-- Click Derecho para fijar objetivo
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if CurrentTarget then
            SetTarget(nil)
        else
            local targetPart = Mouse.Target
            local character = targetPart and targetPart.Parent
            if character and character:FindFirstChild("Humanoid") and character ~= LocalPlayer.Character then
                SetTarget(Players:GetPlayerFromCharacter(character))
            elseif character and character.Parent and character.Parent:FindFirstChild("Humanoid") and character.Parent ~= LocalPlayer.Character then
                SetTarget(Players:GetPlayerFromCharacter(character.Parent))
            end
        end
    end
end)

-- === LÓGICA DE COOLDOWN BYPASS ===
local function removeFolders()
    local liveFolder = workspace:FindFirstChild("Live")
    if liveFolder then
        local targetParent = liveFolder:FindFirstChild(LocalPlayer.Name)
        if targetParent then
            for _, folderName in ipairs(foldersToDelete) do
                local folder = targetParent:FindFirstChild(folderName)
                if folder then
                    folder:Destroy()
                end
            end
        end
    end
end

CooldownButton.MouseButton1Click:Connect(function()
    CdBypassEnabled = not CdBypassEnabled
    if CdBypassEnabled then
        CooldownButton.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
        CooldownButton.Text = "Inf Dashes: ON"
        heartbeatConnection = RunService.Heartbeat:Connect(removeFolders)
    else
        CooldownButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        CooldownButton.Text = "Inf Dashes: OFF"
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end
end)

-- === BOTÓN AIMLOCK ===
AimlockButton.MouseButton1Click:Connect(function()
    FollowEnabled = not FollowEnabled
    if FollowEnabled then
        AimlockButton.Text = "Aimlock: ON"
        AimlockButton.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
    else
        AimlockButton.Text = "Aimlock: OFF"
        AimlockButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        CleanUpGyro()
    end
end)

-- === BUCLE DE ACTUALIZACIÓN DEL GIRO (BODYGYRO SEGURO) ===
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    
    if FollowEnabled and CurrentTarget and CurrentTarget.Character and myHRP and myHum then
        local enemyChar = CurrentTarget.Character
        local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
        
        local currentState = myHum:GetState()
        local yoIncapacitado = (
            currentState == Enum.HumanoidStateType.Physics or 
            currentState == Enum.HumanoidStateType.FallingDown or 
            currentState == Enum.HumanoidStateType.Ragdoll or
            myHum.PlatformStand == true or
            myHum.Health <= 0
        )
        
        if yoIncapacitado then
            CleanUpGyro()
            return
        end
        
        if enemyHRP then
            -- Desactivamos la autorotación por defecto para que no pelee con el Gyro
            myHum.AutoRotate = false
            
            -- Buscamos o creamos el BodyGyro en el HumanoidRootPart
            local gyro = myHRP:FindFirstChild("AimGyro")
            if not gyro then
                gyro = Instance.new("BodyGyro")
                gyro.Name = "AimGyro"
                -- CLAVE: Solo aplicamos torque en el eje Y (giro horizontal)
                -- Esto permite que sigas saltando (eje Y libre) y moviéndote perfectamente
                gyro.maxTorque = Vector3.new(0, 500000, 0) 
                gyro.P = 30000 -- Fuerza del giro
                gyro.D = 500   -- Amortiguación para evitar vibración
                gyro.Parent = myHRP
            end
            
            -- Calculamos la dirección hacia el objetivo
            local lookAtCFrame = CFrame.lookAt(myHRP.Position, Vector3.new(enemyHRP.Position.X, myHRP.Position.Y, enemyHRP.Position.Z))
            
            -- Actualizamos la orientación del Gyro
            gyro.cframe = lookAtCFrame
        else
            CleanUpGyro()
        end
    else
        CleanUpGyro()
    end
end)

-- === MENÚ CONTROLES ===
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, 280, 0, 45), "Out", "Quart", 0.2, true)
        ContentFrame.Visible = false
        MinimizeButton.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 280, 0, 270), "Out", "Quart", 0.2, true)
        task.wait(0.1)
        ContentFrame.Visible = true
        MinimizeButton.Text = "-"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    FollowEnabled = false
    SetTarget(nil)
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    CleanUpGyro()
    ScreenGui:Destroy()
end)
