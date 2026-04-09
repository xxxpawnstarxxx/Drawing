--// Crosshair Library by Assistant
--// Prevents multiple instances
pcall(function()
    getgenv().CrosshairLib:Destroy()
end)

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera

--// Library Setup
local CrosshairLib = {}
CrosshairLib.__index = CrosshairLib
getgenv().CrosshairLib = CrosshairLib

--// Utility Functions
local function LerpNumber(a, b, t)
    return a + (b - a) * t
end

local function ParseColor(colorString)
    if type(colorString) == "string" then
        local r, g, b = colorString:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
    elseif typeof(colorString) == "Color3" then
        return colorString
    end
    return Color3.fromRGB(255, 255, 255)
end

--// Crosshair Class
function CrosshairLib.new(config)
    local self = setmetatable({}, CrosshairLib)
    
    --// Default Configuration
    self.Config = {
        -- General Settings
        Enabled = true,
        FollowMouse = true,
        OffsetX = 0,
        OffsetY = 0,
        
        -- Line Settings
        Size = 12,
        Thickness = 2,
        Color = Color3.fromRGB(0, 255, 0),
        Transparency = 1,
        GapSize = 5,
        Rotation = 0,
        
        -- Center Dot
        CenterDot = {
            Enabled = false,
            Size = 2,
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 1,
            Filled = true,
            Segments = 16
        },
        
        -- Outline
        Outline = {
            Enabled = false,
            Thickness = 1,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.5
        },
        
        -- Animation Settings
        Animations = {
            Enabled = false,
            SpinSpeed = 0,
            PulseSpeed = 0,
            PulseRange = 0,
            RainbowSpeed = 0,
            ExpandOnShoot = false,
            ExpandAmount = 5,
            ExpandDuration = 0.1,
            ShakeOnHit = false,
            ShakeIntensity = 2,
            ShakeDuration = 0.15
        },
        
        -- Dynamic Crosshair
        Dynamic = {
            Enabled = false,
            MinSize = 8,
            MaxSize = 20,
            VelocityScale = 0.1,
            SmoothTime = 0.2
        },
        
        -- Custom Style
        Style = "cross", -- "cross", "circle", "square", "triangle", "plus", "x"
        CustomLines = {}
    }
    
    -- Merge user config
    if config then
        self:UpdateConfig(config)
    end
    
    --// Drawing Objects
    self.Objects = {
        Lines = {},
        Outlines = {},
        CenterDot = Drawing.new("Circle"),
        CenterDotOutline = Drawing.new("Circle")
    }
    
    --// Animation State
    self.AnimState = {
        rotation = 0,
        pulse = 0,
        rainbow = 0,
        expanding = false,
        expandProgress = 0,
        shaking = false,
        shakeProgress = 0,
        currentSize = self.Config.Size,
        dynamicSize = self.Config.Size
    }
    
    --// Internal Variables
    self.Position = Vector2.new(0, 0)
    self.RenderConnection = nil
    self.LastUpdate = tick()
    
    --// Initialize
    self:CreateDrawingObjects()
    self:Start()
    
    return self
end

--// Create Drawing Objects Based on Style
function CrosshairLib:CreateDrawingObjects()
    -- Clear existing objects
    for _, line in pairs(self.Objects.Lines) do
        line:Remove()
    end
    for _, outline in pairs(self.Objects.Outlines) do
        outline:Remove()
    end
    
    self.Objects.Lines = {}
    self.Objects.Outlines = {}
    
    local style = self.Config.Style:lower()
    
    if style == "cross" or style == "plus" then
        -- Standard crosshair (4 lines)
        for i = 1, 4 do
            local line = Drawing.new("Line")
            local outline = Drawing.new("Line")
            table.insert(self.Objects.Lines, line)
            table.insert(self.Objects.Outlines, outline)
        end
        
    elseif style == "x" then
        -- Diagonal crosshair
        for i = 1, 4 do
            local line = Drawing.new("Line")
            local outline = Drawing.new("Line")
            table.insert(self.Objects.Lines, line)
            table.insert(self.Objects.Outlines, outline)
        end
        self.Config.Rotation = 45
        
    elseif style == "circle" then
        -- Circle segments
        for i = 1, 32 do
            local line = Drawing.new("Line")
            local outline = Drawing.new("Line")
            table.insert(self.Objects.Lines, line)
            table.insert(self.Objects.Outlines, outline)
        end
        
    elseif style == "square" then
        -- Square outline
        for i = 1, 4 do
            local line = Drawing.new("Line")
            local outline = Drawing.new("Line")
            table.insert(self.Objects.Lines, line)
            table.insert(self.Objects.Outlines, outline)
        end
        
    elseif style == "triangle" then
        -- Triangle
        for i = 1, 3 do
            local line = Drawing.new("Line")
            local outline = Drawing.new("Line")
            table.insert(self.Objects.Lines, line)
            table.insert(self.Objects.Outlines, outline)
        end
    end
    
    -- Custom lines
    for _, customLine in pairs(self.Config.CustomLines) do
        local line = Drawing.new("Line")
        local outline = Drawing.new("Line")
        table.insert(self.Objects.Lines, line)
        table.insert(self.Objects.Outlines, outline)
    end
