-- ============================================================================
-- 🔥 HER03S BG: AESTHETIC OUTDATED NOTIFICATION
-- Created with ❤️ by ChrisXTM
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

-- Eliminar GUI previa si existe
if CoreGui:FindFirstChild("AestheticOutdatedGui") then
    CoreGui:FindFirstChild("AestheticOutdatedGui"):Destroy()
end

-- === CONFIGURACIÓN VISUAL ===
local CONFIG = {
    MainColor = Color3.fromRGB(20, 20, 25), -- Color de fondo principal
    BorderColor = Color3.fromRGB(45, 45, 55), -- Color del borde
    AccentColor = Color3.fromRGB(35, 150, 255), -- Color de acento (para elementos extra)
    TextColor = Color3.fromRGB(245, 245, 250), -- Color de texto principal
    CloseColor = Color3.fromRGB(220, 70, 70), -- Color rojo moderno para cerrar
    GetColor = Color3.fromRGB(40, 190, 100), -- Color verde moderno para obtener
    CornerRadius = UDim.new(0, 14) -- Redondeo de esquinas
}

local TARGET_URL = "https://www.youtube.com/watch?v=4VNgRmvS98Y"

-- === CREAR INTERFAZ ===

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AestheticOutdatedGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- Cubre toda la pantalla incluyendo la barra superior
ScreenGui.DisplayOrder = 999 -- Asegurar que esté por encima de todo

-- Intentar colocar en CoreGui (o PlayerGui como alternativa)
local success, _ = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then 
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

-- Contenedor principal de fondo (para el efecto fade-in)
local BackgroundFrame = Instance.new("Frame")
BackgroundFrame.Name = "Background"
BackgroundFrame.Size = UDim2.new(1, 0, 1, 0)
BackgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BackgroundFrame.BackgroundTransparency = 1 -- Inicia invisible
BackgroundFrame.BorderSizePixel = 0
BackgroundFrame.Active = true -- Bloquea clics al juego
BackgroundFrame.Parent = ScreenGui

-- El panel de notificación central
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(0, 480, 0, 260) -- Tamaño elegante y compacto
MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centrado en pantalla
MainPanel.AnchorPoint = Vector2.new(0.5, 0.5) -- Punto de anclaje central
MainPanel.BackgroundColor3 = CONFIG.MainColor
MainPanel.BorderSizePixel = 0
MainPanel.ClipsDescendants = true
MainPanel.Parent = BackgroundFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = CONFIG.CornerRadius
MainCorner.Parent = MainPanel

-- Borde/Sombra sutil
local UIBorder = Instance.new("UIStroke")
UIBorder.Thickness = 1.5
UIBorder.Color = CONFIG.BorderColor
UIBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIBorder.Transparency = 0.2
UIBorder.Parent = MainPanel

-- Línea de acento superior
local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(1, 0, 0, 3)
AccentLine.Position = UDim2.new(0, 0, 0, 0)
AccentLine.BackgroundColor3 = CONFIG.AccentColor
AccentLine.BorderSizePixel = 0
AccentLine.Parent = MainPanel

local AccentCorner = Instance.new("UICorner")
AccentCorner.CornerRadius = UDim.new(0, 14) -- Redondeo para la línea de acento
AccentCorner.Parent = AccentLine

-- Título de la notificación
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -40, 0, 40)
TitleLabel.Position = UDim2.new(0, 20, 0, 20)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "@ChrisXTM NEWS:"
TitleLabel.TextColor3 = CONFIG.TextColor
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainPanel

-- Mensaje principal
local MessageLabel = Instance.new("TextLabel")
MessageLabel.Name = "MessageLabel"
MessageLabel.Size = UDim2.new(1, -60, 0, 100)
MessageLabel.Position = UDim2.new(0, 30, 0, 70)
MessageLabel.BackgroundTransparency = 1
MessageLabel.Text = "This script version is Patched.\n\nPlease get the latest update from the official source."
MessageLabel.TextColor3 = CONFIG.TextColor
MessageLabel.Font = Enum.Font.Gotham
MessageLabel.TextSize = 16
MessageLabel.TextWrapped = true
MessageLabel.TextXAlignment = Enum.TextXAlignment.Center
MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
MessageLabel.LineHeight = 1.3
MessageLabel.Parent = MainPanel

