-- DrawingUiLib.lua - Place this file in your executor workspace
-- Enhanced Drawing UI Library with auto-scroll navigation

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Library = {}
Library.UI = {
    Visible = true,
    CurrentPosition = "TopLeft",
    Elements = {},
    SelectedIndex = 1,
    ScrollOffset = 0,
    MaxVisibleItems = 50, -- Increased to show all items
    ItemHeight = 18, -- Slightly smaller for more items
    AutoScroll = true
}

-- UI Positioning
local function getPosition()
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize
    
    if Library.UI.CurrentPosition == "TopLeft" then
        return Vector2.new(20, 20)
    elseif Library.UI.CurrentPosition == "TopRight" then
        return Vector2.new(screenSize.X - 250, 20)
    elseif Library.UI.CurrentPosition == "BottomLeft" then
        return Vector2.new(20, screenSize.Y - 400)
    elseif Library.UI.CurrentPosition == "BottomRight" then
        return Vector2.new(screenSize.X - 250, screenSize.Y - 400)
    else
        return Vector2.new(20, 20)
    end
end

-- Create background
local background = Drawing.new("Square")
background.Size = Vector2.new(230, 600) -- Increased height for full display
background.Position = getPosition()
background.Color = Color3.fromRGB(25, 25, 25)
background.Filled = true
background.Visible = Library.UI.Visible
background.Transparency = 0.15

local border = Drawing.new("Square")
border.Size = Vector2.new(232, 602) -- Increased height
border.Position = getPosition() - Vector2.new(1, 1)
border.Color = Color3.fromRGB(100, 100, 100)
border.Filled = false
border.Thickness = 1
border.Visible = Library.UI.Visible
border.Transparency = 0.8

-- Update positions when screen changes
local function updatePositions()
    local basePos = getPosition()
    background.Position = basePos
    border.Position = basePos - Vector2.new(1, 1)
    
    -- Update all element positions
    for i, element in ipairs(Library.UI.Elements) do
        local yOffset = (i - 1) * Library.UI.ItemHeight + 10 -- Removed scroll offset
        if element.drawingObject then
            element.drawingObject.Position = basePos + Vector2.new(10, yOffset)
            element.drawingObject.Visible = Library.UI.Visible and element.visible -- Always visible
        end
        
        -- Update selection highlight
        if element.highlight then
            element.highlight.Position = basePos + Vector2.new(5, yOffset - 2)
            element.highlight.Visible = Library.UI.Visible and (i == Library.UI.SelectedIndex) and element.visible
        end
    end
end

-- Auto-scroll function (disabled for full display)
local function autoScroll()
    -- No scrolling needed - all items visible
    return
end

-- Navigation functions
local function navigateUp()
    repeat
        Library.UI.SelectedIndex = Library.UI.SelectedIndex - 1
        if Library.UI.SelectedIndex < 1 then
            Library.UI.SelectedIndex = #Library.UI.Elements
        end
    until Library.UI.Elements[Library.UI.SelectedIndex] and Library.UI.Elements[Library.UI.SelectedIndex].selectable
    
    autoScroll()
    updatePositions()
end

local function navigateDown()
    repeat
        Library.UI.SelectedIndex = Library.UI.SelectedIndex + 1
        if Library.UI.SelectedIndex > #Library.UI.Elements then
            Library.UI.SelectedIndex = 1
        end
    until Library.UI.Elements[Library.UI.SelectedIndex] and Library.UI.Elements[Library.UI.SelectedIndex].selectable
    
    autoScroll()
    updatePositions()
end

local function selectCurrent()
    local element = Library.UI.Elements[Library.UI.SelectedIndex]
    if element and element.callback and element.selectable then
        element.callback()
        updatePositions()
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        Library.UI.Visible = not Library.UI.Visible
        background.Visible = Library.UI.Visible
        border.Visible = Library.UI.Visible
        updatePositions()
    elseif Library.UI.Visible then
        if input.KeyCode == Enum.KeyCode.J then
            navigateUp()
        elseif input.KeyCode == Enum.KeyCode.K then
            navigateDown()
        elseif input.KeyCode == Enum.KeyCode.L then
            selectCurrent()
        end
    end
