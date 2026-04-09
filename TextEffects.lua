local TextEffects = {}
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Typing effect
function TextEffects.createTypingText(config)
    config = config or {}
    
    local typingText = {
        position = config.position or Vector2.new(100, 100),
        fullText = config.text or "",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        speed = config.speed or 10, -- characters per second
        onComplete = config.onComplete,
        
        _drawing = nil,
        _currentIndex = 0,
        _elapsed = 0,
        _active = false,
        _connection = nil
    }
    
    function typingText:start()
        if self._active then return end
        self._active = true
        
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = ""
            self._drawing.Size = self.size
            self._drawing.Position = self.position
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._currentIndex = 0
        self._elapsed = 0
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            if not self._active then return end
            
            self._elapsed = self._elapsed + dt
            local targetIndex = math.floor(self._elapsed * self.speed)
            
            if targetIndex > self._currentIndex and self._currentIndex < #self.fullText then
                self._currentIndex = math.min(targetIndex, #self.fullText)
                self._drawing.Text = string.sub(self.fullText, 1, self._currentIndex)
                
                if self._currentIndex >= #self.fullText then
                    self._active = false
                    if self.onComplete then
                        self.onComplete()
                    end
                end
            end
        end)
    end
    
    function typingText:stop()
        self._active = false
        if self._connection then
            self._connection:Disconnect()
        end
    end
    
    function typingText:destroy()
        self:stop()
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return typingText
end

-- Rainbow text effect
function TextEffects.createRainbowText(config)
    config = config or {}
    
    local rainbowText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Rainbow",
        size = config.size or 20,
        speed = config.speed or 1,
        
        _drawing = nil,
        _hue = 0,
        _connection = nil
    }
    
    function rainbowText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Position = self.position
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._hue = (self._hue + dt * self.speed) % 1
            self._drawing.Color = Color3.fromHSV(self._hue, 1, 1)
        end)
    end
    
    function rainbowText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return rainbowText
end

-- Shake effect
function TextEffects.createShakingText(config)
    config = config or {}
    
    local shakingText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Shaking",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        intensity = config.intensity or 5,
        
        _drawing = nil,
        _connection = nil
    }
    
    function shakingText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function()
            local offset = Vector2.new(
                (math.random() - 0.5) * self.intensity * 2,
                (math.random() - 0.5) * self.intensity * 2
            )
            self._drawing.Position = self.position + offset
        end)
    end
    
    function shakingText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return shakingText
end

-- Wave/Floating effect
function TextEffects.createWaveText(config)
    config = config or {}
    
    local waveText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Wave",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        amplitude = config.amplitude or 10,
        frequency = config.frequency or 2,
        speed = config.speed or 1,
        
        _drawing = nil,
        _time = 0,
        _connection = nil
    }
    
    function waveText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._time = self._time + dt * self.speed
            local offset = math.sin(self._time * self.frequency) * self.amplitude
            self._drawing.Position = self.position + Vector2.new(0, offset)
        end)
    end
    
    function waveText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return waveText
end

-- Fade in/out effect
function TextEffects.createFadingText(config)
    config = config or {}
    
    local fadingText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Fade",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        fadeSpeed = config.fadeSpeed or 1,
        mode = config.mode or "inout", -- "in", "out", "inout"
        
        _drawing = nil,
        _time = 0,
        _connection = nil
    }
    
    function fadingText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Position = self.position
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._time = self._time + dt * self.fadeSpeed
            
            local alpha
            if self.mode == "in" then
                alpha = math.min(self._time, 1)
            elseif self.mode == "out" then
                alpha = math.max(1 - self._time, 0)
            else -- inout
                alpha = (math.sin(self._time * math.pi) + 1) / 2
            end
            
            self._drawing.Transparency = alpha
            self._drawing.Color = self.color
        end)
    end
    
    function fadingText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return fadingText
end

-- Glitch effect
function TextEffects.createGlitchText(config)
    config = config or {}
    
    local glitchText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "GLITCH",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        intensity = config.intensity or 0.1, -- 0-1, how often glitches occur
        
        _drawing = nil,
        _connection = nil,
        _glitchChars = "!@#$%^&*()_+-=[]{}|;:,.<>?/~`"
    }
    
    function glitchText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Position = self.position
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function()
            if math.random() < self.intensity then
                local glitchedText = ""
                for i = 1, #self.text do
                    if math.random() < 0.3 then
                        local randomChar = string.sub(self._glitchChars, math.random(1, #self._glitchChars), math.random(1, #self._glitchChars))
                        glitchedText = glitchedText .. randomChar
                    else
                        glitchedText = glitchedText .. string.sub(self.text, i, i)
                    end
                end
                self._drawing.Text = glitchedText
                
                -- Random position offset
                local offset = Vector2.new(
                    (math.random() - 0.5) * 10,
                    (math.random() - 0.5) * 10
                )
                self._drawing.Position = self.position + offset
            else
                self._drawing.Text = self.text
                self._drawing.Position = self.position
            end
        end)
    end
    
    function glitchText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return glitchText
end

-- Pulsating/Breathing effect
function TextEffects.createPulseText(config)
    config = config or {}
    
    local pulseText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Pulse",
        baseSize = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        pulseAmount = config.pulseAmount or 5,
        speed = config.speed or 2,
        
        _drawing = nil,
        _time = 0,
        _connection = nil
    }
    
    function pulseText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Position = self.position
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._time = self._time + dt * self.speed
            local scale = 1 + (math.sin(self._time) * 0.5 + 0.5) * (self.pulseAmount / self.baseSize)
            self._drawing.Size = self.baseSize * scale
        end)
    end
    
    function pulseText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return pulseText