end

--// Update Configuration
function CrosshairLib:UpdateConfig(newConfig)
    local function deepMerge(target, source)
        for key, value in pairs(source) do
            if type(value) == "table" and type(target[key]) == "table" then
                deepMerge(target[key], value)
            else
                target[key] = value
            end
        end
    end
    
    deepMerge(self.Config, newConfig)
    
    -- Recreate objects if style changed
    if newConfig.Style then
        self:CreateDrawingObjects()
    end
end

--// Calculate Position
function CrosshairLib:CalculatePosition()
    local basePos
    
    if self.Config.FollowMouse then
        basePos = UserInputService:GetMouseLocation()
    else
        basePos = Camera.ViewportSize / 2
    end
    
    -- Apply shake
    if self.AnimState.shaking then
        local shake = self.Config.Animations.ShakeIntensity
        local offset = Vector2.new(
            math.random(-shake, shake) * self.AnimState.shakeProgress,
            math.random(-shake, shake) * self.AnimState.shakeProgress
        )
        basePos = basePos + offset
    end
    
    -- Apply offset
    basePos = basePos + Vector2.new(self.Config.OffsetX, self.Config.OffsetY)
    
    return basePos
end

--// Update Animations
function CrosshairLib:UpdateAnimations(deltaTime)
    local anim = self.Config.Animations
    
    -- Rotation
    if anim.SpinSpeed ~= 0 then
        self.AnimState.rotation = (self.AnimState.rotation + anim.SpinSpeed * deltaTime) % 360
    end
    
    -- Pulse
    if anim.PulseSpeed ~= 0 then
        self.AnimState.pulse = self.AnimState.pulse + anim.PulseSpeed * deltaTime
        local pulseOffset = math.sin(self.AnimState.pulse) * anim.PulseRange
        self.AnimState.currentSize = self.Config.Size + pulseOffset
    else
        self.AnimState.currentSize = self.Config.Size
    end
    
    -- Rainbow
    if anim.RainbowSpeed ~= 0 then
        self.AnimState.rainbow = (self.AnimState.rainbow + anim.RainbowSpeed * deltaTime) % 1
    end
    
    -- Expand animation
    if self.AnimState.expanding then
        self.AnimState.expandProgress = math.min(1, self.AnimState.expandProgress + deltaTime / anim.ExpandDuration)
        if self.AnimState.expandProgress >= 1 then
            self.AnimState.expanding = false
            self.AnimState.expandProgress = 0
        end
    end
    
    -- Shake animation
    if self.AnimState.shaking then
        self.AnimState.shakeProgress = math.max(0, self.AnimState.shakeProgress - deltaTime / anim.ShakeDuration)
        if self.AnimState.shakeProgress <= 0 then
            self.AnimState.shaking = false
        end
    end
    
    -- Dynamic size
    if self.Config.Dynamic.Enabled then
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local velocity = humanoidRootPart.AssemblyLinearVelocity.Magnitude
                local targetSize = math.clamp(
                    self.Config.Dynamic.MinSize + velocity * self.Config.Dynamic.VelocityScale,
                    self.Config.Dynamic.MinSize,
                    self.Config.Dynamic.MaxSize
                )
                
                -- Smooth transition
                local smoothFactor = math.min(1, deltaTime / self.Config.Dynamic.SmoothTime)
                self.AnimState.dynamicSize = LerpNumber(self.AnimState.dynamicSize, targetSize, smoothFactor)
            end
        end
    end
