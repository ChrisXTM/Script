--[[
    UNIVERSAL COMBAT HUB (RAYFIELD REMASTERED EDITION)
    UI Aesthetic Upgrade & Integrated Features
    Original Script by ChrisXTM | UI Redesign
--]]

--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

--// GLOBAL STATE VARIABLES
local currentTarget = nil
local selectedBodyPart = "HumanoidRootPart"

-- Back Dash Variables
local autoBackdashEnabled = false
local maxDashDistance = 45
local isDashing = false

-- Heroes BG Variables
local aimlockEnabled = false
local infDashesEnabled = false
local heartbeatConnection = nil

-- Folders to remove for Inf Dashes
local foldersToDelete = {
    "DASHCD", "SideDashCounter", "ForwardDashCD", "DashPunchCD",
    "DontAllowBlocking", "RecentSideDash", "TRUECANTSIDEDASH",
    "CantPunchOnCLIENT", "DownSlamCD", "RecentStun",
    "RecentStunNoAction", "recentdashok", "RagdollCancelCD",
    "M1CD", "AttackCD", "SwingCD", "PunchCD", "HitCooldown", "IsAttacking"
}

--// ANIMATION OBJECTS (DASHES)
local frontDashAnim = Instance.new("Animation")
frontDashAnim.AnimationId = "rbxassetid://13917336710"

local leftDashAnim = Instance.new("Animation")
leftDashAnim.AnimationId = "rbxassetid://101843860692381"

local rightDashAnim = Instance.new("Animation")
rightDashAnim.AnimationId = "rbxassetid://100087324592640"

local frontTrack, leftTrack, rightTrack

--// LOAD ANIMATION TRACKS
local function loadTracks(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 10)
    local animator = hum and hum:WaitForChild("Animator", 10)
    if animator then
        frontTrack = animator:LoadAnimation(frontDashAnim)
        leftTrack = animator:LoadAnimation(leftDashAnim)
        rightTrack = animator:LoadAnimation(rightDashAnim)
    end
end

if player.Character then loadTracks(player.Character) end
player.CharacterAdded:Connect(function(char)
    character = char
    loadTracks(char)
end)

--// HELPER & UTILITY FUNCTIONS
local function CleanUpGyro()
    local myChar = player.Character
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

local function quadraticBezier(p0, p1, p2, t)
    return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

local function getTargetPart(model)
    if not model then return nil end
    return model:FindFirstChild(selectedBodyPart) 
        or model:FindFirstChild("HumanoidRootPart") 
        or model:FindFirstChild("Torso") 
        or model:FindFirstChild("UpperTorso") 
        or model:FindFirstChild("Head")
end

local function isLocalIncapacitated(myChar, myHum, myHRP)
    if not myChar or not myHum or myHum.Health <= 0 then return true end
    if myHum.PlatformStand then return true end

    local state = myHum:GetState()
    if state == Enum.HumanoidStateType.Physics 
        or state == Enum.HumanoidStateType.FallingDown 
        or state == Enum.HumanoidStateType.Ragdoll 
        or state == Enum.HumanoidStateType.Freefall 
        or state == Enum.HumanoidStateType.GettingUp 
        or state == Enum.HumanoidStateType.Dead then
        return true
    end

    if myHRP then
        local velocity = myHRP.AssemblyLinearVelocity
        if velocity.Magnitude > 65 then
            return true
        end
    end

    local stunAttrs = {"Stunned", "Stun", "Ragdoll", "Knocked", "KnockedDown", "KnockedOut", "Hit", "Combo"}
    for _, attrName in ipairs(stunAttrs) do
        if myChar:GetAttribute(attrName) == true then
            return true
        end
    end

    return false
end

local function isCharacterStunned(char)
    if not char or not char.Parent then return true end
    if UserInputService:GetFocusedTextBox() then return true end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return true end
    
    if hum.PlatformStand or hum.Sit then return true end
    
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Ragdoll 
        or state == Enum.HumanoidStateType.FallingDown 
        or state == Enum.HumanoidStateType.Dead then
        return true
    end

    local stunAttributes = {"Stunned", "Stun", "Ragdoll", "KnockedDown", "KnockedOut", "Knocked", "LyingDown"}
    for _, attrName in ipairs(stunAttributes) do
        if char:GetAttribute(attrName) == true then
            return true
        end
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("ValueBase") then
            local nameLower = string.lower(child.Name)
            if string.find(nameLower, "stun") or string.find(nameLower, "ragdoll") or string.find(nameLower, "knocked") or string.find(nameLower, "lying") then
                if child:IsA("BoolValue") and child.Value == true then
                    return true
                elseif (child:IsA("NumberValue") or child:IsA("IntValue")) and child.Value > 0 then
                    return true
                end
            end
        end
    end

    return false
