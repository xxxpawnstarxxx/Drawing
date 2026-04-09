local UILibrary = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Get current viewport size
local function getViewportSize()
    local camera = workspace.CurrentCamera
    return camera.ViewportSize
end

-- Reference resolution for scaling (1920x1080 by default)
UILibrary.ReferenceResolution = Vector2.new(1920, 1080)
UILibrary.ScaleMode = "FitBoth" -- "FitBoth", "FitWidth", "FitHeight", "Stretch", "None"

-- Calculate scale factor based on current viewport
function UILibrary.getScaleFactor()
    local viewport = getViewportSize()
    local refRes = UILibrary.ReferenceResolution
    
    if UILibrary.ScaleMode == "FitWidth" then
        return viewport.X / refRes.X
    elseif UILibrary.ScaleMode == "FitHeight" then
        return viewport.Y / refRes.Y
    elseif UILibrary.ScaleMode == "FitBoth" then
        return math.min(viewport.X / refRes.X, viewport.Y / refRes.Y)
    elseif UILibrary.ScaleMode == "Stretch" then
        return Vector2.new(viewport.X / refRes.X, viewport.Y / refRes.Y)
    elseif UILibrary.ScaleMode == "None" then
        return 1
    end
    
    return 1
end

-- Scale a value
function UILibrary.scale(value)
    local scale = UILibrary.getScaleFactor()
    if typeof(scale) == "Vector2" then
        if typeof(value) == "number" then
            return value * math.min(scale.X, scale.Y)
        elseif typeof(value) == "Vector2" then
            return Vector2.new(value.X * scale.X, value.Y * scale.Y)
        end
    else
        if typeof(value) == "number" then
            return value * scale
        elseif typeof(value) == "Vector2" then
            return value * scale
        end
    end
    return value
end

-- Anchor points enumeration
UILibrary.Anchor = {
    TopLeft = Vector2.new(0, 0),
    TopCenter = Vector2.new(0.5, 0),
    TopRight = Vector2.new(1, 0),
    
    MiddleLeft = Vector2.new(0, 0.5),
    Center = Vector2.new(0.5, 0.5),
    MiddleRight = Vector2.new(1, 0.5),
    
    BottomLeft = Vector2.new(0, 1),
    BottomCenter = Vector2.new(0.5, 1),
    BottomRight = Vector2.new(1, 1),
}

-- UDim2-like positioning system
UILibrary.UDim2 = {}
UILibrary.UDim2.__index = UILibrary.UDim2

function UILibrary.UDim2.new(xScale, xOffset, yScale, yOffset)
    local self = setmetatable({}, UILibrary.UDim2)
    self.X = {Scale = xScale or 0, Offset = xOffset or 0}
    self.Y = {Scale = yScale or 0, Offset = yOffset or 0}
    return self
end

function UILibrary.UDim2.fromScale(xScale, yScale)
    return UILibrary.UDim2.new(xScale, 0, yScale, 0)
end

function UILibrary.UDim2.fromOffset(xOffset, yOffset)
    return UILibrary.UDim2.new(0, xOffset, 0, yOffset)
end

function UILibrary.UDim2:toVector2(parentSize)
    parentSize = parentSize or getViewportSize()
    local scaleFactor = UILibrary.getScaleFactor()
    
    if typeof(scaleFactor) == "Vector2" then
        return Vector2.new(
            parentSize.X * self.X.Scale + self.X.Offset * scaleFactor.X,
            parentSize.Y * self.Y.Scale + self.Y.Offset * scaleFactor.Y
        )
    else
        return Vector2.new(
            parentSize.X * self.X.Scale + self.X.Offset * scaleFactor,
            parentSize.Y * self.Y.Scale + self.Y.Offset * scaleFactor
        )
    end
end

-- Base UI Element
UILibrary.Element = {}
UILibrary.Element.__index = UILibrary.Element