end

--// Render Crosshair
function CrosshairLib:Render()
    if not self.Config.Enabled then
        for _, obj in pairs(self.Objects.Lines) do
            obj.Visible = false
        end
        for _, obj in pairs(self.Objects.Outlines) do
            obj.Visible = false
        end
        self.Objects.CenterDot.Visible = false
        self.Objects.CenterDotOutline.Visible = false
        return
    end
    
    local currentTime = tick()
    local deltaTime = currentTime - self.LastUpdate
    self.LastUpdate = currentTime
    
    -- Update animations
    self:UpdateAnimations(deltaTime)
    
    -- Calculate position
    self.Position = self:CalculatePosition()
    
    -- Calculate size
    local finalSize = self.AnimState.currentSize
    if self.Config.Dynamic.Enabled then
        finalSize = self.AnimState.dynamicSize
    end
    if self.AnimState.expanding then
        local expandOffset = self.Config.Animations.ExpandAmount * (1 - self.AnimState.expandProgress)
        finalSize = finalSize + expandOffset
    end
    
    -- Calculate color
    local color = self.Config.Color
    if self.Config.Animations.RainbowSpeed ~= 0 then
        color = Color3.fromHSV(self.AnimState.rainbow, 1, 1)
    end
    
    -- Calculate rotation
    local totalRotation = self.Config.Rotation + self.AnimState.rotation
    
    -- Render based on style
    local style = self.Config.Style:lower()
    
    if style == "cross" or style == "plus" or style == "x" then
        self:RenderCross(finalSize, totalRotation, color)
    elseif style == "circle" then
        self:RenderCircle(finalSize, color)
    elseif style == "square" then
        self:RenderSquare(finalSize, totalRotation, color)
    elseif style == "triangle" then
        self:RenderTriangle(finalSize, totalRotation, color)
    end
    
    -- Render center dot
    self:RenderCenterDot(color)
end

--// Render Cross Style
function CrosshairLib:RenderCross(size, rotation, color)
    local gap = self.Config.GapSize
    local thickness = self.Config.Thickness
    local rad = math.rad(rotation)
    
    local directions = {
        {x = 1, y = 0},   -- Right
        {x = -1, y = 0},  -- Left
        {x = 0, y = 1},   -- Down
        {x = 0, y = -1}   -- Up
    }
    
    for i, dir in ipairs(directions) do
        if self.Objects.Lines[i] then
            -- Rotate direction
            local rotX = dir.x * math.cos(rad) - dir.y * math.sin(rad)
            local rotY = dir.x * math.sin(rad) + dir.y * math.cos(rad)
            
            local from = self.Position + Vector2.new(rotX * gap, rotY * gap)
            local to = self.Position + Vector2.new(rotX * size, rotY * size)
            
            -- Outline
            if self.Config.Outline.Enabled and self.Objects.Outlines[i] then
                self.Objects.Outlines[i].Visible = true
                self.Objects.Outlines[i].From = from
                self.Objects.Outlines[i].To = to
                self.Objects.Outlines[i].Color = self.Config.Outline.Color
                self.Objects.Outlines[i].Thickness = thickness + self.Config.Outline.Thickness * 2
                self.Objects.Outlines[i].Transparency = self.Config.Outline.Transparency
            else
                self.Objects.Outlines[i].Visible = false
            end
            
            -- Main line
            self.Objects.Lines[i].Visible = true
            self.Objects.Lines[i].From = from
            self.Objects.Lines[i].To = to
            self.Objects.Lines[i].Color = color
            self.Objects.Lines[i].Thickness = thickness
            self.Objects.Lines[i].Transparency = self.Config.Transparency
        end
    end
end