end

--// RAYFIELD UI LIBRARY SETUP
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "XTM Combat Suite | Premium Edition",
    Icon = 4483362458,
    LoadingTitle = "XTM Systems Loading...",
    LoadingSubtitle = "by @ChrisXTM",
    ShowText = "XTM Hub",
    Theme = "Ocean",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XTM_Hub_Config",
        FileName = "XTM_Settings"
    },
    Discord = { Enabled = false },
    KeySystem = false
})

-- ==========================================
--  TAB 1: BACK DASH
-- ==========================================
local DashTab = Window:CreateTab("Back Dash", 4483362458)

DashTab:CreateSection("Target Management")

local targetParagraph = DashTab:CreateParagraph({
    Title = "Status: Target Unset",
    Content = "Right-click an enemy or use search to set target."
})

DashTab:CreateDropdown({
    Name = "Target Locking Body Part",
    Options = {
        "HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso", 
        "LeftArm", "RightArm", "LeftLeg", "RightLeg"
    },
    CurrentOption = {"HumanoidRootPart"},
    MultipleOptions = false,
    Flag = "TargetBodyPart",
    Callback = function(Option)
        selectedBodyPart = Option[1] or "HumanoidRootPart"
    end,
})

DashTab:CreateSection("Directional Dash Options")