end

-- Scramble/Decrypt effect
function TextEffects.createScrambleText(config)
    config = config or {}
    
    local scrambleText = {
        position = config.position or Vector2.new(100, 100),
        fullText = config.text or "DECRYPT",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(0, 255, 0),
        revealSpeed = config.revealSpeed or 0.5, -- seconds per character
        onComplete = config.onComplete,
        
        _drawing = nil,
        _revealed = {},
        _elapsed = 0,
        _active = false,
        _connection = nil,
        _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
    }
    
    function scrambleText:start()
        if self._active then return end
        self._active = true
        
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Size = self.size
            self._drawing.Position = self.position
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._revealed = {}
        for i = 1, #self.fullText do
            self._revealed[i] = false
        end
        self._elapsed = 0
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            if not self._active then return end
            
            self._elapsed = self._elapsed + dt
            local numRevealed = math.floor(self._elapsed / self.revealSpeed)
            
            local displayText = ""
            for i = 1, #self.fullText do
                if i <= numRevealed then
                    self._revealed[i] = true
                    displayText = displayText .. string.sub(self.fullText, i, i)
                else
                    if string.sub(self.fullText, i, i) == " " then
                        displayText = displayText .. " "
                    else
                        local randomChar = string.sub(self._chars, math.random(1, #self._chars), math.random(1, #self._chars))
                        displayText = displayText .. randomChar
                    end
                end
            end
            
            self._drawing.Text = displayText
            
            if numRevealed >= #self.fullText then
                self._active = false
                if self.onComplete then
                    self.onComplete()
                end
            end
        end)
    end
    
    function scrambleText:stop()
        self._active = false
        if self._connection then
            self._connection:Disconnect()
        end
    end
    
    function scrambleText:destroy()
        self:stop()
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return scrambleText
end

-- Bouncing text
function TextEffects.createBouncingText(config)
    config = config or {}
    
    local bouncingText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Bounce",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        bounceHeight = config.bounceHeight or 30,
        speed = config.speed or 3,
        
        _drawing = nil,
        _time = 0,
        _connection = nil
    }
    
    function bouncingText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._time = self._time + dt * self.speed
            local bounce = math.abs(math.sin(self._time)) * self.bounceHeight
            self._drawing.Position = self.position - Vector2.new(0, bounce)
        end)
    end
    
    function bouncingText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return bouncingText
end

-- Spinning text
function TextEffects.createSpinningText(config)
    config = config or {}
    
    local spinningText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Spin",
        size = config.size or 20,
        color = config.color or Color3.fromRGB(255, 255, 255),
        radius = config.radius or 50,
        speed = config.speed or 2,
        
        _drawing = nil,
        _angle = 0,
        _connection = nil
    }
    
    function spinningText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Color = self.color
            self._drawing.Visible = true
            self._drawing.Outline = true
            self._drawing.Center = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._angle = self._angle + dt * self.speed
            local x = self.position.X + math.cos(self._angle) * self.radius
            local y = self.position.Y + math.sin(self._angle) * self.radius
            self._drawing.Position = Vector2.new(x, y)
        end)
    end
    
    function spinningText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return spinningText
end

-- Gradient color cycling
function TextEffects.createGradientText(config)
    config = config or {}
    
    local gradientText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Gradient",
        size = config.size or 20,
        color1 = config.color1 or Color3.fromRGB(255, 0, 0),
        color2 = config.color2 or Color3.fromRGB(0, 0, 255),
        speed = config.speed or 1,
        
        _drawing = nil,
        _time = 0,
        _connection = nil
    }
    
    function gradientText:start()
        if not self._drawing then
            self._drawing = Drawing.new("Text")
            self._drawing.Text = self.text
            self._drawing.Size = self.size
            self._drawing.Position = self.position
            self._drawing.Visible = true
            self._drawing.Outline = true
        end
        
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self._time = self._time + dt * self.speed
            local alpha = (math.sin(self._time) + 1) / 2
            self._drawing.Color = self.color1:Lerp(self.color2, alpha)
        end)
    end
    
    function gradientText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        if self._drawing then
            self._drawing:Remove()
        end
    end
    
    return gradientText
end

-- Chromatic aberration effect
function TextEffects.createChromaticText(config)
    config = config or {}
    
    local chromaticText = {
        position = config.position or Vector2.new(100, 100),
        text = config.text or "Chromatic",
        size = config.size or 20,
        offset = config.offset or 2,
        
        _drawings = {},
        _connection = nil
    }
    
    function chromaticText:start()
        -- Create three text objects for RGB channels
        local colors = {
            Color3.fromRGB(255, 0, 0),
            Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255)
        }
        
        for i = 1, 3 do
            local drawing = Drawing.new("Text")
            drawing.Text = self.text
            drawing.Size = self.size
            drawing.Color = colors[i]
            drawing.Visible = true
            drawing.Outline = false
            drawing.Transparency = 0.7
            table.insert(self._drawings, drawing)
        end
        
        self._connection = RunService.RenderStepped:Connect(function()
            local offsets = {
                Vector2.new(-self.offset, 0),
                Vector2.new(0, 0),
                Vector2.new(self.offset, 0)
            }
            
            for i, drawing in ipairs(self._drawings) do
                drawing.Position = self.position + offsets[i]
            end
        end)
    end
    
    function chromaticText:destroy()
        if self._connection then
            self._connection:Disconnect()
        end
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
    end
    
    return chromaticText
end

return TextEffects