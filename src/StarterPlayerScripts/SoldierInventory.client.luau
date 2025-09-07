-- // SoldierInventory, initialized by KingCreoo on 9-7-2025
-- // Manages UI functions for the client's soldier inventory :)

-- // Services
local Players = game:GetService("Players")

-- // Modules

-- // Variables
local LocalPlayer = Players.LocalPlayer
local UI = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("UI")

local LocalGui = LocalPlayer:WaitForChild("PlayerGui")
local FramesGui = LocalGui:WaitForChild("Frames")

local SoldierInventoryFrame: Frame = FramesGui:WaitForChild("SoldierInventory")
local CloseButton: TextButton = SoldierInventoryFrame:WaitForChild("Close")

local Buttons = {CloseButton}

local ButtonExpandBindable: BindableEvent = UI:WaitForChild("ButtonExpand")
local ButtonDeflateBindable: BindableEvent = UI:WaitForChild("ButtonDeflate")
local CloseFrameBindable: BindableEvent = UI:WaitForChild("CloseFrame")

local FrameActive = false

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

CloseButton.MouseButton1Click:Connect(function()
    if FrameActive == false then return end
    CloseFrameBindable:Fire(SoldierInventoryFrame)
end)

SoldierInventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    FrameActive = SoldierInventoryFrame.Visible
end)