-- Contenedor de botones
local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Name = "Buttons"
ButtonsContainer.Size = UDim2.new(1, -60, 0, 50)
ButtonsContainer.Position = UDim2.new(0, 30, 1, -70)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.Parent = MainPanel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 20) -- Espacio entre botones
UIListLayout.Parent = ButtonsContainer

-- === ESTILIZAR BOTONES ===

local function CreateButton(name, text, color, layoutOrder)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(0, 200, 1, 0)
    Button.BackgroundColor3 = color
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = CONFIG.TextColor
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 16
    Button.LayoutOrder = layoutOrder
    Button.AutoButtonColor = false -- Desactivar efecto por defecto para control manual

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 10)
    ButtonCorner.Parent = Button

    -- Efecto de brillo sutil en el borde
    local ButtonStroke = Instance.new("UIStroke")
    ButtonStroke.Thickness = 1.5
    ButtonStroke.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.2) -- Color más claro
    ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ButtonStroke.Transparency = 1 -- Inicia invisible
    ButtonStroke.Parent = Button

    -- === ANIMACIONES DE BOTONES (HOVER) ===
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local hoverScaleTween = TweenService:Create(Button, tweenInfo, {Size = UDim2.new(0, 210, 1, 5)})
    local normalScaleTween = TweenService:Create(Button, tweenInfo, {Size = UDim2.new(0, 200, 1, 0)})
    
    local hoverStrokeTween = TweenService:Create(ButtonStroke, tweenInfo, {Transparency = 0.5})
    local normalStrokeTween = TweenService:Create(ButtonStroke, tweenInfo, {Transparency = 1})

    Button.MouseEnter:Connect(function()
        hoverScaleTween:Play()
        hoverStrokeTween:Play()
    end)
    
    Button.MouseLeave:Connect(function()
        normalScaleTween:Play()
        normalStrokeTween:Play()
    end)

    return Button
end

-- Crear botón de Cerrar (Rojo)
local CloseButton = CreateButton("CloseButton", "Close", CONFIG.CloseColor, 1)
CloseButton.Parent = ButtonsContainer

-- Crear botón de Obtener Script (Verde)
local GetScriptButton = CreateButton("GetScriptButton", "Get New SCRIPT!!!", CONFIG.GetColor, 2)
GetScriptButton.Parent = ButtonsContainer

-- === FUNCIONALIDAD DE LOS BOTONES ===

GetScriptButton.MouseButton1Click:Connect(function()
    -- Copiar al portapapeles si el ejecutor lo soporta
    if setclipboard then
        setclipboard(TARGET_URL)
        -- Pequeña retroalimentación visual al copiar
        GetScriptButton.Text = "URL Copied!"
        task.wait(1.5)
        GetScriptButton.Text = "Get New SCRIPT!!!"
    end
    -- Intentar abrir el navegador directamente
    pcall(function()
        GuiService:OpenBrowserWindow(TARGET_URL)
    end)
end)

CloseButton.MouseButton1Click:Connect(function()
    -- Efecto de desaparición suave al cerrar
    local fadeOutInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    local fadeOut = TweenService:Create(BackgroundFrame, fadeOutInfo, {BackgroundTransparency = 1})
    TweenService:Create(MainPanel, fadeOutInfo, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end)

-- === EFECTO DE APARICIÓN (FADE-IN CON ESCALA) ===
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Iniciar MainPanel más pequeño para el efecto de escala
MainPanel.Size = UDim2.new(0, 0, 0, 0)

TweenService:Create(BackgroundFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.3}):Play() -- Fondo semitransparente
TweenService:Create(MainPanel, tweenInfo, {Size = UDim2.new(0, 480, 0, 260)}):Play()
