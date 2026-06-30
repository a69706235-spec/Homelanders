local Player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui", 5) or Player:FindFirstChildOfClass("PlayerGui")

local SOUND_IM_BETTER = "rbxassetid://ВСТАВЬ_СЮДА_ID_ПЕРВОГО_ФАЙЛА"
local SOUND_YUMMERS   = "rbxassetid://ВСТАВЬ_СЮДА_ID_ВТОРОГО_ФАЙЛА"
local SOUND_LASERS    = "rbxassetid://ВСТАВЬ_СЮДА_ID_ТРЕТЬЕГО_ФАЙЛА"

if PlayerGui then
    local oldGui = PlayerGui:FindFirstChild("HomelanderProUI")
    if oldGui then oldGui:Destroy() end
end

local Flying = false
local CrashEnabled = true 
local ButtonsLocked = false 
local LookWithCamera = true 
local LasersActive = false 
local FlingingActive = false 
local ShiftLockActive = false
local BoostActive = false
local IsBoostingCharging = false

local SpiralActive = false
local SpiralRadius = 15
local SpiralRadiusLevels = {5, 10, 15, 20, 30, 50, 100}
local SpiralRadiusIdx = 3
local spiralSpeed = 0.65 -- Переменная скорости спирали, настраиваемая из GUI

local CharWobbleEnabled = true
local CharWobbleSpeed = 1
local CharWobbleAmplitude = 1

local SpeedLevel = 1
local UpValue = 0
local DownValue = 0
local currentVelocity = Vector3.new(0, 0, 0)
local currentIdleIdx = 1
local currentMoveIdx = 1
local activeEmoteTrack = nil 
local flightStartTime = 0 

local flingOldRootCFrame = nil
local flingOldHeadCFrame = nil

local SpeedTable = {60, 120, 200, 350, 500} 
local idleFadeTime = 0.6    
local idleAnimSpeed = 0.6   
local moveFadeTime = 0.25   
local moveAnimSpeed = 1.2   

local EmoteData = {
    {"Sit", "rbxassetid://112779764845963"},
    {"Layout", "rbxassetid://118613706864437"},
    {"Excuse sir", "rbxassetid://86901687579440"},
    {"Tiki Tiki", "rbxassetid://103418113885418"}
}

local SpeechData = {
    {"IM BETTER", "I don't make mistakes, I'm not just like the rest of you.. I'm stronger, I'm smarter... I'm better. I AM BETTER!!"},
    {"NEED ME", "I am done apologizing. I am done being persecuted for my strength. You people should be thanking Christ that I am who and what I am, because you need me."},
    {"YOUR GOD", "I am your lord, your saviour. I am your God."},
    {"ANYTHING", "I'm the homelander and I can do whatever the #### I want"},
    {"MEMES", "have you seen the memes about me?"},
    {"YUMMERS", "yummers"},
    {"ASHLEY", "Ashley don't look at him look at me! ASHLEY! look. at. me."},
    {"PERFECT", "it was perfect. perfect, down to the last minute detail."},
    {"Pathhetic", "I used to be intimidated by you. I did. And now I look at you, I'm just... I have no idea why. Truly. You're not even pathetic. You're just nothing."},
    {"no im better", "Oh, no, no, no. I'm Better."}
}

local LandingAnim = "rbxassetid://79698004825744" 
local CrashMinSpeed = 40                            
local LandingHeightOffset = 3.2 

local wasMovingInFlight = false
local savedCameraType = Enum.CameraType.Custom

local IdleAnims = {
    "rbxassetid://126046533185038",
    "rbxassetid://96251694399659",
    "rbxassetid://99778215626688",
    "rbxassetid://76981427752730",
    "rbxassetid://125294976115462",
    "rbxassetid://121533979940089", 
    "rbxassetid://108926161397507", 
    "rbxassetid://73980801925168"   
}
local MoveAnims = {
    "rbxassetid://114833664438028", 
    "rbxassetid://101291673584393",
    "rbxassetid://137006704296145" 
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HomelanderProUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local function stopCurrentEmote()
    if activeEmoteTrack then
        activeEmoteTrack:Stop(0.3)
        activeEmoteTrack = nil
    end
end

local function sendToChat(text)
    local TextChatService = game:GetService("TextChatService")
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local rbxGeneral = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if rbxGeneral then rbxGeneral:SendAsync(text) end
    else
        local sayMessageRequest = game:GetService("ReplicatedStorage"):FindFirstChild("SayMessageRequest", true)
        if sayMessageRequest then sayMessageRequest:FireServer(text, "All") end
    end
end

RunService.RenderStepped:Connect(function()
    local Char = Player.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if Hum and activeEmoteTrack and Hum.MoveDirection.Magnitude > 0.01 then
        stopCurrentEmote()
    end
end)

local function createModernBtn(text, pos, size, isSettingStyle)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0, 52, 0, 48) 
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.BackgroundTransparency = isSettingStyle and 0 or 0.35
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(245, 245, 245)
    btn.Font = Enum.Font.GothamBold 
    btn.TextSize = 8 
    btn.TextWrapped = true 
    btn.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12) 
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1.0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn
    
    btn.InputBegan:Connect(function(input)
        if ButtonsLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startPos = btn.Position
            local dragStart = input.Position
            local conn
            conn = UserInputService.InputChanged:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
                    local delta = input2.Position - dragStart
                    btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then conn:Disconnect() end
            end)
        end
    end)
    return btn
end

local LaserBtn     = createModernBtn("Laser\nOFF", UDim2.new(0.05, 0, 0.15, 0))
local ToggleBtn    = createModernBtn("Fly\nOFF", UDim2.new(0.11, 0, 0.15, 0))
local CrashBtn     = createModernBtn("Ground\nON", UDim2.new(0.17, 0, 0.15, 0))
local PoseBtn      = createModernBtn("Idle\nV1", UDim2.new(0.23, 0, 0.15, 0))
local AnimBtn      = createModernBtn("Move\nV1", UDim2.new(0.29, 0, 0.15, 0))
local SpeedBtn     = createModernBtn("Speed\nLvl 1", UDim2.new(0.35, 0, 0.15, 0))
local SettingsBtn  = createModernBtn("Setting", UDim2.new(0.41, 0, 0.15, 0), nil, true)
local SuperJumpBtn = createModernBtn("Super\nJump", UDim2.new(0.47, 0, 0.15, 0))
local SpeedFlyBtn  = createModernBtn("Speed\nFly", UDim2.new(0.53, 0, 0.15, 0)) 
local BoostBtn     = createModernBtn("Boost\nOFF", UDim2.new(0.59, 0, 0.15, 0))
local SpiralBtn    = createModernBtn("Spiral\nOFF", UDim2.new(0.65, 0, 0.15, 0))

local WobbleMenuBtn  = createModernBtn("Wobble\nMenu", UDim2.new(0.23, 0, 0.23, 0))   
local LookBtn        = createModernBtn("Camera-Lock\nON", UDim2.new(0.29, 0, 0.23, 0))
local LockBtn        = createModernBtn("Lock\nOFF", UDim2.new(0.35, 0, 0.23, 0))
local EmoteMenuBtn   = createModernBtn("Emote", UDim2.new(0.41, 0, 0.23, 0))
local SpeechMenuBtn  = createModernBtn("Speech", UDim2.new(0.47, 0, 0.23, 0))
local ShiftLockBtn   = createModernBtn("Shift-Lock\nOFF", UDim2.new(0.53, 0, 0.23, 0))
local SpiralRadiusBtn = createModernBtn("Spiral Rad\n15", UDim2.new(0.59, 0, 0.23, 0))

