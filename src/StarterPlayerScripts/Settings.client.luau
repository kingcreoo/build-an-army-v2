-- // Settings, initialized by KingCreoo on 9-7-2025
-- // Manages UI functions for the client's settings frame :)

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Modules
local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))

-- // Variables
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ButtonExpandBindable: BindableEvent = Remotes:WaitForChild("ButtonExpand")
local ButtonDeflateBindable: BindableEvent = Remotes:WaitForChild("ButtonDeflate")
local CloseFrameBindable: BindableEvent = Remotes:WaitForChild("CloseFrame")
local NotifyBindable: BindableEvent = Remotes:WaitForChild("NotifyBindable")

local LocalPlayer = Players.LocalPlayer
local UI = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("UI")

local LocalGui = LocalPlayer:WaitForChild("PlayerGui")
local FramesGui = LocalGui:WaitForChild("Frames")

local SettingsFrame: Frame = FramesGui:WaitForChild("SettingsFrame")

local MainFrame: Frame = SettingsFrame:WaitForChild("MainFrame")
local CloseButton: TextButton = SettingsFrame:WaitForChild("Close")

local Buttons = {CloseButton}

local FrameActive

-- // Functions

-- // Events

for _, Button in pairs(Buttons) do
    Button.MouseEnter:Connect(function()
        if FrameActive == false then return end
        ButtonExpandBindable:Fire(Button, 1.1)
    end)
    Button.MouseLeave:Connect(function()
        if FrameActive == false then return end
        ButtonDeflateBindable:Fire(Button)
    end)
end

SettingsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    FrameActive = SettingsFrame.Visible
end)

CloseButton.MouseButton1Click:Connect(function()
    if FrameActive == false then return end
    CloseFrameBindable:Fire(SettingsFrame)
end)