function UILibrary.Element.new(drawingType, config)
    config = config or {}
    
    local self = setmetatable({}, UILibrary.Element)
    
    -- Core properties
    self.Drawing = Drawing.new(drawingType)
    self.Type = drawingType
    
    -- Position and size (using UDim2)
    self.Position = config.Position or UILibrary.UDim2.new(0, 0, 0, 0)
    self.Size = config.Size or UILibrary.UDim2.new(0, 100, 0, 100)
    self.AnchorPoint = config.AnchorPoint or Vector2.new(0, 0)
    
    -- Parent
    self.Parent = config.Parent
    self.Children = {}
    
    -- Layout
    self.AbsolutePosition = Vector2.new(0, 0)
    self.AbsoluteSize = Vector2.new(0, 0)
    
    -- Visibility
    self.Visible = config.Visible ~= false
    self.ZIndex = config.ZIndex or 1
    
    -- Constraints
    self.MinSize = config.MinSize -- UDim2
    self.MaxSize = config.MaxSize -- UDim2
    self.AspectRatio = config.AspectRatio -- number
    
    -- Padding
    self.Padding = config.Padding or {
        Left = 0, Right = 0, Top = 0, Bottom = 0
    }
    
    -- Auto-update
    self._autoUpdate = config.AutoUpdate ~= false
    self._updateConnection = nil
    
    -- Apply initial properties
    for prop, value in pairs(config) do
        if prop ~= "Position" and prop ~= "Size" and prop ~= "AnchorPoint" 
           and prop ~= "Parent" and prop ~= "AutoUpdate" then
            pcall(function()
                self.Drawing[prop] = value
            end)
        end
    end
    
    self:_update()
    
    if self._autoUpdate then
        self:enableAutoUpdate()
    end
    
    return self
end

function UILibrary.Element:_getParentSize()
    if self.Parent then
        return self.Parent.AbsoluteSize
    end
    return getViewportSize()
end

function UILibrary.Element:_getParentPosition()
    if self.Parent then
        return self.Parent.AbsolutePosition + Vector2.new(
            self.Parent.Padding.Left,
            self.Parent.Padding.Top
        )
    end
    return Vector2.new(0, 0)
end

function UILibrary.Element:_update()
    local parentSize = self:_getParentSize()
    local parentPos = self:_getParentPosition()
    
    -- Account for parent padding
    if self.Parent then
        parentSize = parentSize - Vector2.new(
            self.Parent.Padding.Left + self.Parent.Padding.Right,
            self.Parent.Padding.Top + self.Parent.Padding.Bottom
        )
    end
    
    -- Calculate absolute size
    self.AbsoluteSize = self.Size:toVector2(parentSize)
    
    -- Apply constraints
    if self.MinSize then
        local minSize = self.MinSize:toVector2(parentSize)
        self.AbsoluteSize = Vector2.new(
            math.max(self.AbsoluteSize.X, minSize.X),
            math.max(self.AbsoluteSize.Y, minSize.Y)
        )
    end
    
    if self.MaxSize then
        local maxSize = self.MaxSize:toVector2(parentSize)
        self.AbsoluteSize = Vector2.new(
            math.min(self.AbsoluteSize.X, maxSize.X),
            math.min(self.AbsoluteSize.Y, maxSize.Y)
        )
    end
    
    -- Apply aspect ratio
    if self.AspectRatio then
        local currentRatio = self.AbsoluteSize.X / self.AbsoluteSize.Y
        if currentRatio > self.AspectRatio then
            self.AbsoluteSize = Vector2.new(
                self.AbsoluteSize.Y * self.AspectRatio,
                self.AbsoluteSize.Y
            )
        else
            self.AbsoluteSize = Vector2.new(
                self.AbsoluteSize.X,
                self.AbsoluteSize.X / self.AspectRatio
            )
        end
    end
    
    -- Calculate absolute position
    local relativePos = self.Position:toVector2(parentSize)
    local anchorOffset = self.AbsoluteSize * self.AnchorPoint
    self.AbsolutePosition = parentPos + relativePos - anchorOffset
    
    -- Update drawing object
    self:_applyToDrawing()
    
    -- Update children
    for _, child in ipairs(self.Children) do
        child:_update()
    end
end