--// Render Circle Style
function CrosshairLib:RenderCircle(size, color)
    local segments = #self.Objects.Lines
    local angleStep = (math.pi * 2) / segments
    
    for i = 1, segments do
        local angle1 = angleStep * (i - 1)
        local angle2 = angleStep * i
        
        local from = self.Position + Vector2.new(
            math.cos(angle1) * size,
            math.sin(angle1) * size
        )
        local to = self.Position + Vector2.new(
            math.cos(angle2) * size,
            math.sin(angle2) * size
        )
        
        -- Outline
        if self.Config.Outline.Enabled and self.Objects.Outlines[i] then
            self.Objects.Outlines[i].Visible = true
            self.Objects.Outlines[i].From = from
            self.Objects.Outlines[i].To = to
            self.Objects.Outlines[i].Color = self.Config.Outline.Color
            self.Objects.Outlines[i].Thickness = self.Config.Thickness + self.Config.Outline.Thickness * 2
            self.Objects.Outlines[i].Transparency = self.Config.Outline.Transparency
        else
            self.Objects.Outlines[i].Visible = false
        end
        
        -- Main line
        self.Objects.Lines[i].Visible = true
        self.Objects.Lines[i].From = from
        self.Objects.Lines[i].To = to
        self.Objects.Lines[i].Color = color
        self.Objects.Lines[i].Thickness = self.Config.Thickness
        self.Objects.Lines[i].Transparency = self.Config.Transparency
    end
end

--// Render Square Style
function CrosshairLib:RenderSquare(size, rotation, color)
    local rad = math.rad(rotation)
    local halfSize = size
    
    local corners = {
        Vector2.new(-halfSize, -halfSize),
        Vector2.new(halfSize, -halfSize),
        Vector2.new(halfSize, halfSize),
        Vector2.new(-halfSize, halfSize)
    }
    
    -- Rotate corners
    for i, corner in ipairs(corners) do
        local rotX = corner.X * math.cos(rad) - corner.Y * math.sin(rad)
        local rotY = corner.X * math.sin(rad) + corner.Y * math.cos(rad)
        corners[i] = Vector2.new(rotX, rotY)
    end
    
    for i = 1, 4 do
        local from = self.Position + corners[i]
        local to = self.Position + corners[(i % 4) + 1]
        
        -- Outline
        if self.Config.Outline.Enabled and self.Objects.Outlines[i] then
            self.Objects.Outlines[i].Visible = true
            self.Objects.Outlines[i].From = from
            self.Objects.Outlines[i].To = to
            self.Objects.Outlines[i].Color = self.Config.Outline.Color
            self.Objects.Outlines[i].Thickness = self.Config.Thickness + self.Config.Outline.Thickness * 2
            self.Objects.Outlines[i].Transparency = self.Config.Outline.Transparency
        else
            self.Objects.Outlines[i].Visible = false
        end
        
        -- Main line
        self.Objects.Lines[i].Visible = true
        self.Objects.Lines[i].From = from
        self.Objects.Lines[i].To = to
        self.Objects.Lines[i].Color = color
        self.Objects.Lines[i].Thickness = self.Config.Thickness
        self.Objects.Lines[i].Transparency = self.Config.Transparency
    end
end

--// Render Triangle Style
function CrosshairLib:RenderTriangle(size, rotation, color)
    local rad = math.rad(rotation)
    
    local points = {
        Vector2.new(0, -size),
        Vector2.new(size * 0.866, size * 0.5),
        Vector2.new(-size * 0.866, size * 0.5)
    }
    
    -- Rotate points
    for i, point in ipairs(points) do
        local rotX = point.X * math.cos(rad) - point.Y * math.sin(rad)
        local rotY = point.X * math.sin(rad) + point.Y * math.cos(rad)
        points[i] = Vector2.new(rotX, rotY)
    end
    
    for i = 1, 3 do
        local from = self.Position + points[i]
        local to = self.Position + points[(i % 3) + 1]
        
        -- Outline
        if self.Config.Outline.Enabled and self.Objects.Outlines[i] then
            self.Objects.Outlines[i].Visible = true
            self.Objects.Outlines[i].From = from
            self.Objects.Outlines[i].To = to
            self.Objects.Outlines[i].Color = self.Config.Outline.Color
            self.Objects.Outlines[i].Thickness = self.Config.Thickness + self.Config.Outline.Thickness * 2
            self.Objects.Outlines[i].Transparency = self.Config.Outline.Transparency
        else
            self.Objects.Outlines[i].Visible = false
        end
        
        -- Main line
        self.Objects.Lines[i].Visible = true
        self.Objects.Lines[i].From = from
        self.Objects.Lines[i].To = to
        self.Objects.Lines[i].Color = color
        self.Objects.Lines[i].Thickness = self.Config.Thickness
        self.Objects.Lines[i].Transparency = self.Config.Transparency
    end