local UpBtn        = createModernBtn("▲", UDim2.new(0.72, 0, 0.15, 0), UDim2.new(0, 36, 0, 36)) 
local DownBtn      = createModernBtn("▼", UDim2.new(0.75, 0, 0.15, 0), UDim2.new(0, 36, 0, 36)) 

WobbleMenuBtn.Visible = false
LookBtn.Visible = false
LockBtn.Visible = false
EmoteMenuBtn.Visible = false
SpeechMenuBtn.Visible = false
ShiftLockBtn.Visible = false
SpiralRadiusBtn.Visible = false

local WobblePanel = Instance.new("Frame", ScreenGui)
WobblePanel.Size = UDim2.new(0, 165, 0, 48)
WobblePanel.Position = UDim2.new(0.23, 0, 0.31, 0)
WobblePanel.BackgroundTransparency = 1
WobblePanel.Visible = false

local WobbleToggleBtn = createModernBtn("Wobble\nON", UDim2.new(0, 0, 0, 0))
WobbleToggleBtn.Parent = WobblePanel

local WobbleSpdBtn = createModernBtn("Wobble Spd\nx1", UDim2.new(0, 55, 0, 0))
WobbleSpdBtn.Parent = WobblePanel

local WobbleAmpBtn = createModernBtn("Wobble Amp\nx1", UDim2.new(0, 110, 0, 0))
WobbleAmpBtn.Parent = WobblePanel

----------------------------------------------------------------
-- ИНТЕГРАЦИЯ: ГЛАВНОЕ ОКНО НАСТРОЕК И МЕНЮ СПИРАЛИ
----------------------------------------------------------------
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Size = UDim2.new(0, 250, 0, 300)
SettingsFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Active = true
SettingsFrame.Draggable = true
SettingsFrame.Visible = false -- Изначально скрыто, управляется через кнопку Setting
SettingsFrame.Parent = ScreenGui

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, 0, 0, 40)
SettingsTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SettingsTitle.Text = "НАСТРОЙКИ СПИРАЛИ"
SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsTitle.Font = Enum.Font.SourceSansBold
SettingsTitle.TextSize = 18
SettingsTitle.Parent = SettingsFrame

local OpenSpiralButton = Instance.new("TextButton")
OpenSpiralButton.Name = "OpenSpiralButton"
OpenSpiralButton.Size = UDim2.new(0, 210, 0, 40)
OpenSpiralButton.Position = UDim2.new(0, 20, 0, 60)
OpenSpiralButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
OpenSpiralButton.Text = "Открыть меню Спирали"
OpenSpiralButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenSpiralButton.Font = Enum.Font.SourceSans
OpenSpiralButton.TextSize = 16
OpenSpiralButton.Parent = SettingsFrame

local UICorner_OpenBtn = Instance.new("UICorner")
UICorner_OpenBtn.CornerRadius = UDim.new(0, 6)
UICorner_OpenBtn.Parent = OpenSpiralButton

local SpiralMenuFrame = Instance.new("Frame")
SpiralMenuFrame.Name = "SpiralMenuFrame"
SpiralMenuFrame.Size = UDim2.new(0, 220, 0, 200)
SpiralMenuFrame.Position = UDim2.new(0.1, 270, 0, 3) 
SpiralMenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SpiralMenuFrame.BorderSizePixel = 0
SpiralMenuFrame.Visible = false 
SpiralMenuFrame.Active = true
SpiralMenuFrame.Draggable = true
SpiralMenuFrame.Parent = SettingsFrame

local SpiralTitle = Instance.new("TextLabel")
SpiralTitle.Size = UDim2.new(1, 0, 0, 35)
SpiralTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SpiralTitle.Text = "Меню Спирали"
SpiralTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
SpiralTitle.Font = Enum.Font.SourceSansBold
SpiralTitle.TextSize = 16
SpiralTitle.Parent = SpiralMenuFrame

local SpeedTextBox = Instance.new("TextBox")
SpeedTextBox.Name = "SpeedTextBox"
SpeedTextBox.Size = UDim2.new(0, 180, 0, 40)
SpeedTextBox.Position = UDim2.new(0, 20, 0, 70)
SpeedTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedTextBox.Text = tostring(spiralSpeed)
SpeedTextBox.PlaceholderText = "Введите скорость..."
SpeedTextBox.Font = Enum.Font.SourceSans
SpeedTextBox.TextSize = 16
SpeedTextBox.ClearTextOnFocus = false
SpeedTextBox.Parent = SpiralMenuFrame

local UICorner_SpeedBox = Instance.new("UICorner")
UICorner_SpeedBox.CornerRadius = UDim.new(0, 6)
UICorner_SpeedBox.Parent = SpeedTextBox

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 180, 0, 20)
SpeedLabel.Position = UDim2.new(0, 20, 0, 45)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Настройка скорости:"
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.Font = Enum.Font.SourceSans
SpeedLabel.TextSize = 14
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = SpiralMenuFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 180, 0, 30)
StatusLabel.Position = UDim2.new(0, 20, 0, 130)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Текущая скорость: " .. spiralSpeed
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.TextSize = 14
StatusLabel.Parent = SpiralMenuFrame

OpenSpiralButton.MouseButton1Click:Connect(function()
    SpiralMenuFrame.Visible = not SpiralMenuFrame.Visible
    if SpiralMenuFrame.Visible then
        OpenSpiralButton.Text = "Закрыть меню Спирали"
        OpenSpiralButton.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
    else
        OpenSpiralButton.Text = "Открыть меню Спирали"
        OpenSpiralButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end
end)

SpeedTextBox.FocusLost:Connect(function(enterPressed)
    local input = SpeedTextBox.Text
    local numericValue = tonumber(input)
    if numericValue then
        spiralSpeed = numericValue
        StatusLabel.Text = "Текущая скорость: " .. spiralSpeed
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.delay(1, function()
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end)
    else
        SpeedTextBox.Text = tostring(spiralSpeed)
        StatusLabel.Text = "Ошибка! Введите число."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end)
----------------------------------------------------------------

local EmoteContainer = Instance.new("Frame", ScreenGui)
EmoteContainer.Size = UDim2.new(0, 160, 0, 40)
EmoteContainer.Position = UDim2.new(0.41, 0, 0.31, 0)
EmoteContainer.BackgroundTransparency = 1
EmoteContainer.Visible = false

for i, data in ipairs(EmoteData) do
    local eBtn = createModernBtn(data[1], UDim2.new(0, (i-1)*40, 0, 0), UDim2.new(0, 38, 0, 38))
    eBtn.Parent = EmoteContainer
    eBtn.MouseButton1Click:Connect(function()
        local Char = Player.Character
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        if Hum then
            stopCurrentEmote()
            if Flying then StopFlying() end 
            local anim = Instance.new("Animation")
            anim.AnimationId = data[2]
            activeEmoteTrack = Hum:LoadAnimation(anim)
            activeEmoteTrack.Priority = Enum.AnimationPriority.Action
            activeEmoteTrack:Play(0.2)
        end
    end)
end

local SpeechContainer = Instance.new("Frame", ScreenGui)
SpeechContainer.Size = UDim2.new(0, 180, 0, 130)
SpeechContainer.Position = UDim2.new(0.41, 0, 0.41, 0)
SpeechContainer.BackgroundTransparency = 1
SpeechContainer.Visible = false