function UILibrary.Element:_applyToDrawing()
    self.Drawing.Visible = self.Visible
    self.Drawing.ZIndex = self.ZIndex
    
    if self.Type == "Square" or self.Type == "Image" then
        self.Drawing.Size = self.AbsoluteSize
        self.Drawing.Position = self.AbsolutePosition
    elseif self.Type == "Circle" then
        self.Drawing.Radius = math.min(self.AbsoluteSize.X, self.AbsoluteSize.Y) / 2
        self.Drawing.Position = self.AbsolutePosition + self.AbsoluteSize / 2
    elseif self.Type == "Text" then
        self.Drawing.Position = self.AbsolutePosition
        self.Drawing.Size = UILibrary.scale(self.Drawing.Size or 13)
    elseif self.Type == "Line" then
        self.Drawing.From = self.AbsolutePosition
        self.Drawing.To = self.AbsolutePosition + self.AbsoluteSize
    elseif self.Type == "Triangle" then
        -- Triangle uses PointA, PointB, PointC
        local pos = self.AbsolutePosition
        local size = self.AbsoluteSize
        self.Drawing.PointA = pos + Vector2.new(size.X / 2, 0)
        self.Drawing.PointB = pos + Vector2.new(0, size.Y)
        self.Drawing.PointC = pos + Vector2.new(size.X, size.Y)
    elseif self.Type == "Quad" then
        -- Quad uses PointA, PointB, PointC, PointD
        local pos = self.AbsolutePosition
        local size = self.AbsoluteSize
        self.Drawing.PointA = pos
        self.Drawing.PointB = pos + Vector2.new(size.X, 0)
        self.Drawing.PointC = pos + size
        self.Drawing.PointD = pos + Vector2.new(0, size.Y)
    end
end

function UILibrary.Element:enableAutoUpdate()
    if self._updateConnection then return end
    
    self._updateConnection = RunService.RenderStepped:Connect(function()
        self:_update()
    end)
end

function UILibrary.Element:disableAutoUpdate()
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
end

function UILibrary.Element:addChild(child)
    table.insert(self.Children, child)
    child.Parent = self
    child:_update()
end

function UILibrary.Element:removeChild(child)
    for i, c in ipairs(self.Children) do
        if c == child then
            table.remove(self.Children, i)
            child.Parent = nil
            break
        end
    end
end

function UILibrary.Element:setProperty(property, value)
    if property == "Position" or property == "Size" then
        self[property] = value
        self:_update()
    else
        pcall(function()
            self.Drawing[property] = value
        end)
    end
end

function UILibrary.Element:destroy()
    self:disableAutoUpdate()
    
    for _, child in ipairs(self.Children) do
        child:destroy()
    end
    
    self.Drawing:Remove()
end

-- Container with layout support
UILibrary.Container = {}
UILibrary.Container.__index = UILibrary.Container
setmetatable(UILibrary.Container, {__index = UILibrary.Element})

function UILibrary.Container.new(config)
    config = config or {}
    
    local self = UILibrary.Element.new("Square", config)
    setmetatable(self, UILibrary.Container)
    
    -- Layout settings
    self.LayoutMode = config.LayoutMode or "None" -- "None", "Horizontal", "Vertical", "Grid"
    self.LayoutSpacing = config.LayoutSpacing or 5
    self.GridColumns = config.GridColumns or 3
    self.LayoutAlignment = config.LayoutAlignment or "Start" -- "Start", "Center", "End", "SpaceBetween", "SpaceAround"
    
    -- Make container transparent by default
    self.Drawing.Transparency = config.Transparency or 0
    self.Drawing.Filled = config.Filled ~= false
    
    return self
end

function UILibrary.Container:_update()
    -- Update self first
    UILibrary.Element._update(self)
    
    -- Apply layout to children
    if self.LayoutMode ~= "None" and #self.Children > 0 then
        self:_applyLayout()
    end
end