DashTab:CreateToggle({
    Name = "Enable Auto Back-Dash (Hotkey: Q)",
    CurrentValue = false,
    Flag = "AutoBackdash",
    Callback = function(Value)
        autoBackdashEnabled = Value
        Rayfield:Notify({
            Title = "Back-Dash " .. (Value and "Enabled" or "Disabled"),
            Content = Value and "Press Q when in range." or "Module paused.",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

DashTab:CreateSlider({
    Name = "Maximum Activation Distance",
    Range = {10, 100},
    Increment = 5,
    Suffix = "Studs",
    CurrentValue = 45,
    Flag = "MaxDashDistance",
    Callback = function(Value)
        maxDashDistance = Value
    end,
})

-- ==========================================
--  TAB 2: HEROES BATTLEGROUNDS SUITE
-- ==========================================
local HBGTab = Window:CreateTab("Inf Dashes + OP Aimlock", 4483362458)

HBGTab:CreateSection("Player Target Selector")

local hbgTargetParagraph = HBGTab:CreateParagraph({
    Title = "Target: None",
    Content = "Enter player name to set target manually."
})

HBGTab:CreateInput({
    Name = "Search Player by Name",
    PlaceholderText = "Type full or partial name...",
    RemoveTextOnFocusLost = false,
    Callback = function(Text)
        if Text ~= "" then
            local textLower = string.lower(Text)
            local found = nil
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and string.find(string.lower(p.Name), textLower) then
                    found = p.Character
                    break
                end
            end
            if found then
                currentTarget = found
                local partFound = getTargetPart(currentTarget)
                local partName = partFound and partFound.Name or selectedBodyPart
                
                targetParagraph:Set({
                    Title = "Target: " .. currentTarget.Name .. " [" .. partName .. "]",
                    Content = "Target locked successfully."
                })
                hbgTargetParagraph:Set({
                    Title = "Target: " .. currentTarget.Name,
                    Content = "Ready for combat."
                })
                Rayfield:Notify({
                    Title = "Target Found",
                    Content = "Target locked onto: " .. currentTarget.Name,
                    Duration = 2,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Search Error",
                    Content = "No player found matching: " .. Text,
                    Duration = 2.5,
                    Image = 4483362458
                })
            end
        end
    end,
})

HBGTab:CreateSection("Combat Enhancements")

HBGTab:CreateToggle({
    Name = "Combat Aimlock",
    CurrentValue = false,
    Flag = "AimlockToggle",
    Callback = function(Value)
        aimlockEnabled = Value
        if not Value then
            CleanUpGyro()
        end
    end,
})

local function removeFolders()
    local liveFolder = workspace:FindFirstChild("Live")
    if liveFolder then
        local targetParent = liveFolder:FindFirstChild(player.Name)
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

HBGTab:CreateToggle({
    Name = "Inf Dashes / CD Bypass",
    CurrentValue = false,
    Flag = "InfDashesToggle",
    Callback = function(Value)
        infDashesEnabled = Value
        if infDashesEnabled then
            heartbeatConnection = RunService.Heartbeat:Connect(removeFolders)
        else
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
        end
    end,
})

-- ==========================================
--  TAB 3: SETTINGS & CREDITS
-- ==========================================
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Hub Configuration")

SettingsTab:CreateKeybind({
    Name = "Toggle UI Visibility",
    CurrentKeybind = "K",
    HoldToInteract = false,
    Flag = "UIKeybind",
    Callback = function(Keybind)
        -- Handled automatically by Rayfield
    end,
})

SettingsTab:CreateSection("Developer Credits")

local creditParagraph = SettingsTab:CreateParagraph({
    Title = "Created By @ChrisXTM",
    Content = ""
})

-- Rainbow Text Effect for Credits
task.spawn(function()
    local text = "Created By @ChrisXTM"
    local offset = 0
    while task.wait(0.03) do
        offset = (offset + 0.03) % 1
        local rainbowText = ""
        for i = 1, #text do
            local char = text:sub(i, i)
            if char == " " then
                rainbowText = rainbowText .. " "
            else
                local hue = ((i * 0.04) + offset) % 1
                local color = Color3.fromHSV(hue, 1, 1)
                local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
                rainbowText = rainbowText .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, char)
            end
        end
        pcall(function()
            creditParagraph:Set({
                Title = "<b>" .. rainbowText .. "</b>",
                Content = "!!!XTM Completed Script!!!"
            })
        end)
    end
end)

-- ==========================================
--  RIGHT-CLICK TARGET SELECTION
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local target = mouse.Target
        if target and target.Parent then
            local model = target.Parent
            if not model:FindFirstChildOfClass("Humanoid") and model.Parent and model.Parent:FindFirstChildOfClass("Humanoid") then
                model = model.Parent
            end
            
            if model:FindFirstChildOfClass("Humanoid") and model ~= character then
                currentTarget = model
                local partFound = getTargetPart(model)
                local partName = partFound and partFound.Name or selectedBodyPart
                
                targetParagraph:Set({
                    Title = "Target: " .. model.Name .. " [" .. partName .. "]",
                    Content = "Combat mode ready."
                })
                hbgTargetParagraph:Set({
                    Title = "Target: " .. model.Name,
                    Content = "Ready for combat."
                })
                
                Rayfield:Notify({
                    Title = "Target Locked",
                    Content = "Target: " .. model.Name,
                    Duration = 2,
                    Image = 4483362458,
                })
            end
        end
    end
end)

-- ==========================================
--  AIMLOCK UPDATE LOOP (HEROES BG)
-- ==========================================
RunService.RenderStepped:Connect(function()
    local myChar = player.Character
    if not myChar then return end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    
    if aimlockEnabled and currentTarget and currentTarget.Parent and myHRP and myHum then
        local enemyChar = currentTarget
        local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
        local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
        
        if not enemyHum or enemyHum.Health <= 0 or not enemyHRP or not enemyHRP.Parent then
            CleanUpGyro()
            return
        end
        
        if isLocalIncapacitated(myChar, myHum, myHRP) then
            CleanUpGyro()
            return
        end
        
        local myPos = myHRP.Position
        local enemyPos = enemyHRP.Position
        local flatEnemyPos = Vector3.new(enemyPos.X, myPos.Y, enemyPos.Z)
        local distance2D = (flatEnemyPos - myPos).Magnitude
        
        if distance2D > 0.5 then
            myHum.AutoRotate = false
            
            local gyro = myHRP:FindFirstChild("AimGyro")
            if not gyro then
                gyro = Instance.new("BodyGyro")
                gyro.Name = "AimGyro"
                gyro.maxTorque = Vector3.new(0, 400000, 0)
                gyro.P = 15000
                gyro.D = 800
                gyro.Parent = myHRP
            end
            
            gyro.CFrame = CFrame.lookAt(myPos, flatEnemyPos)
        else
            CleanUpGyro()
        end
    else
        CleanUpGyro()
    end
end)

-- ==========================================
--  ANIMATED BACK DASH LOGIC (Q KEY)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.Q and autoBackdashEnabled and not isDashing then
        local myChar = player.Character or player.CharacterAdded:Wait()
        
        if isCharacterStunned(myChar) then
            return
        end
        
        if not currentTarget or not currentTarget.Parent then
            return
        end
        
        local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")
        if not targetHum or targetHum.Health <= 0 then
            currentTarget = nil
            targetParagraph:Set({
                Title = "Status: Target Unset",
                Content = "Right-click an enemy or use search to set target."
            })
            hbgTargetParagraph:Set({
                Title = "Target: None",
                Content = "Enter player name to set target manually."
            })
            return
        end
        
        local targetPart = getTargetPart(currentTarget)
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        
        if targetPart and myHRP and hum then
            local currentDistance = (myHRP.Position - targetPart.Position).Magnitude
            if currentDistance > maxDashDistance then
                return 
            end
            
            isDashing = true
            
            local distanceBehind = 4
            local uCurveOffset = distanceBehind
            local startPos = myHRP.Position
            
            local initialTargetCF = targetPart.CFrame
            local dirToTarget = (initialTargetCF.Position - startPos).Unit
            
            local sideVector = Vector3.new(-dirToTarget.Z, 0, dirToTarget.X)
            if sideVector.Magnitude > 0 then
                sideVector = sideVector.Unit
            else
                sideVector = myHRP.CFrame.RightVector
            end
            
            local isPressingA = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
            local isPressingD = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)
            local rightVector = myHRP.CFrame.RightVector
            
            if isPressingA then
                if sideVector:Dot(rightVector) > 0 then
                    sideVector = -sideVector
                end
            elseif isPressingD then
                if sideVector:Dot(rightVector) < 0 then
                    sideVector = -sideVector
                end
            else
                local rightDot = rightVector:Dot(dirToTarget)
                if rightDot < 0 then
                    sideVector = -sideVector
                end
            end
            
            local forwardDot = myHRP.CFrame.LookVector:Dot(dirToTarget)
            local rightDotVal = rightVector:Dot(dirToTarget)
            local chosenTrack = frontTrack
            
            if isPressingA then
                chosenTrack = leftTrack
            elseif isPressingD then
                chosenTrack = rightTrack
            elseif forwardDot > 0.5 then
                chosenTrack = frontTrack
            elseif rightDotVal > 0.3 then
                chosenTrack = rightTrack
            elseif rightDotVal < -0.3 then
                chosenTrack = leftTrack
            else
                chosenTrack = frontTrack
            end
            
            if chosenTrack then
                chosenTrack:Play()
            end
            
            hum.AutoRotate = false
            
            local dashDuration = 0.32
            local startTime = tick()
            
            local connection
            connection = RunService.RenderStepped:Connect(function()
                local elapsed = tick() - startTime
                local progress = math.clamp(elapsed / dashDuration, 0, 1)
                
                local easedProgress = 1 - (1 - progress) * (1 - progress)
                
                if targetPart and targetPart.Parent and myHRP and myHRP.Parent then
                    local currentTargetCF = targetPart.CFrame
                    local currentBehindPos = currentTargetCF.Position - (currentTargetCF.LookVector * distanceBehind)
                    currentBehindPos = Vector3.new(currentBehindPos.X, myHRP.Position.Y, currentBehindPos.Z)
                    
                    local midPoint = (startPos + currentBehindPos) / 2
                    local controlPoint = midPoint + (sideVector * uCurveOffset)
                    
                    local calculatedPos = quadraticBezier(startPos, controlPoint, currentBehindPos, easedProgress)
                    local targetLookPos = Vector3.new(currentTargetCF.Position.X, myHRP.Position.Y, currentTargetCF.Position.Z)
                    
                    myHRP.CFrame = CFrame.lookAt(calculatedPos, targetLookPos)
                end
                
                if progress >= 1 or isCharacterStunned(myChar) then
                    connection:Disconnect()
                    if hum then hum.AutoRotate = true end
                    if chosenTrack then chosenTrack:Stop(0.1) end
                    isDashing = false
                end
            end)
        end
    end
end)
