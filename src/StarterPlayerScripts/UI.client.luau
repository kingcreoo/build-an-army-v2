-- // UI, initialized by KingCreoo on 9-6-2025
-- // Manages UI functions for the client :)

-- // Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- // Modules

-- // Variables
local LocalPlayer = Players.LocalPlayer
local LocalGui = LocalPlayer:WaitForChild("PlayerGui")

local HUD: ScreenGui = LocalGui:WaitForChild("HUD")
local SoldiersButton: TextButton = HUD:WaitForChild("Soldiers")
local StoreButton: TextButton = HUD:WaitForChild("Store")
local SettingsButton: TextButton = HUD:WaitForChild("Settings")

local FramesGui: ScreenGui = LocalGui:WaitForChild("Frames")
local SoldierShopFrame: Frame = FramesGui:WaitForChild("SoldierShop")
local SoldierInventoryFrame: Frame = FramesGui:WaitForChild("SoldierInventory")

local PromptedFrames = {SoldierShopFrame}
local PromptedFrameDebounces = {SoldierShopFrame = false}

local HUDButtons = {SoldiersButton, StoreButton, SettingsButton}

local ExpansionTweenInfo = TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local DeflationTweenInfo = TweenInfo.new(.075, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local OpenTweenInfo = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local CloseTweenInfo = TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local ButtonExpandBindable: BindableEvent = script:WaitForChild("ButtonExpand")
local ButtonDeflateBindable: BindableEvent = script:WaitForChild("ButtonDeflate")
local CloseFrameBindable: BindableEvent = script:WaitForChild("CloseFrame")

local SoldierShopPrompt: ProximityPrompt = Workspace:WaitForChild("SoldierShop"):WaitForChild("PromptPart"):WaitForChild("Prompt")

local ActiveFrame = nil
local ActiveFramePriority = nil
local HUDActive = nil

local SBD = false

-- // Functions

local function ButtonExpand(Button, Amplification)
    local OriginSize: UDim2 = Button:GetAttribute("OriginSize")
    local ExpansionSize: UDim2 = UDim2.fromScale(OriginSize.X.Scale * Amplification, OriginSize.Y.Scale * Amplification)

    local ExpansionTween = TweenService:Create(Button, ExpansionTweenInfo, {Size = ExpansionSize})
    ExpansionTween:Play()
end

local function ButtonDeflate(Button)
    local OriginSize = Button:GetAttribute("OriginSize")

    local DeflationTween = TweenService:Create(Button, DeflationTweenInfo, {Size = OriginSize})
    DeflationTween:Play()
end

local function ButtonClose(Button)
    local CloseButtonTween = TweenService:Create(Button, DeflationTweenInfo, {Size = UDim2.fromScale(0,0)})
    CloseButtonTween:Play()
    CloseButtonTween.Completed:Connect(function()
        Button.Visible = false
    end)
end

local function ButtonOpen(Button)
    Button.Visible = true
    Button.Size = UDim2.fromScale(0,0)
    local OpenButtonTween = TweenService:Create(Button, ExpansionTweenInfo, {Size = Button:GetAttribute("OriginSize")})
    OpenButtonTween:Play()
end

local function CloseHUD(Fast: boolean)
    if Fast then
        for _, Button in pairs(HUDButtons) do
            Button.Visible = false
        end
    else
        for _, Button in pairs(HUDButtons) do
            task.wait(.05)
            ButtonClose(Button)
        end
    end
    HUDActive = false

    return
end

local function OpenHUD(Fast)
    if Fast then
        for _, Button in pairs(HUDButtons) do
            Button.Visible = true
        end
        HUDActive = true
    else
        for _, Button in pairs(HUDButtons) do
            ButtonOpen(Button)
            task.wait(.2)
        end
        HUDActive = true
    end
end

local function CloseFrame(Frame, NextFrame)
    if table.find(PromptedFrames, Frame) then
        PromptedFrameDebounces[Frame] = true
        task.delay(1, function()
            PromptedFrameDebounces[Frame] = false
        end)
    end

    local CloseTween = TweenService:Create(Frame, CloseTweenInfo, {Size = UDim2.fromScale(0,0)})
    CloseTween:Play()
    ActiveFrame = nil
    CloseTween.Completed:Connect(function()
        Frame.Visible = false
        if not NextFrame then
            task.delay(.1, OpenHUD)
        end
    end)

    return .1
end

local function OpenFrame(Frame: Frame)

    if ActiveFrame and ActiveFramePriority then
        return
    elseif ActiveFrame and not ActiveFramePriority then
        local AnimationTime = CloseFrame(ActiveFrame, true)
        task.wait(AnimationTime)
    elseif not ActiveFrame then
        if HUDActive then
            CloseHUD()
        end
    end

    ActiveFrame = Frame
    local OpenTween = TweenService:Create(Frame, OpenTweenInfo, {Size = UDim2.fromScale(1, 1)})
    Frame.Size = UDim2.fromScale(0,0)
    Frame.Visible = true
    OpenTween:Play()
end

-- // Events
for _, Button in pairs(HUDButtons) do
    Button.MouseEnter:Connect(function()
        if HUDActive == false then return end
        ButtonExpand(Button, 1.1)
    end)
    Button.MouseLeave:Connect(function()
        if HUDActive == false then return end
        ButtonDeflate(Button)
    end)
end

SoldiersButton.MouseButton1Click:Connect(function()
    if not HUDActive then return end

    if SBD then return end
    SBD = true

    if ActiveFrame == SoldierInventoryFrame then
        CloseFrame(SoldierInventoryFrame)
    else
        OpenFrame(SoldierInventoryFrame)
    end

    task.wait(.5)
    SBD = false
end)

ButtonExpandBindable.Event:Connect(ButtonExpand)
ButtonDeflateBindable.Event:Connect(ButtonDeflate)
CloseFrameBindable.Event:Connect(CloseFrame)

SoldierShopPrompt.PromptShown:Connect(function()
    if PromptedFrameDebounces[SoldierShopFrame] then return end

    if SoldierShopFrame.Visible == true then return end

    PromptedFrameDebounces[SoldierShopFrame] = true
    OpenFrame(SoldierShopFrame)

    task.wait(.5)
    PromptedFrameDebounces[SoldierShopFrame] = false
end)
SoldierShopPrompt.PromptHidden:Connect(function()
    if SoldierShopFrame.Visible == false then return end
    CloseFrame(SoldierShopFrame)
end)

-- TODO Wait for loading screen to finish
HUD.Enabled = true
HUDActive = true