end)

-- Screen size change handler
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePositions)

-- Core UI functions
function Library:NewText(text, size, color)
    local textObject = Drawing.new("Text")
    textObject.Text = text
    textObject.Size = size or 12
    textObject.Color = color or Color3.fromRGB(255, 255, 255)
    textObject.Font = Drawing.Fonts.Monospace
    textObject.Visible = Library.UI.Visible
    textObject.Outline = true
    textObject.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local element = {
        drawingObject = textObject,
        visible = true,
        selectable = false,
        type = "text"
    }
    
    table.insert(Library.UI.Elements, element)
    updatePositions()
    return element
end

function Library:NewToggle(text, callback)
    local toggleText = Drawing.new("Text")
    toggleText.Text = "[ ] " .. text
    toggleText.Size = 12
    toggleText.Color = Color3.fromRGB(255, 255, 255)
    toggleText.Font = Drawing.Fonts.Monospace
    toggleText.Visible = Library.UI.Visible
    toggleText.Outline = true
    toggleText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local highlight = Drawing.new("Square")
    highlight.Size = Vector2.new(220, 16)
    highlight.Color = Color3.fromRGB(100, 100, 100)
    highlight.Filled = true
    highlight.Transparency = 0.3
    highlight.Visible = false
    
    local toggled = false
    
    local element = {
        drawingObject = toggleText,
        highlight = highlight,
        visible = true,
        selectable = true,
        type = "toggle",
        callback = function()
            toggled = not toggled
            toggleText.Text = (toggled and "[X] " or "[ ] ") .. text
            toggleText.Color = toggled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
            if callback then callback() end
        end
    }
    
    table.insert(Library.UI.Elements, element)
    updatePositions()
    return element
end

function Library:NewButton(text, callback)
    local buttonText = Drawing.new("Text")
    buttonText.Text = "> " .. text
    buttonText.Size = 12
    buttonText.Color = Color3.fromRGB(100, 200, 255)
    buttonText.Font = Drawing.Fonts.Monospace
    buttonText.Visible = Library.UI.Visible
    buttonText.Outline = true
    buttonText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local highlight = Drawing.new("Square")
    highlight.Size = Vector2.new(220, 16)
    highlight.Color = Color3.fromRGB(100, 100, 100)
    highlight.Filled = true
    highlight.Transparency = 0.3
    highlight.Visible = false
    
    local element = {
        drawingObject = buttonText,
        highlight = highlight,
        visible = true,
        selectable = true,
        type = "button",
        callback = callback
    }
    
    table.insert(Library.UI.Elements, element)
    updatePositions()
    return element
end

function Library:NewDivider(text)
    local dividerText = Drawing.new("Text")
    dividerText.Text = text or "─────────────────────"
    dividerText.Size = 10
    dividerText.Color = Color3.fromRGB(150, 150, 150)
    dividerText.Font = Drawing.Fonts.Monospace
    dividerText.Visible = Library.UI.Visible
    dividerText.Outline = true
    dividerText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local element = {
        drawingObject = dividerText,
        visible = true,
        selectable = false,
        type = "divider"
    }
    
    table.insert(Library.UI.Elements, element)
    updatePositions()
    return element
end

function Library:UpdateText(element, newText)
    if element and element.drawingObject and element.type == "text" then
        element.drawingObject.Text = newText
    end
end

-- Initialize with first selectable item
spawn(function()
    wait(0.1)
    for i, element in ipairs(Library.UI.Elements) do
        if element.selectable then
            Library.UI.SelectedIndex = i
            break
        end
    end
    updatePositions()
end)

return Library