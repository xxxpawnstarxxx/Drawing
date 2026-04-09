local ShapeUtils = {}

-- Helper function for 3D to 2D projection
local function project3D(point3D, camera)
    camera = camera or {
        position = Vector3.new(0, 0, -500),
        fov = 90,
        screenCenter = Vector2.new(400, 300)
    }
    
    local translated = point3D - camera.position
    local fovFactor = 500 / math.tan(math.rad(camera.fov / 2))
    
    if translated.Z > 0 then
        local scale = fovFactor / translated.Z
        return Vector2.new(
            translated.X * scale + camera.screenCenter.X,
            -translated.Y * scale + camera.screenCenter.Y
        ), scale
    end
    
    return nil, 0
end

-- Circle/Ring renderer
function ShapeUtils.createCircle(config)
    config = config or {}
    
    local circle = {
        position = config.position or Vector2.new(100, 100),
        radius = config.radius or 50,
        color = config.color or Color3.fromRGB(255, 255, 255),
        filled = config.filled ~= false,
        thickness = config.thickness or 2,
        segments = config.segments or 32,
        startAngle = config.startAngle or 0,
        endAngle = config.endAngle or 360,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function circle:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local angleStep = (self.endAngle - self.startAngle) / self.segments
        
        if self.filled then
            for i = 0, self.segments - 1 do
                local angle1 = math.rad(self.startAngle + (i * angleStep))
                local angle2 = math.rad(self.startAngle + ((i + 1) * angleStep))
                
                local p1 = self.position
                local p2 = self.position + Vector2.new(math.cos(angle1) * self.radius, math.sin(angle1) * self.radius)
                local p3 = self.position + Vector2.new(math.cos(angle2) * self.radius, math.sin(angle2) * self.radius)
                
                local triangle = Drawing.new("Triangle")
                triangle.PointA = p1
                triangle.PointB = p2
                triangle.PointC = p3
                triangle.Color = self.color
                triangle.Filled = true
                triangle.Visible = self._visible
                triangle.Transparency = self.transparency
                
                table.insert(self._drawings, triangle)
            end
        else
            for i = 0, self.segments - 1 do
                local angle1 = math.rad(self.startAngle + (i * angleStep))
                local angle2 = math.rad(self.startAngle + ((i + 1) * angleStep))
                
                local p1 = self.position + Vector2.new(math.cos(angle1) * self.radius, math.sin(angle1) * self.radius)
                local p2 = self.position + Vector2.new(math.cos(angle2) * self.radius, math.sin(angle2) * self.radius)
                
                local line = Drawing.new("Line")
                line.From = p1
                line.To = p2
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                
                table.insert(self._drawings, line)
            end
        end
    end
    
    function circle:setRadius(radius)
        self.radius = radius
        self:_redraw()
    end
    
    function circle:setPosition(position)
        self.position = position
        self:_redraw()
    end
    
    function circle:setColor(color)
        self.color = color
        self:_redraw()
    end
    
    function circle:setArc(startAngle, endAngle)
        self.startAngle = startAngle
        self.endAngle = endAngle
        self:_redraw()
    end
    
    function circle:setVisible(visible)
        self._visible = visible
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = visible
        end
    end
    
    function circle:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    circle:_redraw()
    return circle
end

-- Ellipse renderer
function ShapeUtils.createEllipse(config)
    config = config or {}
    
    local ellipse = {
        position = config.position or Vector2.new(100, 100),
        radiusX = config.radiusX or 80,
        radiusY = config.radiusY or 50,
        color = config.color or Color3.fromRGB(255, 255, 255),
        filled = config.filled ~= false,
        thickness = config.thickness or 2,
        segments = config.segments or 32,
        rotation = config.rotation or 0,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function ellipse:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local angleStep = 360 / self.segments
        local rotRad = math.rad(self.rotation)
        
        local function rotatePoint(x, y)
            local cosR = math.cos(rotRad)
            local sinR = math.sin(rotRad)
            return x * cosR - y * sinR, x * sinR + y * cosR
        end
        
        if self.filled then
            for i = 0, self.segments - 1 do
                local angle1 = math.rad(i * angleStep)
                local angle2 = math.rad((i + 1) * angleStep)
                
                local x2 = math.cos(angle1) * self.radiusX
                local y2 = math.sin(angle1) * self.radiusY
                local x3 = math.cos(angle2) * self.radiusX
                local y3 = math.sin(angle2) * self.radiusY
                
                local rx2, ry2 = rotatePoint(x2, y2)
                local rx3, ry3 = rotatePoint(x3, y3)
                
                local p1 = self.position
                local p2 = self.position + Vector2.new(rx2, ry2)
                local p3 = self.position + Vector2.new(rx3, ry3)
                
                local triangle = Drawing.new("Triangle")
                triangle.PointA = p1
                triangle.PointB = p2
                triangle.PointC = p3
                triangle.Color = self.color
                triangle.Filled = true
                triangle.Visible = self._visible
                triangle.Transparency = self.transparency
                
                table.insert(self._drawings, triangle)
            end
        else
            for i = 0, self.segments - 1 do
                local angle1 = math.rad(i * angleStep)
                local angle2 = math.rad((i + 1) * angleStep)
                
                local x1 = math.cos(angle1) * self.radiusX
                local y1 = math.sin(angle1) * self.radiusY
                local x2 = math.cos(angle2) * self.radiusX
                local y2 = math.sin(angle2) * self.radiusY
                
                local rx1, ry1 = rotatePoint(x1, y1)
                local rx2, ry2 = rotatePoint(x2, y2)
                
                local p1 = self.position + Vector2.new(rx1, ry1)
                local p2 = self.position + Vector2.new(rx2, ry2)
                
                local line = Drawing.new("Line")
                line.From = p1
                line.To = p2
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                
                table.insert(self._drawings, line)
            end
        end
    end
    
    function ellipse:setRadii(radiusX, radiusY)
        self.radiusX = radiusX
        self.radiusY = radiusY
        self:_redraw()
    end
    
    function ellipse:setRotation(rotation)
        self.rotation = rotation
        self:_redraw()
    end
    
    function ellipse:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    ellipse:_redraw()
    return ellipse
end

-- Polygon renderer
function ShapeUtils.createPolygon(config)
    config = config or {}
    
    local polygon = {
        points = config.points or {},
        color = config.color or Color3.fromRGB(255, 255, 255),
        filled = config.filled ~= false,
        thickness = config.thickness or 2,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function polygon:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        if #self.points < 3 then return end
        
        if self.filled then
            for i = 2, #self.points - 1 do
                local triangle = Drawing.new("Triangle")
                triangle.PointA = self.points[1]
                triangle.PointB = self.points[i]
                triangle.PointC = self.points[i + 1]
                triangle.Color = self.color
                triangle.Filled = true
                triangle.Visible = self._visible
                triangle.Transparency = self.transparency
                
                table.insert(self._drawings, triangle)
            end
        else
            for i = 1, #self.points do
                local nextI = (i % #self.points) + 1
                
                local line = Drawing.new("Line")
                line.From = self.points[i]
                line.To = self.points[nextI]
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                
                table.insert(self._drawings, line)
            end
        end
    end
    
    function polygon:setPoints(points)
        self.points = points
        self:_redraw()
    end
    
    function polygon:setVisible(visible)
        self._visible = visible
        for _, drawing in ipairs(self._drawings) do
            drawing.Visible = visible
        end
    end
    
    function polygon:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    polygon:_redraw()
    return polygon
end

-- Regular Polygon (e.g., pentagon, hexagon, octagon)
function ShapeUtils.createRegularPolygon(config)
    config = config or {}
    
    local sides = config.sides or 6
    local position = config.position or Vector2.new(100, 100)
    local radius = config.radius or 50
    local rotation = config.rotation or 0
    
    local points = {}
    local angleStep = 360 / sides
    
    for i = 0, sides - 1 do
        local angle = math.rad(i * angleStep + rotation)
        local x = position.X + math.cos(angle) * radius
        local y = position.Y + math.sin(angle) * radius
        table.insert(points, Vector2.new(x, y))
    end
    
    config.points = points
    local poly = ShapeUtils.createPolygon(config)
    
    poly.sides = sides
    poly.centerPosition = position
    poly.radius = radius
    poly.rotation = rotation
    
    function poly:setRadius(newRadius)
        self.radius = newRadius
        self:updatePoints()
    end
    
    function poly:setRotation(newRotation)
        self.rotation = newRotation
        self:updatePoints()
    end
    
    function poly:updatePoints()
        local newPoints = {}
        local angleStep = 360 / self.sides
        
        for i = 0, self.sides - 1 do
            local angle = math.rad(i * angleStep + self.rotation)
            local x = self.centerPosition.X + math.cos(angle) * self.radius
            local y = self.centerPosition.Y + math.sin(angle) * self.radius
            table.insert(newPoints, Vector2.new(x, y))
        end
        
        self:setPoints(newPoints)
    end
    
    return poly
end

-- Star renderer
function ShapeUtils.createStar(config)
    config = config or {}
    
    local star = {
        position = config.position or Vector2.new(100, 100),
        outerRadius = config.outerRadius or 50,
        innerRadius = config.innerRadius or 25,
        points = config.points or 5,
        rotation = config.rotation or 0,
        color = config.color or Color3.fromRGB(255, 255, 0),
        filled = config.filled ~= false,
        thickness = config.thickness or 2,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function star:_getPoints()
        local vertices = {}
        local angleStep = 360 / (self.points * 2)
        
        for i = 0, self.points * 2 - 1 do
            local angle = math.rad(i * angleStep + self.rotation - 90)
            local radius = (i % 2 == 0) and self.outerRadius or self.innerRadius
            
            local x = self.position.X + math.cos(angle) * radius
            local y = self.position.Y + math.sin(angle) * radius
            table.insert(vertices, Vector2.new(x, y))
        end
        
        return vertices
    end
    
    function star:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local vertices = self:_getPoints()
        
        if self.filled then
            for i = 2, #vertices - 1 do
                local triangle = Drawing.new("Triangle")
                triangle.PointA = self.position
                triangle.PointB = vertices[i]
                triangle.PointC = vertices[i + 1]
                triangle.Color = self.color
                triangle.Filled = true
                triangle.Visible = self._visible
                triangle.Transparency = self.transparency
                
                table.insert(self._drawings, triangle)
            end
        else
            for i = 1, #vertices do
                local nextI = (i % #vertices) + 1
                
                local line = Drawing.new("Line")
                line.From = vertices[i]
                line.To = vertices[nextI]
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                
                table.insert(self._drawings, line)
            end
        end
    end
    
    function star:setRadii(outer, inner)
        self.outerRadius = outer
        self.innerRadius = inner
        self:_redraw()
    end
    
    function star:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    star:_redraw()
    return star
end

-- Rounded Rectangle
function ShapeUtils.createRoundedRect(config)
    config = config or {}
    
    local rect = {
        position = config.position or Vector2.new(100, 100),
        size = config.size or Vector2.new(200, 100),
        color = config.color or Color3.fromRGB(255, 255, 255),
        cornerRadius = config.cornerRadius or 10,
        filled = config.filled ~= false,
        thickness = config.thickness or 2,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function rect:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local r = math.min(self.cornerRadius, self.size.X / 2, self.size.Y / 2)
        
        if self.filled then
            -- Main body
            local body = Drawing.new("Square")
            body.Size = Vector2.new(self.size.X - 2 * r, self.size.Y)
            body.Position = self.position + Vector2.new(r, 0)
            body.Color = self.color
            body.Filled = true
            body.Visible = self._visible
            body.Transparency = self.transparency
            table.insert(self._drawings, body)
            
            local leftRect = Drawing.new("Square")
            leftRect.Size = Vector2.new(r, self.size.Y - 2 * r)
            leftRect.Position = self.position + Vector2.new(0, r)
            leftRect.Color = self.color
            leftRect.Filled = true
            leftRect.Visible = self._visible
            leftRect.Transparency = self.transparency
            table.insert(self._drawings, leftRect)
            
            local rightRect = Drawing.new("Square")
            rightRect.Size = Vector2.new(r, self.size.Y - 2 * r)
            rightRect.Position = self.position + Vector2.new(self.size.X - r, r)
            rightRect.Color = self.color
            rightRect.Filled = true
            rightRect.Visible = self._visible
            rightRect.Transparency = self.transparency
            table.insert(self._drawings, rightRect)
            
            -- Corners
            local corners = {
                {pos = self.position + Vector2.new(r, r), start = 180, end_ = 270},
                {pos = self.position + Vector2.new(self.size.X - r, r), start = 270, end_ = 360},
                {pos = self.position + Vector2.new(self.size.X - r, self.size.Y - r), start = 0, end_ = 90},
                {pos = self.position + Vector2.new(r, self.size.Y - r), start = 90, end_ = 180}
            }
            
            for _, corner in ipairs(corners) do
                local segments = 8
                local angleStep = (corner.end_ - corner.start) / segments
                
                for i = 0, segments - 1 do
                    local angle1 = math.rad(corner.start + (i * angleStep))
                    local angle2 = math.rad(corner.start + ((i + 1) * angleStep))
                    
                    local p1 = corner.pos
                    local p2 = corner.pos + Vector2.new(math.cos(angle1) * r, math.sin(angle1) * r)
                    local p3 = corner.pos + Vector2.new(math.cos(angle2) * r, math.sin(angle2) * r)
                    
                    local triangle = Drawing.new("Triangle")
                    triangle.PointA = p1
                    triangle.PointB = p2
                    triangle.PointC = p3
                    triangle.Color = self.color
                    triangle.Filled = true
                    triangle.Visible = self._visible
                    triangle.Transparency = self.transparency
                    
                    table.insert(self._drawings, triangle)
                end
            end
        else
            -- Draw outline
            -- Top and bottom lines
            local segments = 8
            
            -- Corners outlines
            local corners = {
                {pos = self.position + Vector2.new(r, r), start = 180, end_ = 270},
                {pos = self.position + Vector2.new(self.size.X - r, r), start = 270, end_ = 360},
                {pos = self.position + Vector2.new(self.size.X - r, self.size.Y - r), start = 0, end_ = 90},
                {pos = self.position + Vector2.new(r, self.size.Y - r), start = 90, end_ = 180}
            }
            
            for _, corner in ipairs(corners) do
                local angleStep = (corner.end_ - corner.start) / segments
                
                for i = 0, segments - 1 do
                    local angle1 = math.rad(corner.start + (i * angleStep))
                    local angle2 = math.rad(corner.start + ((i + 1) * angleStep))
                    
                    local p1 = corner.pos + Vector2.new(math.cos(angle1) * r, math.sin(angle1) * r)
                    local p2 = corner.pos + Vector2.new(math.cos(angle2) * r, math.sin(angle2) * r)
                    
                    local line = Drawing.new("Line")
                    line.From = p1
                    line.To = p2
                    line.Color = self.color
                    line.Thickness = self.thickness
                    line.Visible = self._visible
                    line.Transparency = self.transparency
                    
                    table.insert(self._drawings, line)
                end
            end
            
            -- Straight edges
            local edges = {
                {from = self.position + Vector2.new(r, 0), to = self.position + Vector2.new(self.size.X - r, 0)},
                {from = self.position + Vector2.new(self.size.X, r), to = self.position + Vector2.new(self.size.X, self.size.Y - r)},
                {from = self.position + Vector2.new(self.size.X - r, self.size.Y), to = self.position + Vector2.new(r, self.size.Y)},
                {from = self.position + Vector2.new(0, self.size.Y - r), to = self.position + Vector2.new(0, r)}
            }
            
            for _, edge in ipairs(edges) do
                local line = Drawing.new("Line")
                line.From = edge.from
                line.To = edge.to
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                
                table.insert(self._drawings, line)
            end
        end
    end
    
    function rect:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    rect:_redraw()
    return rect
end

-- Arrow renderer
function ShapeUtils.createArrow(config)
    config = config or {}
    
    local arrow = {
        from = config.from or Vector2.new(100, 100),
        to = config.to or Vector2.new(200, 100),
        color = config.color or Color3.fromRGB(255, 255, 255),
        thickness = config.thickness or 2,
        headSize = config.headSize or 15,
        headAngle = config.headAngle or 30,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function arrow:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        -- Main line
        local line = Drawing.new("Line")
        line.From = self.from
        line.To = self.to
        line.Color = self.color
        line.Thickness = self.thickness
        line.Visible = self._visible
        line.Transparency = self.transparency
        table.insert(self._drawings, line)
        
        -- Arrow head
        local direction = (self.to - self.from).Unit
        local angle = math.atan2(direction.Y, direction.X)
        
        local headAngleRad = math.rad(self.headAngle)
        
        local left = Vector2.new(
            self.to.X - math.cos(angle - headAngleRad) * self.headSize,
            self.to.Y - math.sin(angle - headAngleRad) * self.headSize
        )
        
        local right = Vector2.new(
            self.to.X - math.cos(angle + headAngleRad) * self.headSize,
            self.to.Y - math.sin(angle + headAngleRad) * self.headSize
        )
        
        local leftLine = Drawing.new("Line")
        leftLine.From = self.to
        leftLine.To = left
        leftLine.Color = self.color
        leftLine.Thickness = self.thickness
        leftLine.Visible = self._visible
        leftLine.Transparency = self.transparency
        table.insert(self._drawings, leftLine)
        
        local rightLine = Drawing.new("Line")
        rightLine.From = self.to
        rightLine.To = right
        rightLine.Color = self.color
        rightLine.Thickness = self.thickness
        rightLine.Visible = self._visible
        rightLine.Transparency = self.transparency
        table.insert(self._drawings, rightLine)
    end
    
    function arrow:setPoints(from, to)
        self.from = from
        self.to = to
        self:_redraw()
    end
    
    function arrow:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    arrow:_redraw()
    return arrow
end

-- Grid renderer
function ShapeUtils.createGrid(config)
    config = config or {}
    
    local grid = {
        position = config.position or Vector2.new(0, 0),
        size = config.size or Vector2.new(800, 600),
        cellSize = config.cellSize or 50,
        color = config.color or Color3.fromRGB(100, 100, 100),
        thickness = config.thickness or 1,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function grid:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        -- Vertical lines
        for x = 0, self.size.X, self.cellSize do
            local line = Drawing.new("Line")
            line.From = self.position + Vector2.new(x, 0)
            line.To = self.position + Vector2.new(x, self.size.Y)
            line.Color = self.color
            line.Thickness = self.thickness
            line.Visible = self._visible
            line.Transparency = self.transparency
            table.insert(self._drawings, line)
        end
        
        -- Horizontal lines
        for y = 0, self.size.Y, self.cellSize do
            local line = Drawing.new("Line")
            line.From = self.position + Vector2.new(0, y)
            line.To = self.position + Vector2.new(self.size.X, y)
            line.Color = self.color
            line.Thickness = self.thickness
            line.Visible = self._visible
            line.Transparency = self.transparency
            table.insert(self._drawings, line)
        end
    end
    
    function grid:setCellSize(size)
        self.cellSize = size
        self:_redraw()
    end
    
    function grid:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    grid:_redraw()
    return grid
end

--[[ 3D SHAPES ]]--

-- 3D Cube
function ShapeUtils.createCube(config)
    config = config or {}
    
    local cube = {
        position = config.position or Vector3.new(0, 0, 0),
        size = config.size or 100,
        rotation = config.rotation or Vector3.new(0, 0, 0),
        color = config.color or Color3.fromRGB(255, 255, 255),
        thickness = config.thickness or 2,
        camera = config.camera,
        wireframe = config.wireframe ~= false,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function cube:_getVertices()
        local s = self.size / 2
        local vertices = {
            Vector3.new(-s, -s, -s),
            Vector3.new(s, -s, -s),
            Vector3.new(s, s, -s),
            Vector3.new(-s, s, -s),
            Vector3.new(-s, -s, s),
            Vector3.new(s, -s, s),
            Vector3.new(s, s, s),
            Vector3.new(-s, s, s)
        }
        
        -- Apply rotation
        local rx, ry, rz = math.rad(self.rotation.X), math.rad(self.rotation.Y), math.rad(self.rotation.Z)
        
        for i, v in ipairs(vertices) do
            -- Rotate around X
            local y = v.Y * math.cos(rx) - v.Z * math.sin(rx)
            local z = v.Y * math.sin(rx) + v.Z * math.cos(rx)
            v = Vector3.new(v.X, y, z)
            
            -- Rotate around Y
            local x = v.X * math.cos(ry) + v.Z * math.sin(ry)
            z = -v.X * math.sin(ry) + v.Z * math.cos(ry)
            v = Vector3.new(x, v.Y, z)
            
            -- Rotate around Z
            x = v.X * math.cos(rz) - v.Y * math.sin(rz)
            y = v.X * math.sin(rz) + v.Y * math.cos(rz)
            v = Vector3.new(x, y, v.Z)
            
            vertices[i] = v + self.position
        end
        
        return vertices
    end
    
    function cube:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local vertices = self:_getVertices()
        local projected = {}
        
        for i, v in ipairs(vertices) do
            local p2d = project3D(v, self.camera)
            if p2d then
                projected[i] = p2d
            else
                return -- Don't draw if behind camera
            end
        end
        
        -- Define edges (pairs of vertex indices)
        local edges = {
            {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Back face
            {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- Front face
            {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- Connecting edges
        }
        
        if self.wireframe then
            for _, edge in ipairs(edges) do
                local line = Drawing.new("Line")
                line.From = projected[edge[1]]
                line.To = projected[edge[2]]
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                table.insert(self._drawings, line)
            end
        else
            -- Draw filled faces
            local faces = {
                {1, 2, 3, 4}, -- Back
                {5, 6, 7, 8}, -- Front
                {1, 2, 6, 5}, -- Bottom
                {4, 3, 7, 8}, -- Top
                {1, 4, 8, 5}, -- Left
                {2, 3, 7, 6}  -- Right
            }
            
            for _, face in ipairs(faces) do
                -- Draw as two triangles
                local tri1 = Drawing.new("Triangle")
                tri1.PointA = projected[face[1]]
                tri1.PointB = projected[face[2]]
                tri1.PointC = projected[face[3]]
                tri1.Color = self.color
                tri1.Filled = true
                tri1.Visible = self._visible
                tri1.Transparency = self.transparency
                table.insert(self._drawings, tri1)
                
                local tri2 = Drawing.new("Triangle")
                tri2.PointA = projected[face[1]]
                tri2.PointB = projected[face[3]]
                tri2.PointC = projected[face[4]]
                tri2.Color = self.color
                tri2.Filled = true
                tri2.Visible = self._visible
                tri2.Transparency = self.transparency
                table.insert(self._drawings, tri2)
            end
        end
    end
    
    function cube:setRotation(rotation)
        self.rotation = rotation
        self:_redraw()
    end
    
    function cube:rotate(deltaRotation)
        self.rotation = self.rotation + deltaRotation
        self:_redraw()
    end
    
    function cube:setPosition(position)
        self.position = position
        self:_redraw()
    end
    
    function cube:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    cube:_redraw()
    return cube
end

-- 3D Sphere
function ShapeUtils.createSphere(config)
    config = config or {}
    
    local sphere = {
        position = config.position or Vector3.new(0, 0, 0),
        radius = config.radius or 50,
        color = config.color or Color3.fromRGB(255, 255, 255),
        thickness = config.thickness or 2,
        segments = config.segments or 16,
        rings = config.rings or 12,
        camera = config.camera,
        wireframe = config.wireframe ~= false,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function sphere:_getVertices()
        local vertices = {}
        
        for ring = 0, self.rings do
            local phi = (ring / self.rings) * math.pi
            
            for seg = 0, self.segments do
                local theta = (seg / self.segments) * 2 * math.pi
                
                local x = math.sin(phi) * math.cos(theta) * self.radius
                local y = math.cos(phi) * self.radius
                local z = math.sin(phi) * math.sin(theta) * self.radius
                
                table.insert(vertices, self.position + Vector3.new(x, y, z))
            end
        end
        
        return vertices
    end
    
    function sphere:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local vertices = self:_getVertices()
        local projected = {}
        
        for i, v in ipairs(vertices) do
            local p2d = project3D(v, self.camera)
            if p2d then
                projected[i] = p2d
            end
        end
        
        if self.wireframe then
            -- Draw latitude lines
            for ring = 0, self.rings do
                for seg = 0, self.segments - 1 do
                    local idx1 = ring * (self.segments + 1) + seg + 1
                    local idx2 = ring * (self.segments + 1) + seg + 2
                    
                    if projected[idx1] and projected[idx2] then
                        local line = Drawing.new("Line")
                        line.From = projected[idx1]
                        line.To = projected[idx2]
                        line.Color = self.color
                        line.Thickness = self.thickness
                        line.Visible = self._visible
                        line.Transparency = self.transparency
                        table.insert(self._drawings, line)
                    end
                end
            end
            
            -- Draw longitude lines
            for seg = 0, self.segments do
                for ring = 0, self.rings - 1 do
                    local idx1 = ring * (self.segments + 1) + seg + 1
                    local idx2 = (ring + 1) * (self.segments + 1) + seg + 1
                    
                    if projected[idx1] and projected[idx2] then
                        local line = Drawing.new("Line")
                        line.From = projected[idx1]
                        line.To = projected[idx2]
                        line.Color = self.color
                        line.Thickness = self.thickness
                        line.Visible = self._visible
                        line.Transparency = self.transparency
                        table.insert(self._drawings, line)
                    end
                end
            end
        end
    end
    
    function sphere:setRadius(radius)
        self.radius = radius
        self:_redraw()
    end
    
    function sphere:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    sphere:_redraw()
    return sphere
end

-- 3D Pyramid
function ShapeUtils.createPyramid(config)
    config = config or {}
    
    local pyramid = {
        position = config.position or Vector3.new(0, 0, 0),
        baseSize = config.baseSize or 100,
        height = config.height or 100,
        rotation = config.rotation or Vector3.new(0, 0, 0),
        color = config.color or Color3.fromRGB(255, 255, 255),
        thickness = config.thickness or 2,
        camera = config.camera,
        wireframe = config.wireframe ~= false,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function pyramid:_getVertices()
        local s = self.baseSize / 2
        local h = self.height / 2
        
        local vertices = {
            Vector3.new(-s, -h, -s), -- Base corners
            Vector3.new(s, -h, -s),
            Vector3.new(s, -h, s),
            Vector3.new(-s, -h, s),
            Vector3.new(0, h, 0)      -- Apex
        }
        
        -- Apply rotation (same as cube)
        local rx, ry, rz = math.rad(self.rotation.X), math.rad(self.rotation.Y), math.rad(self.rotation.Z)
        
        for i, v in ipairs(vertices) do
            -- Rotate around X
            local y = v.Y * math.cos(rx) - v.Z * math.sin(rx)
            local z = v.Y * math.sin(rx) + v.Z * math.cos(rx)
            v = Vector3.new(v.X, y, z)
            
            -- Rotate around Y
            local x = v.X * math.cos(ry) + v.Z * math.sin(ry)
            z = -v.X * math.sin(ry) + v.Z * math.cos(ry)
            v = Vector3.new(x, v.Y, z)
            
            -- Rotate around Z
            x = v.X * math.cos(rz) - v.Y * math.sin(rz)
            y = v.X * math.sin(rz) + v.Y * math.cos(rz)
            v = Vector3.new(x, y, v.Z)
            
            vertices[i] = v + self.position
        end
        
        return vertices
    end
    
    function pyramid:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local vertices = self:_getVertices()
        local projected = {}
        
        for i, v in ipairs(vertices) do
            local p2d = project3D(v, self.camera)
            if p2d then
                projected[i] = p2d
            else
                return
            end
        end
        
        local edges = {
            {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Base
            {1, 5}, {2, 5}, {3, 5}, {4, 5}  -- Edges to apex
        }
        
        for _, edge in ipairs(edges) do
            local line = Drawing.new("Line")
            line.From = projected[edge[1]]
            line.To = projected[edge[2]]
            line.Color = self.color
            line.Thickness = self.thickness
            line.Visible = self._visible
            line.Transparency = self.transparency
            table.insert(self._drawings, line)
        end
    end
    
    function pyramid:setRotation(rotation)
        self.rotation = rotation
        self:_redraw()
    end
    
    function pyramid:rotate(deltaRotation)
        self.rotation = self.rotation + deltaRotation
        self:_redraw()
    end
    
    function pyramid:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    pyramid:_redraw()
    return pyramid
end

-- 3D Cylinder
function ShapeUtils.createCylinder(config)
    config = config or {}
    
    local cylinder = {
        position = config.position or Vector3.new(0, 0, 0),
        radius = config.radius or 50,
        height = config.height or 100,
        rotation = config.rotation or Vector3.new(0, 0, 0),
        segments = config.segments or 16,
        color = config.color or Color3.fromRGB(255, 255, 255),
        thickness = config.thickness or 2,
        camera = config.camera,
        wireframe = config.wireframe ~= false,
        transparency = config.transparency or 1,
        
        _drawings = {},
        _visible = true
    }
    
    function cylinder:_getVertices()
        local vertices = {}
        local h = self.height / 2
        
        -- Top circle
        for i = 0, self.segments do
            local angle = (i / self.segments) * 2 * math.pi
            local x = math.cos(angle) * self.radius
            local z = math.sin(angle) * self.radius
            table.insert(vertices, Vector3.new(x, h, z))
        end
        
        -- Bottom circle
        for i = 0, self.segments do
            local angle = (i / self.segments) * 2 * math.pi
            local x = math.cos(angle) * self.radius
            local z = math.sin(angle) * self.radius
            table.insert(vertices, Vector3.new(x, -h, z))
        end
        
        -- Apply rotation
        local rx, ry, rz = math.rad(self.rotation.X), math.rad(self.rotation.Y), math.rad(self.rotation.Z)
        
        for i, v in ipairs(vertices) do
            local y = v.Y * math.cos(rx) - v.Z * math.sin(rx)
            local z = v.Y * math.sin(rx) + v.Z * math.cos(rx)
            v = Vector3.new(v.X, y, z)
            
            local x = v.X * math.cos(ry) + v.Z * math.sin(ry)
            z = -v.X * math.sin(ry) + v.Z * math.cos(ry)
            v = Vector3.new(x, v.Y, z)
            
            x = v.X * math.cos(rz) - v.Y * math.sin(rz)
            y = v.X * math.sin(rz) + v.Y * math.cos(rz)
            v = Vector3.new(x, y, v.Z)
            
            vertices[i] = v + self.position
        end
        
        return vertices
    end
    
    function cylinder:_redraw()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
        
        local vertices = self:_getVertices()
        local projected = {}
        
        for i, v in ipairs(vertices) do
            local p2d = project3D(v, self.camera)
            if p2d then
                projected[i] = p2d
            end
        end
        
        local segCount = self.segments + 1
        
        -- Top circle
        for i = 1, self.segments do
            if projected[i] and projected[i + 1] then
                local line = Drawing.new("Line")
                line.From = projected[i]
                line.To = projected[i + 1]
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                table.insert(self._drawings, line)
            end
        end
        
        -- Bottom circle
        for i = segCount + 1, segCount + self.segments do
            if projected[i] and projected[i + 1] then
                local line = Drawing.new("Line")
                line.From = projected[i]
                line.To = projected[i + 1]
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                table.insert(self._drawings, line)
            end
        end
        
        -- Vertical lines
        for i = 1, segCount do
            if projected[i] and projected[i + segCount] then
                local line = Drawing.new("Line")
                line.From = projected[i]
                line.To = projected[i + segCount]
                line.Color = self.color
                line.Thickness = self.thickness
                line.Visible = self._visible
                line.Transparency = self.transparency
                table.insert(self._drawings, line)
            end
        end
    end
    
    function cylinder:setRotation(rotation)
        self.rotation = rotation
        self:_redraw()
    end
    
    function cylinder:rotate(deltaRotation)
        self.rotation = self.rotation + deltaRotation
        self:_redraw()
    end
    
    function cylinder:destroy()
        for _, drawing in ipairs(self._drawings) do
            drawing:Remove()
        end
        self._drawings = {}
    end
    
    cylinder:_redraw()
    return cylinder
end

return ShapeUtils