for i, data in ipairs(SpeechData) do
    local row = math.floor((i - 1) / 3) 
    local col = (i - 1) % 3
    local sBtn = createModernBtn(data[1], UDim2.new(0, col * 55, 0, row * 42), UDim2.new(0, 52, 0, 38))
    sBtn.Parent = SpeechContainer
    sBtn.MouseButton1Click:Connect(function() 
        sendToChat(data[2]) 
        local Char = Player.Character
        local Head = Char and Char:FindFirstChild("Head")
        if Head then
            if data[1] == "IM BETTER" then
                local sound = Instance.new("Sound")
                sound.SoundId = SOUND_IM_BETTER
                sound.Volume = 1
                sound.Parent = Head
                sound:Play()
                game:GetService("Debris"):AddItem(sound, 10)
            elseif data[1] == "YUMMERS" then
                local sound = Instance.new("Sound")
                sound.SoundId = SOUND_YUMMERS
                sound.Volume = 1
                sound.Parent = Head
                sound:Play()
                game:GetService("Debris"):AddItem(sound, 5)
            end
        end
    end)
end

SettingsBtn.MouseButton1Click:Connect(function()
    local targetVisibility = not LookBtn.Visible
    WobbleMenuBtn.Visible = targetVisibility
    LookBtn.Visible = targetVisibility
    LockBtn.Visible = targetVisibility
    EmoteMenuBtn.Visible = targetVisibility
    SpeechMenuBtn.Visible = targetVisibility
    ShiftLockBtn.Visible = targetVisibility
    SpiralRadiusBtn.Visible = targetVisibility
    
    -- Синхронизация отображения фрейма настроек спирали
    SettingsFrame.Visible = targetVisibility
    
    if not targetVisibility then 
        WobblePanel.Visible = false
        EmoteContainer.Visible = false 
        SpeechContainer.Visible = false 
        SpiralMenuFrame.Visible = false
        OpenSpiralButton.Text = "Открыть меню Спирали"
        OpenSpiralButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end
end)

LockBtn.MouseButton1Click:Connect(function()
    ButtonsLocked = not ButtonsLocked
    LockBtn.Text = ButtonsLocked and "Lock\nON" or "Lock\nOFF"
    LockBtn.BackgroundColor3 = ButtonsLocked and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(20, 20, 20)
end)

LookBtn.MouseButton1Click:Connect(function()
    LookWithCamera = not LookWithCamera
    LookBtn.Text = LookWithCamera and "Camera-Lock\nON" or "Camera-Lock\nOFF"
    LookBtn.BackgroundColor3 = LookWithCamera and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(150, 0, 0)
end)

ShiftLockBtn.MouseButton1Click:Connect(function()
    ShiftLockActive = not ShiftLockActive
    ShiftLockBtn.Text = ShiftLockActive and "Shift-Lock\nON" or "Shift-Lock\nOFF"
    ShiftLockBtn.BackgroundColor3 = ShiftLockActive and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(20, 20, 20)
end)

WobbleMenuBtn.MouseButton1Click:Connect(function()
    WobblePanel.Visible = not WobblePanel.Visible
    if WobblePanel.Visible then EmoteContainer.Visible = false; SpeechContainer.Visible = false end
end)

WobbleToggleBtn.MouseButton1Click:Connect(function()
    CharWobbleEnabled = not CharWobbleEnabled
    WobbleToggleBtn.Text = CharWobbleEnabled and "Wobble\nON" or "Wobble\nOFF"
    WobbleToggleBtn.BackgroundColor3 = CharWobbleEnabled and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(150, 0, 0)
end)

