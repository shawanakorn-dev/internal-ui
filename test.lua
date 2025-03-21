-- init
local scriptVersion = "v0.1.1"
local config = {
    mainTabText = [[print("Hello World!")]],
    customExecution = false,
    executeFunc = loadstring
}

-- services
local inputService = game:GetService("UserInputService")
local logService = game:GetService("LogService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local players = game:GetService("Players")

-- imports
local miscLib = require(script.Parent.utils.misc)
local highlighterLib = require(script.Parent.utils.syntax-highlight)

-- Create a simple GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 625, 0, 375)
mainFrame.Position = UDim2.new(0.5, -312.5, 0.5, -187.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 1
mainFrame.Parent = screenGui

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 30, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Executor GUI"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 1, 0)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = topBar

local editorFrame = Instance.new("Frame")
editorFrame.Name = "EditorFrame"
editorFrame.Size = UDim2.new(1, -20, 1, -50)
editorFrame.Position = UDim2.new(0, 10, 0, 40)
editorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
editorFrame.Parent = mainFrame

local textBox = Instance.new("TextBox")
textBox.Name = "TextBox"
textBox.Size = UDim2.new(1, -10, 1, -10)
textBox.Position = UDim2.new(0, 5, 0, 5)
textBox.BackgroundTransparency = 1
textBox.Text = config.mainTabText
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.TextSize = 14
textBox.Font = Enum.Font.Consolas
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.MultiLine = true
textBox.TextWrapped = true
textBox.Parent = editorFrame

local executeButton = Instance.new("TextButton")
executeButton.Name = "ExecuteButton"
executeButton.Size = UDim2.new(0, 100, 0, 30)
executeButton.Position = UDim2.new(1, -110, 1, -40)
executeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
executeButton.Text = "Execute"
executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
executeButton.TextSize = 14
executeButton.Font = Enum.Font.GothamBold
executeButton.Parent = mainFrame

-- Add console output
local consoleFrame = Instance.new("Frame")
consoleFrame.Name = "ConsoleFrame"
consoleFrame.Size = UDim2.new(1, -20, 0, 100)
consoleFrame.Position = UDim2.new(0, 10, 1, -140)
consoleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
consoleFrame.Parent = mainFrame

local consoleOutput = Instance.new("TextLabel")
consoleOutput.Name = "ConsoleOutput"
consoleOutput.Size = UDim2.new(1, -10, 1, -10)
consoleOutput.Position = UDim2.new(0, 5, 0, 5)
consoleOutput.BackgroundTransparency = 1
consoleOutput.Text = ""
consoleOutput.TextColor3 = Color3.fromRGB(255, 255, 255)
consoleOutput.TextSize = 12
consoleOutput.Font = Enum.Font.Consolas
consoleOutput.TextXAlignment = Enum.TextXAlignment.Left
consoleOutput.TextYAlignment = Enum.TextYAlignment.Top
consoleOutput.TextWrapped = true
consoleOutput.Parent = consoleFrame

-- Add functionality
local function logToConsole(message, messageType)
    local color = Color3.fromRGB(255, 255, 255)
    if messageType == "error" then
        color = Color3.fromRGB(255, 0, 0)
    elseif messageType == "success" then
        color = Color3.fromRGB(0, 255, 0)
    end
    
    consoleOutput.Text = consoleOutput.Text .. "\n" .. message
    consoleOutput.TextColor3 = color
end

local function executeScript()
    local scriptText = textBox.Text
    if scriptText == "" then
        logToConsole("Error: Script is empty", "error")
        return
    end
    
    local success, result = pcall(function()
        local func = config.executeFunc(scriptText)
        if func then
            func()
            return true
        end
        return false
    end)
    
    if not success then
        logToConsole("Error: " .. tostring(result), "error")
    else
        logToConsole("Script executed successfully", "success")
    end
end

-- Use miscLib for button events and dragging
miscLib.ButtonClickEvent(executeButton, Enum.UserInputType.MouseButton1, executeScript)
miscLib.ButtonClickEvent(closeButton, Enum.UserInputType.MouseButton1, function()
    screenGui:Destroy()
end)

-- Make the GUI draggable using miscLib
miscLib.Draggify(mainFrame, topBar)

-- Initialize syntax highlighting
highlighterLib:Init()

-- Add syntax highlighting to textbox
textBox:GetPropertyChangedSignal("Text"):Connect(function()
    highlighterLib:Render(textBox)
end)

-- Add keyboard shortcuts
inputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Return and inputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        executeScript()
    end
end)

-- Initial console message
logToConsole("Executor GUI loaded successfully", "success") 