function UILibrary.Container:_applyLayout()
    local spacing = UILibrary.scale(self.LayoutSpacing)
    local contentSize = self.AbsoluteSize - Vector2.new(
        self.Padding.Left + self.Padding.Right,
        self.Padding.Top + self.Padding.Bottom
    )
    
    if self.LayoutMode == "Horizontal" then
        local totalWidth = 0
        local maxHeight = 0
        
        -- Calculate total size
        for _, child in ipairs(self.Children) do
            totalWidth = totalWidth + child.AbsoluteSize.X
            maxHeight = math.max(maxHeight, child.AbsoluteSize.Y)
        end
        totalWidth = totalWidth + spacing * (#self.Children - 1)
        
        -- Calculate starting position based on alignment
        local startX = 0
        if self.LayoutAlignment == "Center" then
            startX = (contentSize.X - totalWidth) / 2
        elseif self.LayoutAlignment == "End" then
            startX = contentSize.X - totalWidth
        end
        
        local currentX = startX
        
        for i, child in ipairs(self.Children) do
            if self.LayoutAlignment == "SpaceBetween" then
                if #self.Children > 1 then
                    currentX = (contentSize.X - (totalWidth - spacing * (#self.Children - 1))) / (#self.Children - 1) * (i - 1)
                end
            elseif self.LayoutAlignment == "SpaceAround" then
                local totalSpacing = contentSize.X - (totalWidth - spacing * (#self.Children - 1))
                local itemSpacing = totalSpacing / #self.Children
                currentX = itemSpacing * (i - 0.5) + (totalWidth - spacing * (#self.Children - 1)) / #self.Children * (i - 1)
            end
            
            child.Position = UILibrary.UDim2.fromOffset(currentX, 0)
            child:_update()
            
            if self.LayoutAlignment ~= "SpaceBetween" and self.LayoutAlignment ~= "SpaceAround" then
                currentX = currentX + child.AbsoluteSize.X + spacing
            end
        end
        
    elseif self.LayoutMode == "Vertical" then
        local totalHeight = 0
        local maxWidth = 0
        
        for _, child in ipairs(self.Children) do
            totalHeight = totalHeight + child.AbsoluteSize.Y
            maxWidth = math.max(maxWidth, child.AbsoluteSize.X)
        end
        totalHeight = totalHeight + spacing * (#self.Children - 1)
        
        local startY = 0
        if self.LayoutAlignment == "Center" then
            startY = (contentSize.Y - totalHeight) / 2
        elseif self.LayoutAlignment == "End" then
            startY = contentSize.Y - totalHeight
        end
        
        local currentY = startY
        
        for i, child in ipairs(self.Children) do
            if self.LayoutAlignment == "SpaceBetween" then
                if #self.Children > 1 then
                    currentY = (contentSize.Y - (totalHeight - spacing * (#self.Children - 1))) / (#self.Children - 1) * (i - 1)
                end
            elseif self.LayoutAlignment == "SpaceAround" then
                local totalSpacing = contentSize.Y - (totalHeight - spacing * (#self.Children - 1))
                local itemSpacing = totalSpacing / #self.Children
                currentY = itemSpacing * (i - 0.5) + (totalHeight - spacing * (#self.Children - 1)) / #self.Children * (i - 1)
            end
            
            child.Position = UILibrary.UDim2.fromOffset(0, currentY)
            child:_update()
            
            if self.LayoutAlignment ~= "SpaceBetween" and self.LayoutAlignment ~= "SpaceAround" then
                currentY = currentY + child.AbsoluteSize.Y + spacing
            end
        end
        
    elseif self.LayoutMode == "Grid" then
        local columns = self.GridColumns
        local rows = math.ceil(#self.Children / columns)
        
        local cellWidth = (contentSize.X - spacing * (columns - 1)) / columns
        local cellHeight = (contentSize.Y - spacing * (rows - 1)) / rows
        
        for i, child in ipairs(self.Children) do
            local col = (i - 1) % columns
            local row = math.floor((i - 1) / columns)
            
            local x = col * (cellWidth + spacing)
            local y = row * (cellHeight + spacing)
            
            child.Position = UILibrary.UDim2.fromOffset(x, y)
            child:_update()
        end
    end
end

-- Text Label
function UILibrary.createTextLabel(config)
    config = config or {}
    config.AutoUpdate = config.AutoUpdate ~= false
    
    local element = UILibrary.Element.new("Text", config)
    
    -- Text-specific properties
    element.Drawing.Text = config.Text or "Label"
    element.Drawing.Size = config.TextSize or 13
    element.Drawing.Center = config.Center or false
    element.Drawing.Outline = config.Outline or false
    element.Drawing.Color = config.Color or Color3.fromRGB(255, 255, 255)
    element.Drawing.Font = config.Font or Drawing.Fonts.UI
    
    -- Override apply to drawing for text
    local originalApply = element._applyToDrawing
    element._applyToDrawing = function(self)
        originalApply(self)
        self.Drawing.Size = UILibrary.scale(config.TextSize or 13)
    end
    
    return element
end

-- Button (Interactive Square)
function UILibrary.createButton(config)
    config = config or {}
    
    local element = UILibrary.Element.new("Square", config)
    
    element.Drawing.Color = config.Color or Color3.fromRGB(60, 60, 60)
    element.Drawing.Filled = config.Filled ~= false
    element.Drawing.Thickness = config.Thickness or 1
    
    -- Button state
    element.Hovered = false
    element.Pressed = false
    
    -- Colors
    element.IdleColor = config.Color or Color3.fromRGB(60, 60, 60)
    element.HoverColor = config.HoverColor or Color3.fromRGB(80, 80, 80)
    element.PressColor = config.PressColor or Color3.fromRGB(40, 40, 40)
    
    -- Callbacks
    element.OnClick = config.OnClick
    element.OnHover = config.OnHover
    element.OnLeave = config.OnLeave
    
    -- Input handling
    element._inputConnection = RunService.RenderStepped:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        local pos = element.AbsolutePosition
        local size = element.AbsoluteSize
        
        local wasHovered = element.Hovered
        element.Hovered = mousePos.X >= pos.X and mousePos.X <= pos.X + size.X
                      and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y
        
        if element.Hovered and not wasHovered and element.OnHover then
            element.OnHover()
        elseif not element.Hovered and wasHovered and element.OnLeave then
            element.OnLeave()
        end
        
        -- Update color
        if element.Pressed then
            element.Drawing.Color = element.PressColor
        elseif element.Hovered then
            element.Drawing.Color = element.HoverColor
        else
            element.Drawing.Color = element.IdleColor
        end
    end)
    
    element._clickConnection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if element.Hovered then
                element.Pressed = true
            end
        end
    end)
    
    element._releaseConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if element.Pressed and element.Hovered and element.OnClick then
                element.OnClick()
            end
            element.Pressed = false
        end
    end)
    
    -- Override destroy
    local originalDestroy = element.destroy
    element.destroy = function(self)
        if self._inputConnection then self._inputConnection:Disconnect() end
        if self._clickConnection then self._clickConnection:Disconnect() end
        if self._releaseConnection then self._releaseConnection:Disconnect() end
        originalDestroy(self)
    end
    
    return element
end

-- Frame (Container alias)
function UILibrary.createFrame(config)
    return UILibrary.Container.new(config)
end

-- Circle
function UILibrary.createCircle(config)
    config = config or {}
    return UILibrary.Element.new("Circle", config)
end

-- Image
function UILibrary.createImage(config)
    config = config or {}
    local element = UILibrary.Element.new("Image", config)
    element.Drawing.Data = config.Data or ""
    return element
end

-- Line
function UILibrary.createLine(config)
    config = config or {}
    return UILibrary.Element.new("Line", config)
end

-- Helper functions
function UILibrary.setReferenceResolution(width, height)
    UILibrary.ReferenceResolution = Vector2.new(width, height)
end

function UILibrary.setScaleMode(mode)
    UILibrary.ScaleMode = mode
end

-- Screen management
UILibrary.Screen = {}

function UILibrary.Screen.getCenter()
    local viewport = getViewportSize()
    return viewport / 2
end

function UILibrary.Screen.getSize()
    return getViewportSize()
end

function UILibrary.Screen.getScaledSize()
    return UILibrary.scale(getViewportSize())
end

return UILibrary