local speedLevels = {1, 1.5, 2, 3, 5, 8, 0.5}
local currentSpdIdx = 1
WobbleSpdBtn.MouseButton1Click:Connect(function()
    currentSpdIdx = (currentSpdIdx % #speedLevels) + 1
    CharWobbleSpeed = speedLevels[currentSpdIdx]
    WobbleSpdBtn.Text = "Wobble Spd\nx" .. CharWobbleSpeed
end)

local ampLevels = {1, 2, 3, 5, 8, 15, 0.5}
local currentAmpIdx = 1
WobbleAmpBtn.MouseButton1Click:Connect(function()
    currentAmpIdx = (currentAmpIdx % #ampLevels) + 1
    CharWobbleAmplitude = ampLevels[currentAmpIdx]
    WobbleAmpBtn.Text = "Wobble Amp\nx" .. CharWobbleAmplitude
end)

EmoteMenuBtn.MouseButton1Click:Connect(function() 
    EmoteContainer.Visible = not EmoteContainer.Visible 
    if EmoteContainer.Visible then WobblePanel.Visible = false; SpeechContainer.Visible = false end
end)
SpeechMenuBtn.MouseButton1Click:Connect(function() 
    SpeechContainer.Visible = not SpeechContainer.Visible 
    if SpeechContainer.Visible then WobblePanel.Visible = false; EmoteContainer.Visible = false end
end)

local function flingTarget(targetChar)
    if FlingingActive then return end
    FlingingActive = true
    
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myHead = myChar and myChar:FindFirstChild("Head")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if myRoot and targetRoot and myHum and myHead then
        flingOldRootCFrame = myRoot.CFrame
        flingOldHeadCFrame = myHead.CFrame
        
        local savedCFrame = myRoot.CFrame
        local savedVelocity = myRoot.AssemblyLinearVelocity
        local savedAngular = myRoot.AssemblyAngularVelocity
        
        if bv then bv.MaxForce = Vector3.zero end
        if bg then bg.MaxTorque = Vector3.zero end
        
        local oldCameraType = Camera.CameraType
        local savedCamCFrame = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
        
        myChar.Archivable = true
        local fakeClone = myChar:Clone()
        myChar.Archivable = false
        fakeClone.Name = "FakeLocalClone"
        fakeClone.Parent = workspace
        
        for _, part in ipairs(fakeClone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            elseif part:IsA("Script") or part:IsA("LocalScript") then
                part:Destroy()
            end
        end
        
        local savedTransparencies = {}
        local savedCollides = {}
        
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then
                savedTransparencies[part] = part.Transparency
                savedCollides[part] = part.CanCollide
                part.Transparency = 1 
                if part.Name ~= "HumanoidRootPart" then part.CanCollide = false end
            end
        end
        
        for i = 1, 2 do
            if not targetRoot or not targetRoot.Parent or not myRoot or not myRoot.Parent then break end
            Camera.CFrame = savedCamCFrame 
            myRoot.CFrame = targetRoot.CFrame * CFrame.Angles(0, math.rad(i * 180), 0)
            myRoot.AssemblyLinearVelocity = Vector3.new(9999, 9999, 9999) 
            myRoot.AssemblyAngularVelocity = Vector3.new(50000, 50000, 50000) 
            RunService.Heartbeat:Wait()
        end
        
        if myRoot and myRoot.Parent then
            myRoot.CFrame = savedCFrame
            myRoot.AssemblyLinearVelocity = savedVelocity
            myRoot.AssemblyAngularVelocity = savedAngular
        end
        
        for part, origTrans in pairs(savedTransparencies) do
            if part and part.Parent then part.Transparency = origTrans end
        end
        for part, origCollide in pairs(savedCollides) do
            if part and part.Parent then part.CanCollide = origCollide end
        end
        
        if fakeClone then fakeClone:Destroy() end
        Camera.CameraType = oldCameraType
        Camera.CFrame = savedCamCFrame
        
        if bv then bv.MaxForce = Vector3.new(1e6, 1e6, 1e6) end
        if bg then bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6) end
    end
    
    flingOldRootCFrame = nil
    flingOldHeadCFrame = nil
    task.wait(0.05) 
    FlingingActive = false
end

local leftLaserPart, rightLaserPart, faceLight, laserAnimTrack, introAnimTrack
local laserConnection
local laserSound 
local laserSession = 0 
local laserAnimId = "rbxassetid://127165725254450"
local introAnimId = "rbxassetid://70399811795186"

local function removeLasers()
    laserSession = laserSession + 1 
    if laserConnection then laserConnection:Disconnect() laserConnection = nil end
    if leftLaserPart then leftLaserPart:Destroy() leftLaserPart = nil end
    if rightLaserPart then rightLaserPart:Destroy() rightLaserPart = nil end
    if faceLight then faceLight:Destroy() faceLight = nil end
    if laserAnimTrack then laserAnimTrack:Stop(0.45); laserAnimTrack = nil end
    if introAnimTrack then introAnimTrack:Stop(0.45); introAnimTrack = nil end
    if laserSound then
        laserSound:Stop()
        laserSound:Destroy()
        laserSound = nil
    end
end

local function createLaserPart()
    local p = Instance.new("Part")
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromRGB(255, 20, 20)
    p.Transparency = 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Parent = workspace
    return p
end

local function toggleLasers()
    LasersActive = not LasersActive
    local Char = Player.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    removeLasers() 
    
    if LasersActive then
        local currentSession = laserSession 
        LaserBtn.Text = "Laser\nON"
        LaserBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        
        task.spawn(function()
            task.wait(0.5)
            if laserSession ~= currentSession or not LasersActive then return end
            local Head = Char and Char:FindFirstChild("Head")
            if Head then
                laserSound = Instance.new("Sound")
                laserSound.SoundId = SOUND_LASERS
                laserSound.Volume = 1
                laserSound.Looped = true 
                laserSound.Parent = Head
                laserSound:Play()
            end
        end)
        
        task.spawn(function()
            if Hum then
                local introAnim = Instance.new("Animation")
                introAnim.AnimationId = introAnimId
                introAnimTrack = Hum:LoadAnimation(introAnim)
                introAnimTrack.Priority = Enum.AnimationPriority.Action4
                introAnimTrack:Play(0.6)
                
                local elapsed = 0
                while introAnimTrack.Length == 0 and elapsed < 0.5 do
                    RunService.Heartbeat:Wait()
                    if laserSession ~= currentSession or not LasersActive then
                        if introAnimTrack then introAnimTrack:Stop(0) end
                        return
                    end
                    elapsed = elapsed + 0.015
                end
                task.wait(0.02)
                
                if laserSession ~= currentSession or not LasersActive then 
                    if introAnimTrack then introAnimTrack:Stop(0) end
                    return 
                end
                
                local startCut = introAnimTrack.Length * 0.3
                local durationCut = introAnimTrack.Length * 0.15
                introAnimTrack.TimePosition = startCut
                task.wait(durationCut)
                
                if laserSession ~= currentSession or not LasersActive then 
                    if introAnimTrack then introAnimTrack:Stop(0) end
                    return 
                end
                
                local mainAnim = Instance.new("Animation")
                mainAnim.AnimationId = laserAnimId
                laserAnimTrack = Hum:LoadAnimation(mainAnim)
                laserAnimTrack.Priority = Enum.AnimationPriority.Action4
                laserAnimTrack:Play(0.45)
                introAnimTrack:Stop(0.45)
            end
            
            local Head = Char and Char:FindFirstChild("Head")
            if not Head then removeLasers() return end
            
            if not faceLight then
                faceLight = Instance.new("PointLight")
                faceLight.Color = Color3.fromRGB(255, 0, 0)
                faceLight.Range = 15
                faceLight.Brightness = 10
                faceLight.Parent = Head
            end
            
            laserConnection = RunService.RenderStepped:Connect(function()
                if laserSession ~= currentSession or not LasersActive then
                    removeLasers()
                    return
                end
                
                local CurrentChar = Player.Character
                local CurrentHead = CurrentChar and CurrentChar:FindFirstChild("Head")
                if not CurrentHead then removeLasers() return end
                
                if not leftLaserPart or not leftLaserPart.Parent then
                    leftLaserPart = createLaserPart()
                    rightLaserPart = createLaserPart()
                end
                
                local headCFrame = CurrentHead.CFrame
                local lookVector = CurrentHead.CFrame.LookVector
                if FlingingActive and flingOldHeadCFrame then
                    headCFrame = flingOldHeadCFrame
                    lookVector = flingOldHeadCFrame.LookVector
                end
                
                local rParams = RaycastParams.new()
                rParams.FilterDescendantsInstances = {CurrentChar}
                if workspace:FindFirstChild("FakeLocalClone") then
                    table.insert(rParams.FilterDescendantsInstances, workspace.FakeLocalClone)
                end
                rParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local rayResult = workspace:Raycast(headCFrame.Position, lookVector * 500, rParams)
                local hitPoint = rayResult and rayResult.Position or (headCFrame.Position + lookVector * 500)
                
                if rayResult and rayResult.Instance and not FlingingActive then
                    local hitModel = rayResult.Instance:FindFirstAncestorOfClass("Model")
                    if hitModel and hitModel ~= CurrentChar then
                        local targetHum = hitModel:FindFirstChildOfClass("Humanoid")
                        if targetHum and targetHum.Health > 0 then
                            task.spawn(flingTarget, hitModel)
                        end
                    end
                end
                
                local leftEye = (headCFrame * CFrame.new(-0.22, 0.15, -0.55)).Position
                local rightEye = (headCFrame * CFrame.new(0.22, 0.15, -0.55)).Position
                local lDist = (hitPoint - leftEye).Magnitude
                leftLaserPart.Size = Vector3.new(0.18, 0.18, lDist)
                leftLaserPart.CFrame = CFrame.lookAt(leftEye, hitPoint) * CFrame.new(0, 0, -lDist/2)
                
                local rDist = (hitPoint - rightEye).Magnitude
                rDist = rDist > 0 and rDist or 0.1
                rightLaserPart.Size = Vector3.new(0.18, 0.18, rDist)
                rightLaserPart.CFrame = CFrame.lookAt(rightEye, hitPoint) * CFrame.new(0, 0, -rDist/2)
            end)
        end)
    else
        LaserBtn.Text = "Laser\nOFF"
        LaserBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        if Hum then Hum.AutoRotate = true end
    end
end

LaserBtn.MouseButton1Click:Connect(toggleLasers)

local bv, bg, activeTrack, boostFlyTrack
local idleTracks, moveTracks = {}, {}

local function loadTracks(Hum)
    idleTracks, moveTracks = {}, {}
    for i, id in ipairs(IdleAnims) do
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local success, track = pcall(function() return Hum:LoadAnimation(anim) end)
        if success and track then track.Priority = Enum.AnimationPriority.Action; track.Looped = true; idleTracks[i] = track end
    end
    for i, id in ipairs(MoveAnims) do
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local success, track = pcall(function() return Hum:LoadAnimation(anim) end)
        if success and track then track.Priority = Enum.AnimationPriority.Action; track.Looped = true; moveTracks[i] = track end
    end
end

function StopFlying()
    if WobblePanel.Visible then WobblePanel.Visible = false end
    Flying = false
    BoostActive = false
    IsBoostingCharging = false
    ToggleBtn.Text = "Fly\nOFF"
    SpeedFlyBtn.Text = "Speed\nFly"
    BoostBtn.Text = "Boost\nOFF"
    BoostBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    
    local Char = Player.Character
    if Char then
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChildOfClass("Humanoid")
        if Root then
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            Root.Anchored = true
            task.wait(0.05)
            Root.Anchored = false
        end
        if Hum then 
            Hum.PlatformStand = false 
            Hum.AutoRotate = true 
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    if activeTrack then activeTrack:Stop(0.6) activeTrack = nil end 
    if boostFlyTrack then boostFlyTrack:Stop(0.3) boostFlyTrack = nil end
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() end
    if wasMovingInFlight then
        wasMovingInFlight = false
        Camera.CameraType = savedCameraType
    end
end

function StartFlying()
    local Char = Player.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local Root = Char.HumanoidRootPart
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    stopCurrentEmote()
    if Hum then
        Hum.AutoRotate = false
        Hum.PlatformStand = true 
        loadTracks(Hum)
    end
    Flying = true
    ToggleBtn.Text = "Fly\nON"
    flightStartTime = os.clock()
    
    Root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    currentVelocity = Vector3.new(0, 0, 0)
    
    bv = Instance.new("BodyVelocity", Root)
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.new(0, 0, 0)
    
    bg = Instance.new("BodyGyro", Root)
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6) 
    bg.P = 1000000 
    bg.D = 9000   
    bg.CFrame = Root.CFrame
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local wasMovingLastFrame = false
    local savedIdlePos = nil 
    local currentBank = 0

    task.spawn(function()
        while Flying and Root and Root.Parent do
            local currentHum = Char:FindFirstChildOfClass("Humanoid")
            if not currentHum then break end
            
            if not FlingingActive then
                if IsBoostingCharging then
                    if bv then bv.Velocity = Vector3.zero end
                    currentVelocity = Vector3.zero
                else
                    local moveDir = currentHum.MoveDirection
                    local isMoving = moveDir.Magnitude > 0.05 or UpValue ~= 0 or DownValue ~= 0
                    if not isMoving and BoostActive then
                        BoostActive = false
                        BoostBtn.Text = "Boost\nOFF"
                        BoostBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    end
                    
                    local speed = SpeedTable[SpeedLevel] or 60
                    if BoostActive then speed = speed * 4 end 
                    
                    local targetVelocity = Vector3.new(0, 0, 0)
                    local verticalVel = 0
                    if moveDir.Magnitude > 0.05 then verticalVel = Camera.CFrame.LookVector.Y * speed end
                    local manualVertical = (UpValue - DownValue) * (speed * 0.5)
                    verticalVel = verticalVel + manualVertical
                    local moveVel = (moveDir * speed) + Vector3.new(0, verticalVel, 0)
                    
                    if isMoving then
                        savedIdlePos = nil 
                        wasMovingLastFrame = true
                        targetVelocity = moveVel
                        if bv then
                            bv.Velocity = bv.Velocity:Lerp(targetVelocity, 0.08)
                            currentVelocity = bv.Velocity
                        end
                    else
                        if wasMovingLastFrame then
                            wasMovingLastFrame = false
                            Root.AssemblyLinearVelocity = Vector3.zero
                            if bv then bv.Velocity = Vector3.zero end
                        end
                        if not savedIdlePos then savedIdlePos = Root.Position end
                        if CharWobbleEnabled and savedIdlePos then
                            local t = os.clock() * 0.7 * CharWobbleSpeed
                            local nX = math.noise(t, 14.23, 5.12) * 2.5 * CharWobbleAmplitude
                            local nY = math.noise(7.41, t, 19.85) * 1.8 * CharWobbleAmplitude
                            local nZ = math.noise(23.11, 11.45, t) * 2.5 * CharWobbleAmplitude
                            local targetPos = savedIdlePos + Vector3.new(nX, nY, nZ)
                            targetVelocity = (targetPos - Root.Position) * 4.5
                        end
                        if bv then
                            bv.Velocity = targetVelocity
                            currentVelocity = targetVelocity
                        end
                    end
                    
                    local isMovingAnim = moveDir.Magnitude > 0.05
                    local targetTrack
                    if BoostActive and isMovingAnim then
                        if not boostFlyTrack or boostFlyTrack.Animation.AnimationId ~= "rbxassetid://131114687716793" then
                            local anim = Instance.new("Animation")
                            anim.AnimationId = "rbxassetid://131114687716793"
                            boostFlyTrack = currentHum:LoadAnimation(anim)
                            boostFlyTrack.Priority = Enum.AnimationPriority.Action4
                            boostFlyTrack.Looped = true
                        end
                        targetTrack = boostFlyTrack
                    else
                        targetTrack = isMovingAnim and moveTracks[currentMoveIdx] or idleTracks[currentIdleIdx]
                    end
                    
                    if targetTrack and targetTrack ~= activeTrack and Flying then
                        local fade = isMovingAnim and moveFadeTime or idleFadeTime
                        if activeTrack then activeTrack:Stop(fade) end
                        activeTrack = targetTrack
                        activeTrack:Play(fade)
                        if targetTrack == boostFlyTrack then
                            activeTrack:AdjustSpeed(1.2)
                        else
                            activeTrack:AdjustSpeed(isMovingAnim and moveAnimSpeed or idleAnimSpeed)
                        end
                    end
                    
                    if CrashEnabled and (os.clock() - flightStartTime) > 1.0 and currentVelocity.Magnitude > CrashMinSpeed then
                        local lookAheadDistance = math.max(currentVelocity.Magnitude * 0.05, 10)
                        local raycastResult = workspace:Raycast(Root.Position, currentVelocity.Unit * lookAheadDistance, raycastParams)
                        if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
                            local currentDist = (Root.Position - raycastResult.Position).Magnitude
                            if currentDist <= 8 then
                                local hitPos = raycastResult.Position
                                StopFlying() 
                                Root.AssemblyLinearVelocity = Vector3.zero
                                Root.AssemblyAngularVelocity = Vector3.zero
                                local _, yRotation, _ = Root.CFrame:ToEulerAnglesYXZ()
                                local targetCFrame = CFrame.new(hitPos + Vector3.new(0, LandingHeightOffset, 0)) * CFrame.Angles(0, yRotation, 0)
                                local landTween = TweenService:Create(Root, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
                                local landAnimInstance = Instance.new("Animation")
                                landAnimInstance.AnimationId = LandingAnim
                                local success, landTrack = pcall(function() return currentHum:LoadAnimation(landAnimInstance) end)
                                if success and landTrack then
                                    landTrack.Priority = Enum.AnimationPriority.Action4
                                    landTrack:Play(0.1) 
                                end
                                landTween:Play()
                                landTween.Completed:Wait() 
                                Root.Anchored = true 
                                task.wait(1.5) 
                                Root.Anchored = false
                                if landTrack then landTrack:Stop(0.5) end
                                local uprightCFrame = CFrame.new(Root.Position) * CFrame.Angles(0, yRotation, 0)
                                local standTween = TweenService:Create(Root, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = uprightCFrame})
                                standTween:Play()
                                standTween.Completed:Wait() 
                                currentHum.PlatformStand = false
                                currentHum.AutoRotate = true
                                break 
                            end
                        end
                    end
                    
                    if isMoving then
                        if not wasMovingInFlight then wasMovingInFlight = true; savedCameraType = Camera.CameraType; Camera.CameraType = Enum.CameraType.Custom end
                        if moveVel.Magnitude > 0.01 then
                            local lookDir
                            if ShiftLockActive then
                                lookDir = Camera.CFrame.LookVector
                            else
                                local horizontalDir = Vector3.new(moveVel.X, 0, moveVel.Z)
                                if horizontalDir.Magnitude > 0.1 then
                                    lookDir = moveVel.Unit
                                else
                                    local camLook = Camera.CFrame.LookVector
                                    lookDir = Vector3.new(camLook.X, 0, camLook.Z).Unit
                                    if lookDir.Magnitude < 0.01 then lookDir = Root.CFrame.LookVector end
                                end
                            end
                            local relativeMove = Camera.CFrame:VectorToObjectSpace(moveDir)
                            local targetBank = 0
                            if moveDir.Magnitude > 0.05 then targetBank = -relativeMove.X * math.rad(25) end
                            currentBank = currentBank + (targetBank - currentBank) * 0.1
                            local targetRotation = CFrame.lookAt(Root.Position, Root.Position + lookDir, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, currentBank)
                            bg.CFrame = bg.CFrame:Lerp(targetRotation, 0.15) 
                        end
                    else
                        currentBank = currentBank + (0 - currentBank) * 0.1
                        if wasMovingInFlight then wasMovingInFlight = false; Camera.CameraType = savedCameraType end
                        if ShiftLockActive or LookWithCamera then
                            local camLook = Camera.CFrame.LookVector
                            if camLook.Magnitude > 0.01 then
                                local targetRotation = CFrame.lookAt(Root.Position, Root.Position + camLook, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, currentBank)
                                bg.CFrame = bg.CFrame:Lerp(targetRotation, 0.12) 
                            end
                        else
                            local _, yRotation, _ = bg.CFrame:ToEulerAnglesYXZ()
                            bg.CFrame = bg.CFrame:Lerp(CFrame.new(Root.Position) * CFrame.Angles(0, yRotation, 0) * CFrame.Angles(0, 0, currentBank), 0.12) 
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

function StartSpeedFlying()
    local Char = Player.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local Root = Char.HumanoidRootPart
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    local Animator = Hum:FindFirstChildOfClass("Animator") or Hum:WaitForChild("Animator", 2)
    
    stopCurrentEmote()
    if activeTrack then activeTrack:Stop() activeTrack = nil end
    
    Flying = true
    ToggleBtn.Text = "Fly\nON"   
    SpeedFlyBtn.Text = "Speed\nFly" 
    flightStartTime = os.clock()
    
    local EMOTE_ID = "rbxassetid://132168338773523"
    local FLY_ANIM_ID = "rbxassetid://114833664438028"
    local START_TIME = 1.0 
    local DURATION = 1.0 
    local DASH_DURATION = 3.5 
    local FLY_SPEED = 120 
    local UPWARD_SPEED = 25 
    local FADE_TIME = 0.4 
    
    if Hum then
        Hum.AutoRotate = false
        Hum.PlatformStand = true 
        loadTracks(Hum)
    end
    Root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.new(0, 0, 0) 
    bv.Parent = Root
    
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6) 
    bg.P = 1000000 
    bg.D = 9000 
    bg.CFrame = Root.CFrame
    bg.Parent = Root

    local emoteAnim = Instance.new("Animation")
    emoteAnim.AnimationId = EMOTE_ID
    local emoteTrack = Animator:LoadAnimation(emoteAnim)
    emoteTrack.Priority = Enum.AnimationPriority.Action4
    emoteTrack:Play(0.5) 
    
    local elapsed = 0
    while emoteTrack.Length == 0 and elapsed < 0.5 do
        RunService.Heartbeat:Wait()
        elapsed = elapsed + 0.015
    end
    task.wait(0.05)
    if not Flying then return end
    emoteTrack.TimePosition = START_TIME 
    task.wait(DURATION)
    if not Flying or not Root.Parent or not Hum then return end
    emoteTrack:AdjustSpeed(0) 
    
    local flyAnim = Instance.new("Animation")
    flyAnim.AnimationId = FLY_ANIM_ID
    local flyTrack = Animator:LoadAnimation(flyAnim)
    flyTrack.Priority = Enum.AnimationPriority.Action
    flyTrack.Looped = true
    
    flyTrack:Play(FADE_TIME)
    emoteTrack:Stop(FADE_TIME)
    activeTrack = flyTrack
    activeTrack:AdjustSpeed(moveAnimSpeed)
    
    local startSpeed = FLY_SPEED
    if BoostActive then startSpeed = startSpeed * 4 end 
    currentVelocity = (Root.CFrame.LookVector * startSpeed) + Vector3.new(0, UPWARD_SPEED, 0)
    bv.Velocity = currentVelocity
    task.wait(0.1)
    if emoteTrack then emoteTrack:Destroy() end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local wasMovingLastFrame = false
    local savedIdlePos = nil
    local currentBank = 0

    task.spawn(function()
        while Flying and Root and Root.Parent do
            local currentHum = Char:FindFirstChildOfClass("Humanoid")
            if not currentHum then break end
            
            if not FlingingActive then
                if IsBoostingCharging then
                    if bv then bv.Velocity = Vector3.zero end
                    currentVelocity = Vector3.zero
                else
                    local moveDir = currentHum.MoveDirection
                    local isMoving = moveDir.Magnitude > 0.05 or UpValue ~= 0 or DownValue ~= 0
                    if os.clock() - flightStartTime > (DURATION + DASH_DURATION) and not isMoving and BoostActive then
                        BoostActive = false
                        BoostBtn.Text = "Boost\nOFF"
                        BoostBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    end
                    local speed = SpeedTable[SpeedLevel] or 60
                    if BoostActive then speed = speed * 4 end 
                    
                    local verticalVel = 0
                    if moveDir.Magnitude > 0.05 then verticalVel = Camera.CFrame.LookVector.Y * speed end
                    local manualVertical = (UpValue - DownValue) * (speed * 0.5)
                    verticalVel = verticalVel + manualVertical
                    local moveVel = (moveDir * speed) + Vector3.new(0, verticalVel, 0)
                    
                    if os.clock() - flightStartTime > (DURATION + DASH_DURATION) then
                        local targetVelocity = Vector3.new(0, 0, 0)
                        if isMoving then
                            savedIdlePos = nil
                            wasMovingLastFrame = true
                            targetVelocity = moveVel
                            if bv then
                                bv.Velocity = bv.Velocity:Lerp(targetVelocity, 0.08)
                                currentVelocity = bv.Velocity
                            end
                        else
                            if wasMovingLastFrame then
                                wasMovingLastFrame = false
                                Root.AssemblyLinearVelocity = Vector3.zero
                                if bv then bv.Velocity = Vector3.zero end
                            end
                            if not savedIdlePos then savedIdlePos = Root.Position end
                            if CharWobbleEnabled and savedIdlePos then
                                local t = os.clock() * 0.7 * CharWobbleSpeed
                                local nX = math.noise(t, 14.23, 5.12) * 2.5 * CharWobbleAmplitude
                                local nY = math.noise(7.41, t, 19.85) * 1.8 * CharWobbleAmplitude
                                local targetPos = savedIdlePos + Vector3.new(nX, nY, math.noise(23.11, 11.45, t) * 2.5 * CharWobbleAmplitude)
                                targetVelocity = (targetPos - Root.Position) * 4.5
                            end
                            if bv then
                                bv.Velocity = targetVelocity
                                currentVelocity = targetVelocity
                            end
                        end
                        local isMovingAnim = moveDir.Magnitude > 0.05
                        local targetTrack
                        if BoostActive and isMovingAnim then
                            if not boostFlyTrack or boostFlyTrack.Animation.AnimationId ~= "rbxassetid://131114687716793" then
                                local anim = Instance.new("Animation")
                                anim.AnimationId = "rbxassetid://131114687716793"
                                boostFlyTrack = currentHum:LoadAnimation(anim)
                                boostFlyTrack.Priority = Enum.AnimationPriority.Action4
                                boostFlyTrack.Looped = true
                            end
                            targetTrack = boostFlyTrack
                        else
                            targetTrack = isMovingAnim and moveTracks[currentMoveIdx] or idleTracks[currentIdleIdx]
                        end
                        if targetTrack and targetTrack ~= activeTrack and Flying then
                            local fade = isMovingAnim and moveFadeTime or idleFadeTime
                            if activeTrack then activeTrack:Stop(fade) end
                            activeTrack = targetTrack
                            activeTrack:Play(fade)
                            if targetTrack == boostFlyTrack then
                                activeTrack:AdjustSpeed(1.2)
                            else
                                activeTrack:AdjustSpeed(isMovingAnim and moveAnimSpeed or idleFadeTime)
                            end
                        end
                    else
                        if bv then
                            local dashSpeed = FLY_SPEED
                            if BoostActive then dashSpeed = dashSpeed * 4 end 
                            currentVelocity = (Root.CFrame.LookVector * dashSpeed) + Vector3.new(0, UPWARD_SPEED, 0)
                            if CharWobbleEnabled then
                                local t = os.clock() * 4.5 * CharWobbleSpeed
                                local transAmp = 2 * CharWobbleAmplitude
                                local dashZigzagY = (math.sin(t * 3.2) + math.cos(t * 6.4) * 0.25) * 0.5
                                local wobbleMove = Vector3.new(math.sin(t), dashZigzagY, math.cos(t)) * transAmp
                                currentVelocity = currentVelocity + Root.CFrame:VectorToWorldSpace(wobbleMove)
                            end
                            bv.Velocity = bv.Velocity:Lerp(currentVelocity, 0.1)
                        end
                    end
                    
                    if CrashEnabled and (os.clock() - flightStartTime) > (DURATION + 1.0) and currentVelocity.Magnitude > CrashMinSpeed then
                        local lookAheadDistance = math.max(currentVelocity.Magnitude * 0.05, 10)
                        local raycastResult = workspace:Raycast(Root.Position, currentVelocity.Unit * lookAheadDistance, raycastParams)
                        if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
                            local currentDist = (Root.Position - raycastResult.Position).Magnitude
                            if currentDist <= 8 then
                                local hitPos = raycastResult.Position
                                StopFlying() 
                                Root.AssemblyLinearVelocity = Vector3.zero
                                Root.AssemblyAngularVelocity = Vector3.zero
                                local _, yRotation, _ = Root.CFrame:ToEulerAnglesYXZ()
                                local targetCFrame = CFrame.new(hitPos + Vector3.new(0, LandingHeightOffset, 0)) * CFrame.Angles(0, yRotation, 0)
                                local landTween = TweenService:Create(Root, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
                                local landAnimInstance = Instance.new("Animation")
                                landAnimInstance.AnimationId = LandingAnim
                                local success, landTrack = pcall(function() return currentHum:LoadAnimation(landAnimInstance) end)
                                if success and landTrack then
                                    landTrack.Priority = Enum.AnimationPriority.Action4
                                    landTrack:Play(0.1) 
                                end
                                landTween:Play()
                                landTween.Completed:Wait() 
                                Root.Anchored = true 
                                task.wait(1.5) 
                                Root.Anchored = false
                                if landTrack then landTrack:Stop(0.5) end
                                local uprightCFrame = CFrame.new(Root.Position) * CFrame.Angles(0, yRotation, 0)
                                local standTween = TweenService:Create(Root, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = uprightCFrame})
                                standTween:Play()
                                standTween.Completed:Wait() 
                                currentHum.PlatformStand = false
                                currentHum.AutoRotate = true
                                break 
                            end
                        end
                    end
                    
                    if os.clock() - flightStartTime > (DURATION + DASH_DURATION) then
                        local isMoving = moveDir.Magnitude > 0.05
                        if isMoving then
                            if not wasMovingInFlight then wasMovingInFlight = true; savedCameraType = Camera.CameraType; Camera.CameraType = Enum.CameraType.Custom end
                            if moveVel.Magnitude > 0.01 then
                                local lookDir
                                if ShiftLockActive then
                                    lookDir = Camera.CFrame.LookVector
                                else
                                    local horizontalDir = Vector3.new(moveVel.X, 0, moveVel.Z)
                                    if horizontalDir.Magnitude > 0.1 then
                                        lookDir = moveVel.Unit
                                    else
                                        local camLook = Camera.CFrame.LookVector
                                        lookDir = Vector3.new(camLook.X, 0, camLook.Z).Unit
                                        if lookDir.Magnitude < 0.01 then lookDir = Root.CFrame.LookVector end
                                    end
                                end
                                local relativeMove = Camera.CFrame:VectorToObjectSpace(moveDir)
                                local targetBank = 0
                                if moveDir.Magnitude > 0.05 then targetBank = -relativeMove.X * math.rad(25) end
                                currentBank = currentBank + (targetBank - currentBank) * 0.1
                                local targetRotation = CFrame.lookAt(Root.Position, Root.Position + lookDir, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, currentBank)
                                bg.CFrame = bg.CFrame:Lerp(targetRotation, 0.15)
                            end
                        else
                            currentBank = currentBank + (0 - currentBank) * 0.1
                            if wasMovingInFlight then wasMovingInFlight = false; Camera.CameraType = savedCameraType end
                            if ShiftLockActive or LookWithCamera then
                                local camLook = Camera.CFrame.LookVector
                                if camLook.Magnitude > 0.01 then
                                    local targetRotation = CFrame.lookAt(Root.Position, Root.Position + camLook, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, currentBank)
                                    bg.CFrame = bg.CFrame:Lerp(targetRotation, 0.12)
                                end
                            else
                                local _, yRotation, _ = bg.CFrame:ToEulerAnglesYXZ()
                                bg.CFrame = bg.CFrame:Lerp(CFrame.new(Root.Position) * CFrame.Angles(0, yRotation, 0) * CFrame.Angles(0, 0, currentBank), 0.12)
                            end
                        end
                    else
                        currentBank = currentBank + (0 - currentBank) * 0.1
                        if (ShiftLockActive or LookWithCamera) and bg then
                            local camLook = Camera.CFrame.LookVector
                            if camLook.Magnitude > 0.01 then
                                local targetRotation = CFrame.lookAt(Root.Position, Root.Position + camLook, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, currentBank)
                                bg.CFrame = bg.CFrame:Lerp(targetRotation, 0.15)
                            end
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

BoostBtn.MouseButton1Click:Connect(function()
    if not Flying or IsBoostingCharging or BoostActive then return end 
    IsBoostingCharging = true
    BoostBtn.Text = "Boost\nCHRG"
    BoostBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    
    local Char = Player.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if Hum then
        for _, track in pairs(Hum:GetPlayingAnimationTracks()) do track:Stop(0.1) end
        activeTrack = nil
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://127528880902667"
        local track = Hum:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action4
        track:Play()
        task.wait(0.8)
        track:Stop(0.1)
    else
        task.wait(0.8)
    end
    if not Flying then 
        IsBoostingCharging = false
        BoostActive = false
        BoostBtn.Text = "Boost\nOFF"
        BoostBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        return 
    end
    IsBoostingCharging = false
    BoostActive = true
    BoostBtn.Text = "Boost\nON"
    BoostBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if Root and bv then
        local speed = SpeedTable[SpeedLevel] or 60
        bv.Velocity = Root.CFrame.LookVector * (speed * 4) 
    end
end)

ToggleBtn.MouseButton1Click:Connect(function() if Flying then StopFlying() else StartFlying() end end)
SpeedFlyBtn.MouseButton1Click:Connect(function() if Flying then StopFlying() else StartSpeedFlying() end end)
CrashBtn.MouseButton1Click:Connect(function() CrashEnabled = not CrashEnabled; CrashBtn.Text = CrashEnabled and "Ground\nON" or "Ground\nOFF" end)

PoseBtn.MouseButton1Click:Connect(function() 
    currentIdleIdx = (currentIdleIdx % #IdleAnims) + 1 
    PoseBtn.Text = "Idle\nV" .. currentIdleIdx 
end)

AnimBtn.MouseButton1Click:Connect(function() currentMoveIdx = (currentMoveIdx % 3) + 1; AnimBtn.Text = "Move\nV" .. currentMoveIdx end)
SpeedBtn.MouseButton1Click:Connect(function() SpeedLevel = (SpeedLevel % 5) + 1; SpeedBtn.Text = "Speed\nLvl " .. SpeedLevel end)
UpBtn.MouseButton1Down:Connect(function() UpValue = 1 end)
UpBtn.MouseButton1Up:Connect(function() UpValue = 0 end)
DownBtn.MouseButton1Down:Connect(function() DownValue = 1 end)
DownBtn.MouseButton1Up:Connect(function() DownValue = 0 end)

SuperJumpBtn.MouseButton1Click:Connect(function()
    if Flying then StopFlying() end
    local Char = Player.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChild("Humanoid")
    if Root and Hum then
        local chargeAnim = Instance.new("Animation")
        chargeAnim.AnimationId = "rbxassetid://127610911773857"
        local chargeTrack = Hum:LoadAnimation(chargeAnim)
        chargeTrack.Priority = Enum.AnimationPriority.Action3
        chargeTrack:Play(0.3)
        task.wait(0.8)
        chargeTrack:Stop(0.1)
        
        Hum.PlatformStand = true
        Hum.AutoRotate = false
        local jumpVelocity = Instance.new("BodyVelocity", Root)
        jumpVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        jumpVelocity.Velocity = Vector3.new(Root.AssemblyLinearVelocity.X, 100, Root.AssemblyLinearVelocity.Z)
        local jumpGyro = Instance.new("BodyGyro", Root)
        jumpGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        
        local _, yRot, _ = Root.CFrame:ToEulerAnglesYXZ()
        jumpGyro.CFrame = CFrame.fromEulerAnglesYXZ(math.rad(90), yRot, 0)
        local flyUpAnim = Instance.new("Animation")
        flyUpAnim.AnimationId = "rbxassetid://132105268936736"
        local flyUpTrack = Hum:LoadAnimation(flyUpAnim)
        flyUpTrack.Priority = Enum.AnimationPriority.Action3
        flyUpTrack:Play(0.15)
        
        local originalFOV = Camera.FieldOfView
        TweenService:Create(Camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = originalFOV + 12}):Play()
        local jumpTween = TweenService:Create(jumpVelocity, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Velocity = Vector3.new(Root.AssemblyLinearVelocity.X, 30, Root.AssemblyLinearVelocity.Z)
        })
        jumpTween:Play()
        task.wait(0.55)
        
        TweenService:Create(Camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {FieldOfView = originalFOV}):Play()
        flyUpTrack:Stop(0.3)
        Root.AssemblyLinearVelocity = jumpVelocity.Velocity
        jumpVelocity:Destroy()
        jumpGyro:Destroy()
        Hum.PlatformStand = false
        StartFlying() 
    end
end)

SpiralRadiusBtn.MouseButton1Click:Connect(function()
    SpiralRadiusIdx = (SpiralRadiusIdx % #SpiralRadiusLevels) + 1
    SpiralRadius = SpiralRadiusLevels[SpiralRadiusIdx]
    SpiralRadiusBtn.Text = "Spiral Rad\n" .. SpiralRadius
end)

SpiralBtn.MouseButton1Click:Connect(function()
    SpiralActive = not SpiralActive
    local Char = Player.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if SpiralActive then
        SpiralBtn.Text = "Spiral\nON"
        SpiralBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        if not Root or not Hum then SpiralActive = false; return end
        
        local wasFlyingAtStart = Flying
        if wasFlyingAtStart then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://127528880902667"
            local t = Hum:LoadAnimation(anim)
            t.Priority = Enum.AnimationPriority.Action4
            t:Play()
            task.wait(0.8)
            t:Stop()
        else
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://132168338773523"
            local t = Hum:LoadAnimation(anim)
            t.Priority = Enum.AnimationPriority.Action4
            t:Play()
            task.wait(1.0)
            t:Stop()
        end
        
        if not SpiralActive then return end
        
        local centerPart = Instance.new("Part")
        centerPart.Size = Vector3.new(1,1,1)
        centerPart.Transparency = 1
        centerPart.Anchored = true
        centerPart.CanCollide = false
        centerPart.Position = Root.Position
        centerPart.Parent = workspace
        
        Camera.CameraSubject = centerPart
        
        local spiralAnim = Instance.new("Animation")
        spiralAnim.AnimationId = "rbxassetid://131114687716793"
        local spiralTrack = Hum:LoadAnimation(spiralAnim)
        spiralTrack.Priority = Enum.AnimationPriority.Action4
        spiralTrack.Looped = true
        spiralTrack:Play()
        
        local angle = 0
        local centerPos = Root.Position
        local oldPlatformStand = Hum.PlatformStand
        Hum.PlatformStand = true
        
        task.spawn(function()
            local cloneTick = 0
            while SpiralActive and Root and Root.Parent do
                -- Модифицировано: Шаг изменения угла теперь использует переменную spiralSpeed
                angle = angle + spiralSpeed
                local posX = centerPos.X + math.sin(angle) * SpiralRadius
                local posZ = centerPos.Z + math.cos(angle) * SpiralRadius
                local targetPos = Vector3.new(posX, centerPos.Y, posZ)
                
                local tangentX = math.cos(angle)
                local tangentZ = -math.sin(angle)
                local lookDir = Vector3.new(tangentX, 0, tangentZ).Unit
                
                Root.CFrame = CFrame.lookAt(targetPos, targetPos + lookDir)
                Root.AssemblyLinearVelocity = lookDir * 9999999
                
                cloneTick = cloneTick + 1
                if cloneTick % 2 == 0 then
                    task.spawn(function()
                        Char.Archivable = true
                        local clone = Char:Clone()
                        Char.Archivable = false
                        clone.Parent = workspace
                        for _, p in ipairs(clone:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.Anchored = true
                                p.CanCollide = false
                                p.Material = Enum.Material.Neon
                                TweenService:Create(p, TweenInfo.new(0.3), {Transparency = 1}):Play()
                            elseif p:IsA("Script") or p:IsA("LocalScript") then
                                p:Destroy()
                            end
                        end
                        task.wait(0.3)
                        clone:Destroy()
                    end)
                end
                RunService.Heartbeat:Wait()
            end
            
            if Root then
                Root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                Root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                Root.CFrame = CFrame.new(centerPos) * Root.CFrame.Rotation
            end
            
            if spiralTrack then spiralTrack:Stop() end
            Camera.CameraSubject = Hum
            if centerPart then centerPart:Destroy() end
            
            if not wasFlyingAtStart and not Flying then
                if Root then
                    Root.AssemblyLinearVelocity = Vector3.zero
                    Root.AssemblyAngularVelocity = Vector3.zero
                end
                local landAnimInstance = Instance.new("Animation")
                landAnimInstance.AnimationId = LandingAnim
                local landTrack = Hum:LoadAnimation(landAnimInstance)
                landTrack.Priority = Enum.AnimationPriority.Action4
                landTrack:Play(0.1)
                
                if Root then Root.Anchored = true end
                task.wait(1.5)
                if Root then Root.Anchored = false end
                if landTrack then landTrack:Stop() end
                Hum.PlatformStand = oldPlatformStand
            else
                Hum.PlatformStand = oldPlatformStand
                if Flying and bv then bv.Velocity = Vector3.zero end
            end
        end)
    else
        SpiralBtn.Text = "Spiral\nOFF"
        SpiralBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)