end

--// Render Center Dot
function CrosshairLib:RenderCenterDot(color)
    local dotConfig = self.Config.CenterDot
    
    if dotConfig.Enabled then
        -- Outline
        if self.Config.Outline.Enabled then
            self.Objects.CenterDotOutline.Visible = true
            self.Objects.CenterDotOutline.Position = self.Position
            self.Objects.CenterDotOutline.Radius = dotConfig.Size + self.Config.Outline.Thickness
            self.Objects.CenterDotOutline.Color = self.Config.Outline.Color
            self.Objects.CenterDotOutline.Transparency = self.Config.Outline.Transparency
            self.Objects.CenterDotOutline.Filled = dotConfig.Filled
            self.Objects.CenterDotOutline.NumSides = dotConfig.Segments
        else
            self.Objects.CenterDotOutline.Visible = false
        end
        
        -- Main dot
        self.Objects.CenterDot.Visible = true
        self.Objects.CenterDot.Position = self.Position
        self.Objects.CenterDot.Radius = dotConfig.Size
        self.Objects.CenterDot.Color = self.Config.Animations.RainbowSpeed ~= 0 and color or dotConfig.Color
        self.Objects.CenterDot.Transparency = dotConfig.Transparency
        self.Objects.CenterDot.Filled = dotConfig.Filled
        self.Objects.CenterDot.NumSides = dotConfig.Segments
    else
        self.Objects.CenterDot.Visible = false
        self.Objects.CenterDotOutline.Visible = false
    end
end

--// Animation Triggers
function CrosshairLib:TriggerExpand()
    if self.Config.Animations.ExpandOnShoot then
        self.AnimState.expanding = true
        self.AnimState.expandProgress = 0
    end
end

function CrosshairLib:TriggerShake()
    if self.Config.Animations.ShakeOnHit then
        self.AnimState.shaking = true
        self.AnimState.shakeProgress = 1
    end
end

--// Control Functions
function CrosshairLib:Start()
    if self.RenderConnection then return end
    
    self.RenderConnection = RunService.RenderStepped:Connect(function()
        self:Render()
    end)
end

function CrosshairLib:Stop()
    if self.RenderConnection then
        self.RenderConnection:Disconnect()
        self.RenderConnection = nil
    end
    
    -- Hide all objects
    for _, obj in pairs(self.Objects.Lines) do
        obj.Visible = false
    end
    for _, obj in pairs(self.Objects.Outlines) do
        obj.Visible = false
    end
    self.Objects.CenterDot.Visible = false
    self.Objects.CenterDotOutline.Visible = false
end

function CrosshairLib:Destroy()
    self:Stop()
    
    -- Remove all drawing objects
    for _, line in pairs(self.Objects.Lines) do
        line:Remove()
    end
    for _, outline in pairs(self.Objects.Outlines) do
        outline:Remove()
    end
    self.Objects.CenterDot:Remove()
    self.Objects.CenterDotOutline:Remove()
    
    getgenv().CrosshairLib = nil
end

--// Presets
CrosshairLib.Presets = {
    Default = {
        Style = "cross",
        Size = 12,
        Thickness = 2,
        Color = Color3.fromRGB(0, 255, 0),
        GapSize = 5
    },
    
    Dot = {
        Style = "cross",
        Size = 0,
        CenterDot = {
            Enabled = true,
            Size = 2,
            Color = Color3.fromRGB(255, 255, 255)
        }
    },
    
    Circle = {
        Style = "circle",
        Size = 15,
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255)
    },
    
    Dynamic = {
        Style = "cross",
        Size = 10,
        Dynamic = {
            Enabled = true,
            MinSize = 8,
            MaxSize = 25,
            VelocityScale = 0.15
        }
    },
    
    Rainbow = {
        Style = "cross",
        Size = 12,
        Animations = {
            RainbowSpeed = 2,
            SpinSpeed = 45
        }
    },
    
    Tactical = {
        Style = "cross",
        Size = 10,
        Thickness = 1,
        Color = Color3.fromRGB(255, 0, 0),
        GapSize = 3,
        CenterDot = {
            Enabled = true,
            Size = 1,
            Color = Color3.fromRGB(255, 0, 0)
        },
        Outline = {
            Enabled = true,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.7
        }
    }
}

return CrosshairLib