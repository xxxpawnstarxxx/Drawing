local GraphUtils = {}

-- Line Graph
function GraphUtils.createLineGraph(config)
    config = config or {}
    
    local graph = {
        position = config.position or Vector2.new(100, 100),
        size = config.size or Vector2.new(300, 200),
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        lineColor = config.lineColor or Color3.fromRGB(0, 255, 100),
        gridColor = config.gridColor or Color3.fromRGB(50, 50, 50),
        maxDataPoints = config.maxDataPoints or 50,
        minValue = config.minValue or 0,
        maxValue = config.maxValue or 100,
        showGrid = config.showGrid ~= false,
        thickness = config.thickness or 2,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function graph:_createBackground()
        local bg = Drawing.new("Square")
        bg.Size = self.size
        bg.Position = self.position
        bg.Color = self.backgroundColor
        bg.Filled = true
        bg.Visible = self._visible
        bg.Transparency = 0.8
        table.insert(self._drawings, bg)
        return bg
    end
    
    function graph:_createGrid()
        local gridLines = {}
        local gridCount = 5
        
        for i = 0, gridCount do
            local line = Drawing.new("Line")
            line.From = self.position + Vector2.new(0, (self.size.Y / gridCount) * i)
            line.To = self.position + Vector2.new(self.size.X, (self.size.Y / gridCount) * i)
            line.Color = self.gridColor
            line.Thickness = 1
            line.Visible = self._visible and self.showGrid
            line.Transparency = 0.5
            table.insert(self._drawings, line)
            table.insert(gridLines, line)
        end
        
        return gridLines
    end
    
    function graph:_normalizeValue(value)
        return (value - self.minValue) / (self.maxValue - self.minValue)
    end
    
    function graph:_valueToY(value)
        local normalized = self:_normalizeValue(value)
        return self.position.Y + self.size.Y - (normalized * self.size.Y)
    end
    
    function graph:addDataPoint(value)
        table.insert(self._data, value)
        if #self._data > self.maxDataPoints then
            table.remove(self._data, 1)
        end
        self:_redraw()
    end
    
    function graph:_redraw()
        -- Remove old line segments
        for i = #self._drawings, 1, -1 do
            if self._drawings[i].ClassName == "Line" and self._drawings[i].Color == self.lineColor then
                self._drawings[i]:Remove()
                table.remove(self._drawings, i)
            end
        end
        
        -- Draw new line segments
        if #self._data < 2 then return end
        
        local xStep = self.size.X / (self.maxDataPoints - 1)
        
        for i = 1, #self._data - 1 do
            local line = Drawing.new("Line")
            
            local x1 = self.position.X + ((i - 1) * xStep)
            local y1 = self:_valueToY(self._data[i])
            
            local x2 = self.position.X + (i * xStep)
            local y2 = self:_valueToY(self._data[i + 1])
            
            line.From = Vector2.new(x1, y1)
            line.To = Vector2.new(x2, y2)
            line.Color = self.lineColor
            line.Thickness = self.thickness
            line.Visible = self._visible
            
            table.insert(self._drawings, line)
        end
    end
    
    function graph:show()
        if not self._visible then
            self:_createBackground()
            if self.showGrid then
                self:_createGrid()
            end
            self._visible = true
            self:_redraw()
        end
        
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = true
        end
    end
    
    function graph:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function graph:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        self._data = {}
    end
    
    function graph:setData(data)
        self._data = data
        self:_redraw()
    end
    
    return graph
end

-- Bar Graph
function GraphUtils.createBarGraph(config)
    config = config or {}
    
    local graph = {
        position = config.position or Vector2.new(100, 100),
        size = config.size or Vector2.new(300, 200),
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        barColor = config.barColor or Color3.fromRGB(0, 150, 255),
        maxBars = config.maxBars or 10,
        maxValue = config.maxValue or 100,
        spacing = config.spacing or 5,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function graph:addBar(value, color)
        table.insert(self._data, {value = value, color = color or self.barColor})
        if #self._data > self.maxBars then
            table.remove(self._data, 1)
        end
        self:_redraw()
    end
    
    function graph:_redraw()
        -- Clear old bars
        for _, drawing in ipairs(self._drawings) do
            if drawing.ClassName == "Square" then
                drawing:Remove()
            end
        end
        self._drawings = {}
        
        -- Draw background
        local bg = Drawing.new("Square")
        bg.Size = self.size
        bg.Position = self.position
        bg.Color = self.backgroundColor
        bg.Filled = true
        bg.Visible = self._visible
        bg.Transparency = 0.8
        table.insert(self._drawings, bg)
        
        -- Draw bars
        if #self._data == 0 then return end
        
        local barWidth = (self.size.X - (self.spacing * (#self._data + 1))) / #self._data
        
        for i, data in ipairs(self._data) do
            local barHeight = (data.value / self.maxValue) * self.size.Y
            local bar = Drawing.new("Square")
            
            bar.Size = Vector2.new(barWidth, barHeight)
            bar.Position = Vector2.new(
                self.position.X + (i - 1) * (barWidth + self.spacing) + self.spacing,
                self.position.Y + self.size.Y - barHeight
            )
            bar.Color = data.color
            bar.Filled = true
            bar.Visible = self._visible
            
            table.insert(self._drawings, bar)
        end
    end
    
    function graph:show()
        self._visible = true
        self:_redraw()
    end
    
    function graph:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function graph:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
    end
    
    function graph:setData(data)
        self._data = {}
        for _, item in ipairs(data) do
            if type(item) == "table" then
                table.insert(self._data, item)
            else
                table.insert(self._data, {value = item, color = self.barColor})
            end
        end
        self:_redraw()
    end
    
    return graph
end

-- Pie Chart
function GraphUtils.createPieChart(config)
    config = config or {}
    
    local chart = {
        position = config.position or Vector2.new(200, 200),
        radius = config.radius or 100,
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        showBackground = config.showBackground ~= false,
        segments = config.segments or 32, -- Resolution of the circle
        showLabels = config.showLabels or false,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function chart:_createCircleSegment(centerX, centerY, radius, startAngle, endAngle, color)
        local points = {}
        local angleStep = (endAngle - startAngle) / self.segments
        
        -- Create triangle fan for the pie slice
        for i = 0, self.segments do
            local angle = startAngle + (angleStep * i)
            local x = centerX + math.cos(angle) * radius
            local y = centerY + math.sin(angle) * radius
            
            if i > 0 then
                local triangle = Drawing.new("Triangle")
                triangle.PointA = Vector2.new(centerX, centerY)
                triangle.PointB = Vector2.new(points[#points].X, points[#points].Y)
                triangle.PointC = Vector2.new(x, y)
                triangle.Color = color
                triangle.Filled = true
                triangle.Visible = self._visible
                triangle.Transparency = 0.9
                table.insert(self._drawings, triangle)
            end
            
            table.insert(points, {X = x, Y = y})
        end
    end
    
    function chart:_redraw()
        -- Clear old drawings
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        -- Draw background circle
        if self.showBackground then
            local bg = Drawing.new("Circle")
            bg.Position = self.position
            bg.Radius = self.radius + 10
            bg.Color = self.backgroundColor
            bg.Filled = true
            bg.Visible = self._visible
            bg.Transparency = 0.7
            table.insert(self._drawings, bg)
        end
        
        -- Calculate total value
        local total = 0
        for _, data in ipairs(self._data) do
            total = total + data.value
        end
        
        if total == 0 then return end
        
        -- Draw pie slices
        local currentAngle = -math.pi / 2 -- Start from top
        
        for _, data in ipairs(self._data) do
            local sliceAngle = (data.value / total) * (math.pi * 2)
            self:_createCircleSegment(
                self.position.X,
                self.position.Y,
                self.radius,
                currentAngle,
                currentAngle + sliceAngle,
                data.color
            )
            
            -- Draw label if enabled
            if self.showLabels and data.label then
                local midAngle = currentAngle + sliceAngle / 2
                local labelX = self.position.X + math.cos(midAngle) * (self.radius * 0.7)
                local labelY = self.position.Y + math.sin(midAngle) * (self.radius * 0.7)
                
                local text = Drawing.new("Text")
                text.Text = data.label
                text.Position = Vector2.new(labelX, labelY)
                text.Color = Color3.fromRGB(255, 255, 255)
                text.Size = 14
                text.Center = true
                text.Outline = true
                text.Visible = self._visible
                table.insert(self._drawings, text)
            end
            
            currentAngle = currentAngle + sliceAngle
        end
    end
    
    function chart:setData(data)
        self._data = data
        self:_redraw()
    end
    
    function chart:addSlice(value, color, label)
        table.insert(self._data, {
            value = value,
            color = color or Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255)),
            label = label
        })
        self:_redraw()
    end
    
    function chart:show()
        self._visible = true
        self:_redraw()
    end
    
    function chart:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function chart:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        self._data = {}
    end
    
    return chart
end

-- Donut Chart
function GraphUtils.createDonutChart(config)
    config = config or {}
    
    local chart = {
        position = config.position or Vector2.new(200, 200),
        outerRadius = config.outerRadius or 100,
        innerRadius = config.innerRadius or 60,
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        showBackground = config.showBackground ~= false,
        segments = config.segments or 32,
        showLabels = config.showLabels or false,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function chart:_createDonutSegment(centerX, centerY, innerRadius, outerRadius, startAngle, endAngle, color)
        local angleStep = (endAngle - startAngle) / self.segments
        
        for i = 0, self.segments - 1 do
            local angle1 = startAngle + (angleStep * i)
            local angle2 = startAngle + (angleStep * (i + 1))
            
            -- Outer arc points
            local outerX1 = centerX + math.cos(angle1) * outerRadius
            local outerY1 = centerY + math.sin(angle1) * outerRadius
            local outerX2 = centerX + math.cos(angle2) * outerRadius
            local outerY2 = centerY + math.sin(angle2) * outerRadius
            
            -- Inner arc points
            local innerX1 = centerX + math.cos(angle1) * innerRadius
            local innerY1 = centerY + math.sin(angle1) * innerRadius
            local innerX2 = centerX + math.cos(angle2) * innerRadius
            local innerY2 = centerY + math.sin(angle2) * innerRadius
            
            -- Create two triangles to form a quad
            local tri1 = Drawing.new("Triangle")
            tri1.PointA = Vector2.new(outerX1, outerY1)
            tri1.PointB = Vector2.new(outerX2, outerY2)
            tri1.PointC = Vector2.new(innerX1, innerY1)
            tri1.Color = color
            tri1.Filled = true
            tri1.Visible = self._visible
            tri1.Transparency = 0.9
            table.insert(self._drawings, tri1)
            
            local tri2 = Drawing.new("Triangle")
            tri2.PointA = Vector2.new(outerX2, outerY2)
            tri2.PointB = Vector2.new(innerX2, innerY2)
            tri2.PointC = Vector2.new(innerX1, innerY1)
            tri2.Color = color
            tri2.Filled = true
            tri2.Visible = self._visible
            tri2.Transparency = 0.9
            table.insert(self._drawings, tri2)
        end
    end
    
    function chart:_redraw()
        -- Clear old drawings
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        -- Draw background
        if self.showBackground then
            local bg = Drawing.new("Circle")
            bg.Position = self.position
            bg.Radius = self.outerRadius + 10
            bg.Color = self.backgroundColor
            bg.Filled = true
            bg.Visible = self._visible
            bg.Transparency = 0.7
            table.insert(self._drawings, bg)
        end
        
        -- Calculate total
        local total = 0
        for _, data in ipairs(self._data) do
            total = total + data.value
        end
        
        if total == 0 then return end
        
        -- Draw donut segments
        local currentAngle = -math.pi / 2
        
        for _, data in ipairs(self._data) do
            local sliceAngle = (data.value / total) * (math.pi * 2)
            self:_createDonutSegment(
                self.position.X,
                self.position.Y,
                self.innerRadius,
                self.outerRadius,
                currentAngle,
                currentAngle + sliceAngle,
                data.color
            )
            
            -- Draw label
            if self.showLabels and data.label then
                local midAngle = currentAngle + sliceAngle / 2
                local labelRadius = (self.innerRadius + self.outerRadius) / 2
                local labelX = self.position.X + math.cos(midAngle) * labelRadius
                local labelY = self.position.Y + math.sin(midAngle) * labelRadius
                
                local text = Drawing.new("Text")
                text.Text = data.label
                text.Position = Vector2.new(labelX, labelY)
                text.Color = Color3.fromRGB(255, 255, 255)
                text.Size = 14
                text.Center = true
                text.Outline = true
                text.Visible = self._visible
                table.insert(self._drawings, text)
            end
            
            currentAngle = currentAngle + sliceAngle
        end
        
        -- Draw center circle
        local centerCircle = Drawing.new("Circle")
        centerCircle.Position = self.position
        centerCircle.Radius = self.innerRadius
        centerCircle.Color = self.backgroundColor
        centerCircle.Filled = true
        centerCircle.Visible = self._visible
        centerCircle.Transparency = 0.9
        table.insert(self._drawings, centerCircle)
    end
    
    function chart:setData(data)
        self._data = data
        self:_redraw()
    end
    
    function chart:addSlice(value, color, label)
        table.insert(self._data, {
            value = value,
            color = color or Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255)),
            label = label
        })
        self:_redraw()
    end
    
    function chart:show()
        self._visible = true
        self:_redraw()
    end
    
    function chart:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function chart:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        self._data = {}
    end
    
    return chart
end

-- Scatter Plot
function GraphUtils.createScatterPlot(config)
    config = config or {}
    
    local plot = {
        position = config.position or Vector2.new(100, 100),
        size = config.size or Vector2.new(300, 200),
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        pointColor = config.pointColor or Color3.fromRGB(255, 100, 100),
        gridColor = config.gridColor or Color3.fromRGB(50, 50, 50),
        pointSize = config.pointSize or 4,
        showGrid = config.showGrid ~= false,
        minX = config.minX or 0,
        maxX = config.maxX or 100,
        minY = config.minY or 0,
        maxY = config.maxY or 100,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function plot:_createBackground()
        local bg = Drawing.new("Square")
        bg.Size = self.size
        bg.Position = self.position
        bg.Color = self.backgroundColor
        bg.Filled = true
        bg.Visible = self._visible
        bg.Transparency = 0.8
        table.insert(self._drawings, bg)
    end
    
    function plot:_createGrid()
        local gridCount = 5
        
        -- Horizontal lines
        for i = 0, gridCount do
            local line = Drawing.new("Line")
            line.From = self.position + Vector2.new(0, (self.size.Y / gridCount) * i)
            line.To = self.position + Vector2.new(self.size.X, (self.size.Y / gridCount) * i)
            line.Color = self.gridColor
            line.Thickness = 1
            line.Visible = self._visible and self.showGrid
            line.Transparency = 0.5
            table.insert(self._drawings, line)
        end
        
        -- Vertical lines
        for i = 0, gridCount do
            local line = Drawing.new("Line")
            line.From = self.position + Vector2.new((self.size.X / gridCount) * i, 0)
            line.To = self.position + Vector2.new((self.size.X / gridCount) * i, self.size.Y)
            line.Color = self.gridColor
            line.Thickness = 1
            line.Visible = self._visible and self.showGrid
            line.Transparency = 0.5
            table.insert(self._drawings, line)
        end
    end
    
    function plot:_normalizeX(x)
        return (x - self.minX) / (self.maxX - self.minX)
    end
    
    function plot:_normalizeY(y)
        return (y - self.minY) / (self.maxY - self.minY)
    end
    
    function plot:_toScreenX(x)
        return self.position.X + self:_normalizeX(x) * self.size.X
    end
    
    function plot:_toScreenY(y)
        return self.position.Y + self.size.Y - (self:_normalizeY(y) * self.size.Y)
    end
    
    function plot:addPoint(x, y, color)
        table.insert(self._data, {x = x, y = y, color = color or self.pointColor})
        self:_redraw()
    end
    
    function plot:_redraw()
        -- Remove old points
        for i = #self._drawings, 1, -1 do
            if self._drawings[i].ClassName == "Circle" then
                self._drawings[i]:Remove()
                table.remove(self._drawings, i)
            end
        end
        
        -- Draw points
        for _, point in ipairs(self._data) do
            local circle = Drawing.new("Circle")
            circle.Position = Vector2.new(self:_toScreenX(point.x), self:_toScreenY(point.y))
            circle.Radius = self.pointSize
            circle.Color = point.color
            circle.Filled = true
            circle.Visible = self._visible
            circle.Transparency = 0.9
            table.insert(self._drawings, circle)
        end
    end
    
    function plot:show()
        if not self._visible then
            self:_createBackground()
            if self.showGrid then
                self:_createGrid()
            end
            self._visible = true
            self:_redraw()
        end
        
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = true
        end
    end
    
    function plot:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function plot:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        self._data = {}
    end
    
    function plot:setData(data)
        self._data = data
        self:_redraw()
    end
    
    function plot:clear()
        self._data = {}
        self:_redraw()
    end
    
    return plot
end

-- Area Chart
function GraphUtils.createAreaChart(config)
    config = config or {}
    
    local chart = {
        position = config.position or Vector2.new(100, 100),
        size = config.size or Vector2.new(300, 200),
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        fillColor = config.fillColor or Color3.fromRGB(0, 255, 100),
        lineColor = config.lineColor or Color3.fromRGB(0, 200, 80),
        gridColor = config.gridColor or Color3.fromRGB(50, 50, 50),
        maxDataPoints = config.maxDataPoints or 50,
        minValue = config.minValue or 0,
        maxValue = config.maxValue or 100,
        showGrid = config.showGrid ~= false,
        thickness = config.thickness or 2,
        fillTransparency = config.fillTransparency or 0.3,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function chart:_createBackground()
        local bg = Drawing.new("Square")
        bg.Size = self.size
        bg.Position = self.position
        bg.Color = self.backgroundColor
        bg.Filled = true
        bg.Visible = self._visible
        bg.Transparency = 0.8
        table.insert(self._drawings, bg)
    end
    
    function chart:_createGrid()
        local gridCount = 5
        
        for i = 0, gridCount do
            local line = Drawing.new("Line")
            line.From = self.position + Vector2.new(0, (self.size.Y / gridCount) * i)
            line.To = self.position + Vector2.new(self.size.X, (self.size.Y / gridCount) * i)
            line.Color = self.gridColor
            line.Thickness = 1
            line.Visible = self._visible and self.showGrid
            line.Transparency = 0.5
            table.insert(self._drawings, line)
        end
    end
    
    function chart:_normalizeValue(value)
        return (value - self.minValue) / (self.maxValue - self.minValue)
    end
    
    function chart:_valueToY(value)
        local normalized = self:_normalizeValue(value)
        return self.position.Y + self.size.Y - (normalized * self.size.Y)
    end
    
    function chart:addDataPoint(value)
        table.insert(self._data, value)
        if #self._data > self.maxDataPoints then
            table.remove(self._data, 1)
        end
        self:_redraw()
    end
    
    function chart:_redraw()
        -- Remove old drawings (except background and grid)
        for i = #self._drawings, 1, -1 do
            local drawing = self._drawings[i]
            if drawing.ClassName == "Triangle" or (drawing.ClassName == "Line" and drawing.Color == self.lineColor) then
                drawing:Remove()
                table.remove(self._drawings, i)
            end
        end
        
        if #self._data < 2 then return end
        
        local xStep = self.size.X / (self.maxDataPoints - 1)
        
        -- Draw filled area using triangles
        for i = 1, #self._data - 1 do
            local x1 = self.position.X + ((i - 1) * xStep)
            local y1 = self:_valueToY(self._data[i])
            
            local x2 = self.position.X + (i * xStep)
            local y2 = self:_valueToY(self._data[i + 1])
            
            local baseY = self.position.Y + self.size.Y
            
            -- Create two triangles to fill the area
            local tri1 = Drawing.new("Triangle")
            tri1.PointA = Vector2.new(x1, y1)
            tri1.PointB = Vector2.new(x2, y2)
            tri1.PointC = Vector2.new(x1, baseY)
            tri1.Color = self.fillColor
            tri1.Filled = true
            tri1.Visible = self._visible
            tri1.Transparency = self.fillTransparency
            table.insert(self._drawings, tri1)
            
            local tri2 = Drawing.new("Triangle")
            tri2.PointA = Vector2.new(x2, y2)
            tri2.PointB = Vector2.new(x2, baseY)
            tri2.PointC = Vector2.new(x1, baseY)
            tri2.Color = self.fillColor
            tri2.Filled = true
            tri2.Visible = self._visible
            tri2.Transparency = self.fillTransparency
            table.insert(self._drawings, tri2)
        end
        
        -- Draw line on top
        for i = 1, #self._data - 1 do
            local line = Drawing.new("Line")
            
            local x1 = self.position.X + ((i - 1) * xStep)
            local y1 = self:_valueToY(self._data[i])
            
            local x2 = self.position.X + (i * xStep)
            local y2 = self:_valueToY(self._data[i + 1])
            
            line.From = Vector2.new(x1, y1)
            line.To = Vector2.new(x2, y2)
            line.Color = self.lineColor
            line.Thickness = self.thickness
            line.Visible = self._visible
            
            table.insert(self._drawings, line)
        end
    end
    
    function chart:show()
        if not self._visible then
            self:_createBackground()
            if self.showGrid then
                self:_createGrid()
            end
            self._visible = true
            self:_redraw()
        end
        
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = true
        end
    end
    
    function chart:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function chart:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        self._data = {}
    end
    
    function chart:setData(data)
        self._data = data
        self:_redraw()
    end
    
    return chart
end

-- Horizontal Bar Graph
function GraphUtils.createHorizontalBarGraph(config)
    config = config or {}
    
    local graph = {
        position = config.position or Vector2.new(100, 100),
        size = config.size or Vector2.new(300, 200),
        backgroundColor = config.backgroundColor or Color3.fromRGB(20, 20, 20),
        barColor = config.barColor or Color3.fromRGB(0, 150, 255),
        maxBars = config.maxBars or 10,
        maxValue = config.maxValue or 100,
        spacing = config.spacing or 5,
        showLabels = config.showLabels or false,
        
        _data = {},
        _drawings = {},
        _visible = false
    }
    
    function graph:addBar(value, color, label)
        table.insert(self._data, {
            value = value,
            color = color or self.barColor,
            label = label
        })
        if #self._data > self.maxBars then
            table.remove(self._data, 1)
        end
        self:_redraw()
    end
    
    function graph:_redraw()
        -- Clear old drawings
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        -- Draw background
        local bg = Drawing.new("Square")
        bg.Size = self.size
        bg.Position = self.position
        bg.Color = self.backgroundColor
        bg.Filled = true
        bg.Visible = self._visible
        bg.Transparency = 0.8
        table.insert(self._drawings, bg)
        
        if #self._data == 0 then return end
        
        -- Draw bars
        local barHeight = (self.size.Y - (self.spacing * (#self._data + 1))) / #self._data
        
        for i, data in ipairs(self._data) do
            local barWidth = (data.value / self.maxValue) * self.size.X
            local bar = Drawing.new("Square")
            
            bar.Size = Vector2.new(barWidth, barHeight)
            bar.Position = Vector2.new(
                self.position.X,
                self.position.Y + (i - 1) * (barHeight + self.spacing) + self.spacing
            )
            bar.Color = data.color
            bar.Filled = true
            bar.Visible = self._visible
            
            table.insert(self._drawings, bar)
            
            -- Draw label if enabled
            if self.showLabels and data.label then
                local text = Drawing.new("Text")
                text.Text = data.label
                text.Position = Vector2.new(
                    self.position.X + 5,
                    bar.Position.Y + barHeight / 2
                )
                text.Color = Color3.fromRGB(255, 255, 255)
                text.Size = 12
                text.Outline = true
                text.Visible = self._visible
                table.insert(self._drawings, text)
            end
        end
    end
    
    function graph:show()
        self._visible = true
        self:_redraw()
    end
    
    function graph:hide()
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = false
        end
    end
    
    function graph:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        self._data = {}
    end
    
    function graph:setData(data)
        self._data = {}
        for _, item in ipairs(data) do
            if type(item) == "table" then
                table.insert(self._data, item)
            else
                table.insert(self._data, {value = item, color = self.barColor})
            end
        end
        self:_redraw()
    end
    
    return graph
end

return GraphUtils