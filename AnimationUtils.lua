local AnimationUtils = {}

-- Easing functions
AnimationUtils.Easing = {
    Linear = function(t) return t end,
    
    -- Quadratic
    InQuad = function(t) return t * t end,
    OutQuad = function(t) return t * (2 - t) end,
    InOutQuad = function(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end,
    
    -- Cubic
    InCubic = function(t) return t * t * t end,
    OutCubic = function(t) return 1 - math.pow(1 - t, 3) end,
    InOutCubic = function(t) return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2 end,
    
    -- Quartic
    InQuart = function(t) return t * t * t * t end,
    OutQuart = function(t) return 1 - math.pow(1 - t, 4) end,
    InOutQuart = function(t) return t < 0.5 and 8 * t * t * t * t or 1 - math.pow(-2 * t + 2, 4) / 2 end,
    
    -- Quintic
    InQuint = function(t) return t * t * t * t * t end,
    OutQuint = function(t) return 1 - math.pow(1 - t, 5) end,
    InOutQuint = function(t) return t < 0.5 and 16 * t * t * t * t * t or 1 - math.pow(-2 * t + 2, 5) / 2 end,
    
    -- Sine
    InSine = function(t) return 1 - math.cos(t * math.pi / 2) end,
    OutSine = function(t) return math.sin(t * math.pi / 2) end,
    InOutSine = function(t) return -(math.cos(math.pi * t) - 1) / 2 end,
    
    -- Exponential
    InExpo = function(t) return t == 0 and 0 or math.pow(2, 10 * t - 10) end,
    OutExpo = function(t) return t == 1 and 1 or 1 - math.pow(2, -10 * t) end,
    InOutExpo = function(t)
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return t < 0.5 and math.pow(2, 20 * t - 10) / 2 or (2 - math.pow(2, -20 * t + 10)) / 2
    end,
    
    -- Circular
    InCirc = function(t) return 1 - math.sqrt(1 - t * t) end,
    OutCirc = function(t) return math.sqrt(1 - math.pow(t - 1, 2)) end,
    InOutCirc = function(t)
        return t < 0.5 
            and (1 - math.sqrt(1 - math.pow(2 * t, 2))) / 2
            or (math.sqrt(1 - math.pow(-2 * t + 2, 2)) + 1) / 2
    end,
    
    -- Back
    InBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * t * t * t - c1 * t * t
    end,
    OutBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
    end,
    InOutBack = function(t)
        local c1 = 1.70158
        local c2 = c1 * 1.525
        return t < 0.5
            and (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
            or (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
    end,
    
    -- Elastic
    InElastic = function(t)
        local c4 = (2 * math.pi) / 3
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4)
    end,
    OutElastic = function(t)
        local c4 = (2 * math.pi) / 3
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    end,
    InOutElastic = function(t)
        local c5 = (2 * math.pi) / 4.5
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return t < 0.5
            and -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
            or (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
    end,
    
    -- Bounce
    InBounce = function(t)
        return 1 - AnimationUtils.Easing.OutBounce(1 - t)
    end,
    OutBounce = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end,
    InOutBounce = function(t)
        return t < 0.5
            and (1 - AnimationUtils.Easing.OutBounce(1 - 2 * t)) / 2
            or (1 + AnimationUtils.Easing.OutBounce(2 * t - 1)) / 2
    end,
}

-- Helper function to lerp between colors
local function lerpColor3(c1, c2, alpha)
    return Color3.new(
        c1.R + (c2.R - c1.R) * alpha,
        c1.G + (c2.G - c1.G) * alpha,
        c1.B + (c2.B - c1.B) * alpha
    )
end

-- Helper function to lerp between Vector2
local function lerpVector2(v1, v2, alpha)
    return Vector2.new(
        v1.X + (v2.X - v1.X) * alpha,
        v1.Y + (v2.Y - v1.Y) * alpha
    )
end

-- Animator class
function AnimationUtils.createAnimator()
    local animator = {
        _animations = {},
        _sequences = {},
        _paused = false
    }
    
    -- Animate a single property
    function animator:animate(object, property, endValue, duration, easingFunc, callback)
        local startValue
        
        -- Handle Drawing objects
        if isrenderobj and isrenderobj(object) then
            startValue = getrenderproperty(object, property)
        else
            startValue = object[property]
        end
        
        local startTime = tick()
        
        local anim = {
            object = object,
            property = property,
            startValue = startValue,
            endValue = endValue,
            duration = duration,
            easingFunc = easingFunc or AnimationUtils.Easing.Linear,
            callback = callback,
            startTime = startTime,
            paused = false,
            pauseTime = 0,
            id = #self._animations + 1
        }
        
        table.insert(self._animations, anim)
        return anim
    end
    
    -- Animate multiple properties at once
    function animator:animateMultiple(object, properties, duration, easingFunc, callback)
        local anims = {}
        local completedCount = 0
        local totalProps = 0
        
        for _ in pairs(properties) do
            totalProps = totalProps + 1
        end
        
        for prop, endValue in pairs(properties) do
            local anim = self:animate(object, prop, endValue, duration, easingFunc, function()
                completedCount = completedCount + 1
                if completedCount >= totalProps and callback then
                    callback()
                end
            end)
            table.insert(anims, anim)
        end
        
        return anims
    end
    
    -- Create a sequence of animations
    function animator:sequence()
        local seq = {
            steps = {},
            currentStep = 0,
            animator = self
        }
        
        function seq:then(object, property, endValue, duration, easingFunc)
            table.insert(self.steps, {
                object = object,
                property = property,
                endValue = endValue,
                duration = duration,
                easingFunc = easingFunc
            })
            return self
        end
        
        function seq:thenMultiple(object, properties, duration, easingFunc)
            table.insert(self.steps, {
                object = object,
                properties = properties,
                duration = duration,
                easingFunc = easingFunc,
                isMultiple = true
            })
            return self
        end
        
        function seq:wait(duration)
            table.insert(self.steps, {
                isWait = true,
                duration = duration
            })
            return self
        end
        
        function seq:play(callback)
            self.currentStep = 0
            self.callback = callback
            table.insert(self.animator._sequences, self)
            self:playNext()
            return self
        end
        
        function seq:playNext()
            self.currentStep = self.currentStep + 1
            if self.currentStep > #self.steps then
                -- Sequence complete
                if self.callback then
                    self.callback()
                end
                return
            end
            
            local step = self.steps[self.currentStep]
            
            if step.isWait then
                task.wait(step.duration)
                self:playNext()
            elseif step.isMultiple then
                self.animator:animateMultiple(
                    step.object,
                    step.properties,
                    step.duration,
                    step.easingFunc,
                    function() self:playNext() end
                )
            else
                self.animator:animate(
                    step.object,
                    step.property,
                    step.endValue,
                    step.duration,
                    step.easingFunc,
                    function() self:playNext() end
                )
            end
        end
        
        return seq
    end
    
    -- Fade in a drawing object
    function animator:fadeIn(object, duration, easingFunc, callback)
        return self:animate(object, "Transparency", 1, duration, easingFunc, callback)
    end
    
    -- Fade out a drawing object
    function animator:fadeOut(object, duration, easingFunc, callback)
        return self:animate(object, "Transparency", 0, duration, easingFunc, callback)
    end
    
    -- Slide an object
    function animator:slide(object, endPosition, duration, easingFunc, callback)
        return self:animate(object, "Position", endPosition, duration, easingFunc, callback)
    end
    
    -- Scale an object (for Drawing objects with Size property)
    function animator:scale(object, endSize, duration, easingFunc, callback)
        return self:animate(object, "Size", endSize, duration, easingFunc, callback)
    end
    
    -- Color transition
    function animator:colorTransition(object, endColor, duration, easingFunc, callback)
        return self:animate(object, "Color", endColor, duration, easingFunc, callback)
    end
    
    -- Pause a specific animation
    function animator:pauseAnimation(anim)
        if not anim.paused then
            anim.paused = true
            anim.pauseTime = tick()
        end
    end
    
    -- Resume a specific animation
    function animator:resumeAnimation(anim)
        if anim.paused then
            local pauseDuration = tick() - anim.pauseTime
            anim.startTime = anim.startTime + pauseDuration
            anim.paused = false
        end
    end
    
    -- Pause all animations
    function animator:pause()
        self._paused = true
        for _, anim in ipairs(self._animations) do
            if not anim.paused then
                anim.pauseTime = tick()
            end
        end
    end
    
    -- Resume all animations
    function animator:resume()
        if self._paused then
            local now = tick()
            for _, anim in ipairs(self._animations) do
                if not anim.paused then
                    local pauseDuration = now - anim.pauseTime
                    anim.startTime = anim.startTime + pauseDuration
                end
            end
            self._paused = false
        end
    end
    
    -- Update animations
    function animator:update(dt)
        if self._paused then return end
        
        local currentTime = tick()
        local toRemove = {}
        
        for i, anim in ipairs(self._animations) do
            if not anim.paused then
                local elapsed = currentTime - anim.startTime
                local alpha = math.clamp(elapsed / anim.duration, 0, 1)
                local eased = anim.easingFunc(alpha)
                
                -- Handle different value types
                local newValue
                if type(anim.startValue) == "table" and anim.startValue.X and anim.startValue.Y then
                    -- Vector2
                    newValue = lerpVector2(anim.startValue, anim.endValue, eased)
                elseif type(anim.startValue) == "table" and anim.startValue.R then
                    -- Color3
                    newValue = lerpColor3(anim.startValue, anim.endValue, eased)
                elseif type(anim.startValue) == "number" then
                    newValue = anim.startValue + (anim.endValue - anim.startValue) * eased
                elseif type(anim.startValue) == "boolean" then
                    newValue = alpha >= 0.5 and anim.endValue or anim.startValue
                end
                
                -- Set the property
                if isrenderobj and isrenderobj(anim.object) then
                    setrenderproperty(anim.object, anim.property, newValue)
                else
                    anim.object[anim.property] = newValue
                end
                
                if alpha >= 1 then
                    table.insert(toRemove, i)
                    if anim.callback then
                        task.spawn(anim.callback)
                    end
                end
            end
        end
        
        -- Remove completed animations
        for i = #toRemove, 1, -1 do
            table.remove(self._animations, toRemove[i])
        end
    end
    
    -- Stop a specific animation
    function animator:stop(anim)
        for i, a in ipairs(self._animations) do
            if a == anim or a.id == anim then
                table.remove(self._animations, i)
                return true
            end
        end
        return false
    end
    
    -- Clear all animations
    function animator:clear()
        self._animations = {}
        self._sequences = {}
    end
    
    -- Get active animation count
    function animator:getActiveCount()
        return #self._animations
    end
    
    return animator
end

-- Spring physics animator (bonus feature)
function AnimationUtils.createSpring(object, property, stiffness, damping)
    stiffness = stiffness or 100
    damping = damping or 10
    
    local spring = {
        object = object,
        property = property,
        target = nil,
        velocity = 0,
        stiffness = stiffness,
        damping = damping,
        active = false
    }
    
    function spring:setTarget(value)
        self.target = value
        self.active = true
    end
    
    function spring:update(dt)
        if not self.active or not self.target then return end
        
        local current
        if isrenderobj and isrenderobj(self.object) then
            current = getrenderproperty(self.object, self.property)
        else
            current = self.object[self.property]
        end
        
        if type(current) == "number" then
            local force = (self.target - current) * self.stiffness
            local dampingForce = self.velocity * self.damping
            local acceleration = force - dampingForce
            
            self.velocity = self.velocity + acceleration * dt
            local newValue = current + self.velocity * dt
            
            if isrenderobj and isrenderobj(self.object) then
                setrenderproperty(self.object, self.property, newValue)
            else
                self.object[self.property] = newValue
            end
            
            -- Stop if close enough
            if math.abs(self.target - newValue) < 0.01 and math.abs(self.velocity) < 0.01 then
                self.active = false
                self.velocity = 0
            end
        end
    end
    
    return spring
end

return AnimationUtils