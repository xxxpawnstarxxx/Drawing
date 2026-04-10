-- ============================================================================
-- RAKNET SPY - ENHANCED UI VERSION v5.4
-- ============================================================================

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================
local CONFIG = {
    MAX_PACKETS = 10000,
    MOCK_PACKET_INTERVAL = 0.08,
    UI_UPDATE_INTERVAL = 0.5,
    MAX_VISIBLE_PACKETS = 500,
    VERSION = "5.4"
}

local PACKET_NAMES = {
    [0x00] = "CONNECTED_PING",
    [0x03] = "CONNECTED_PONG",
    [0x09] = "CONNECTION_REQUEST",
    [0x10] = "CONNECTION_REQUEST_ACCEPTED",
    [0x13] = "NEW_INCOMING_CONNECTION",
    [0x15] = "DISCONNECTION_NOTIFICATION",
    [0x83] = "DATA_REPLICATION_ACK",
    [0x84] = "ENTITY_UPDATE",
    [0x85] = "WORLD_SYNC",
    [0x88] = "CHAT_MESSAGE",
    [0x8A] = "POSITION_UPDATE"
}

local DIRECTION = {
    SEND = "SND",
    RECEIVE = "RCV",
    INJECT = "INJ"
}

local COLORS = {
    Primary = Color3.fromRGB(45, 45, 50),
    Background = Color3.fromRGB(20, 20, 25),
    Accent = Color3.fromRGB(35, 35, 40),
    Text = Color3.fromRGB(220, 220, 220),
    TextDark = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(46, 204, 113),
    Error = Color3.fromRGB(231, 76, 60),
    Send = Color3.fromRGB(52, 152, 219),
    Receive = Color3.fromRGB(46, 204, 113),
    Inject = Color3.fromRGB(241, 196, 15),
    RowEven = Color3.fromRGB(30, 30, 35),
    RowOdd = Color3.fromRGB(25, 25, 30),
    Selected = Color3.fromRGB(50, 50, 60),
    Border = Color3.fromRGB(60, 60, 70)
}

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================
local RakNetSpy = {
    running = false,
    paused = false,
    snd_enabled = true,
    drop_rcv = false,
    dir_filter = 0,
    id_filter = nil,
    text_filter = "",
    
    stats = {
        sent = 0,
        received = 0,
        dropped = 0,
        modified = 0,
        blacklisted = 0,
        injected = 0,
        start_time = 0
    },
    
    packets = {},
    max_packets = CONFIG.MAX_PACKETS,
    selected_packet = nil,
    blacklist = {},
    auto_respond = {},
    last_ui_update = 0,
    last_packet_count = 0,
    needs_full_refresh = false,
    
    ui = {
        elements = {},
        current_tab = "Main",
        packet_rows = {},
        packet_row_map = {},
        details_text = nil,
        stats_label = nil,
        scroll_frame = nil,
        context_menu = nil
    }
}

-- ============================================================================
-- PACKET CLASS
-- ============================================================================
local Packet = {}
Packet.__index = Packet

function Packet.new(id, data, direction, timestamp)
    local self = setmetatable({}, Packet)
    self.id = id
    self.data = data
    self.direction = direction
    self.timestamp = timestamp or tick()
    self.size = #data
    self.modified = false
    self.number = #RakNetSpy.packets + 1
    self.tags = {}
    return self
end

function Packet:getName()
    return PACKET_NAMES[self.id] or string.format("UNKNOWN_0x%02X", self.id)
end

function Packet:getHexPreview(max_bytes)
    max_bytes = max_bytes or 12
    local preview = {}
    local limit = math.min(#self.data, max_bytes)
    
    for i = 1, limit do
        table.insert(preview, string.format("%02X", string.byte(self.data, i)))
    end
    
    if #self.data > max_bytes then
        table.insert(preview, "...")
    end
    
    return table.concat(preview, " ")
end

function Packet:getFullHex()
    local hex = {}
    for i = 1, #self.data do
        table.insert(hex, string.format("%02X", string.byte(self.data, i)))
    end
    return table.concat(hex, " ")
end

function Packet:getFormatted()
    local chunks = {}
    for i = 1, #self.data, 16 do
        local chunk = {}
        local ascii = {}
        for j = i, math.min(i + 15, #self.data) do
            local byte = string.byte(self.data, j)
            table.insert(chunk, string.format("%02X", byte))
            table.insert(ascii, (byte >= 32 and byte <= 126) and string.char(byte) or ".")
        end
        table.insert(chunks, string.format("%-47s %s", table.concat(chunk, " "), table.concat(ascii)))
    end
    return table.concat(chunks, "\n")
end

function Packet:addTag(tag)
    self.tags[tag] = true
end

function Packet:hasTag(tag)
    return self.tags[tag] == true
end

function Packet:toJSON()
    return string.format(
        '{"id":%d,"name":"%s","direction":"%s","size":%d,"timestamp":%.3f,"hex":"%s"}',
        self.id,
        self:getName(),
        self.direction,
        self.size,
        self.timestamp,
        self:getFullHex()
    )
end

function Packet:toCSV()
    return string.format(
        '%d,0x%02X,%s,%s,%d,%.3f,"%s"',
        self.number,
        self.id,
        self:getName(),
        self.direction,
        self.size,
        self.timestamp,
        self:getFullHex()
    )
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
local function parseHexString(hex_str)
    local bytes = {}
    for byte_str in hex_str:gmatch("%x%x") do
        table.insert(bytes, tonumber(byte_str, 16))
    end
    return #bytes > 0 and string.char(table.unpack(bytes)) or nil
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- ============================================================================
-- EXPORT FUNCTIONS
-- ============================================================================
local function exportToJSON(packets)
    local json_packets = {}
    for _, packet in ipairs(packets) do
        table.insert(json_packets, packet:toJSON())
    end
    return "[\n  " .. table.concat(json_packets, ",\n  ") .. "\n]"
end

local function exportToCSV(packets)
    local csv = {"#,ID,Name,Direction,Size,Timestamp,HexData"}
    for _, packet in ipairs(packets) do
        table.insert(csv, packet:toCSV())
    end
    return table.concat(csv, "\n")
end

local function exportToText(packets)
    local lines = {
        "═══════════════════════════════════════════════════════════",
        "RAKNET SPY - PACKET EXPORT",
        string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")),
        string.format("Total Packets: %d", #packets),
        "═══════════════════════════════════════════════════════════",
        ""
    }
    
    for _, packet in ipairs(packets) do
        table.insert(lines, string.format("───── PACKET #%d ─────", packet.number))
        table.insert(lines, string.format("ID:        0x%02X (%d)", packet.id, packet.id))
        table.insert(lines, string.format("Name:      %s", packet:getName()))
        table.insert(lines, string.format("Direction: %s", packet.direction))
        table.insert(lines, string.format("Size:      %d bytes", packet.size))
        table.insert(lines, string.format("Timestamp: %.3f", packet.timestamp))
        table.insert(lines, "")
        table.insert(lines, packet:getFormatted())
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- PACKET MANAGEMENT
-- ============================================================================
local function addPacket(packet)
    table.insert(RakNetSpy.packets, packet)
    
    if #RakNetSpy.packets > RakNetSpy.max_packets then
        table.remove(RakNetSpy.packets, 1)
        for i, p in ipairs(RakNetSpy.packets) do
            p.number = i
        end
        RakNetSpy.needs_full_refresh = true
    end
end

local function clearPackets()
    RakNetSpy.packets = {}
    RakNetSpy.selected_packet = nil
    RakNetSpy.last_packet_count = 0
    RakNetSpy.needs_full_refresh = true
    RakNetSpy.stats = {
        sent = 0,
        received = 0,
        dropped = 0,
        modified = 0,
        blacklisted = 0,
        injected = 0,
        start_time = tick()
    }
end

local function filterPackets()
    local filtered = {}
    
    for _, packet in ipairs(RakNetSpy.packets) do
        local pass_dir = true
        local pass_id = true
        local pass_text = true
        
        if RakNetSpy.dir_filter == 1 then
            pass_dir = packet.direction == DIRECTION.SEND or packet.direction == DIRECTION.INJECT
        elseif RakNetSpy.dir_filter == 2 then
            pass_dir = packet.direction == DIRECTION.RECEIVE
        end
        
        if RakNetSpy.id_filter then
            pass_id = packet.id == RakNetSpy.id_filter
        end
        
        if RakNetSpy.text_filter ~= "" then
            local search = RakNetSpy.text_filter:lower()
            pass_text = packet:getName():lower():find(search) or 
                       string.format("0x%02x", packet.id):find(search) or
                       packet:getFullHex():lower():find(search)
        end
        
        if pass_dir and pass_id and pass_text then
            table.insert(filtered, packet)
        end
    end
    
    return filtered
end

-- ============================================================================
-- PACKET INTERCEPTION
-- ============================================================================
local function interceptOutgoing(packet_id, data)
    if not RakNetSpy.running or RakNetSpy.paused then return data end
    
    if RakNetSpy.blacklist[packet_id] then
        RakNetSpy.stats.blacklisted = RakNetSpy.stats.blacklisted + 1
        return nil
    end
    
    if not RakNetSpy.snd_enabled then 
        RakNetSpy.stats.dropped = RakNetSpy.stats.dropped + 1
        return nil 
    end
    
    local packet = Packet.new(packet_id, data, DIRECTION.SEND)
    addPacket(packet)
    RakNetSpy.stats.sent = RakNetSpy.stats.sent + 1
    
    return data
end

local function interceptIncoming(packet_id, data)
    if not RakNetSpy.running or RakNetSpy.paused then return data end
    
    if RakNetSpy.blacklist[packet_id] then
        RakNetSpy.stats.blacklisted = RakNetSpy.stats.blacklisted + 1
        return nil
    end
    
    if RakNetSpy.drop_rcv then
        RakNetSpy.stats.dropped = RakNetSpy.stats.dropped + 1
        return nil
    end
    
    local packet = Packet.new(packet_id, data, DIRECTION.RECEIVE)
    addPacket(packet)
    RakNetSpy.stats.received = RakNetSpy.stats.received + 1
    
    if RakNetSpy.auto_respond[packet_id] then
        task.defer(function()
            local response = RakNetSpy.auto_respond[packet_id]
            if type(response) == "function" then
                response = response(packet)
            end
            if response then
                injectPacket(packet_id, response)
            end
        end)
    end
    
    return data
end

local function injectPacket(packet_id, data)
    local packet = Packet.new(packet_id, data, DIRECTION.INJECT)
    packet.modified = true
    packet:addTag("INJECTED")
    
    addPacket(packet)
    RakNetSpy.stats.injected = RakNetSpy.stats.injected + 1
    RakNetSpy.stats.modified = RakNetSpy.stats.modified + 1
end

-- ============================================================================
-- MOCK PACKET GENERATOR
-- ============================================================================
local mock_timer = 0
local function generateMockPackets(dt)
    if not RakNetSpy.running or RakNetSpy.paused then return end
    
    mock_timer = mock_timer + dt
    if mock_timer < CONFIG.MOCK_PACKET_INTERVAL then return end
    mock_timer = 0
    
    local id = 0x83
    local rand = math.random()
    if rand > 0.85 then 
        local ids = {0x84, 0x85, 0x88, 0x8A}
        id = ids[math.random(#ids)]
    end
    
    local size = math.random(14, 88)
    local data = {id}
    for i = 2, size do
        table.insert(data, math.random(0, 255))
    end
    
    if id == 0x83 then
        data[2] = 0x05
        data[3] = 0x06
        data[4] = 0xB3
        data[5] = 0x4A
    end
    
    local data_str = string.char(table.unpack(data))
    
    if math.random() > 0.5 then
        interceptOutgoing(id, data_str)
    else
        interceptIncoming(id, data_str)
    end
end

-- ============================================================================
-- CUSTOM UI LIBRARY
-- ============================================================================
local UILib = {}

function UILib:Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function UILib:CreateWindow(title)
    local screenGui = self:Create("ScreenGui", {
        Name = "RakNetSpyUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui")
    })
    
    local mainFrame = self:Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 900, 0, 600),
        Position = UDim2.new(0.5, -450, 0.5, -300),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 1,
        BorderColor3 = COLORS.Border,
        Parent = screenGui
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = mainFrame
    })
    
    -- Title bar
    local titleBar = self:Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COLORS.Primary,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = titleBar
    })
    
    -- Fix corners
    local cornerFix = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = COLORS.Primary,
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    local titleLabel = self:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Close button
    local closeBtn = self:Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -30, 0, 2),
        BackgroundColor3 = COLORS.Error,
        Text = "×",
        TextColor3 = COLORS.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Parent = titleBar
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Minimize button
    local minimizeBtn = self:Create("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -62, 0, 2),
        BackgroundColor3 = COLORS.Accent,
        Text = "_",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = titleBar
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = minimizeBtn
    })
    
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        mainFrame:TweenSize(
            minimized and UDim2.new(0, 900, 0, 32) or UDim2.new(0, 900, 0, 600),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    end)
    
    -- Dragging
    local dragging, dragInput, dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Content area
    local contentFrame = self:Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -10, 1, -42),
        Position = UDim2.new(0, 5, 0, 37),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentFrame = contentFrame,
        Elements = {}
    }
end

function UILib:CreateContextMenu(parent)
    local contextMenu = self:Create("Frame", {
        Name = "ContextMenu",
        Size = UDim2.new(0, 180, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = COLORS.Primary,
        BorderSizePixel = 1,
        BorderColor3 = COLORS.Border,
        Visible = false,
        ZIndex = 1000,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = contextMenu
    })
    
    local listLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = contextMenu
    })
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contextMenu.Size = UDim2.new(0, 180, 0, listLayout.AbsoluteContentSize.Y + 4)
    end)
    
    return contextMenu
end

function UILib:AddContextMenuItem(menu, text, callback)
    local menuItem = self:Create("TextButton", {
        Name = text:gsub("%s+", ""),
        Size = UDim2.new(1, -4, 0, 26),
        Position = UDim2.new(0, 2, 0, 0),
        BackgroundColor3 = COLORS.Accent,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = menu
    })
    
    self:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = menuItem
    })
    
    menuItem.MouseButton1Click:Connect(function()
        menu.Visible = false
        if callback then callback() end
    end)
    
    menuItem.MouseEnter:Connect(function()
        menuItem.BackgroundColor3 = COLORS.Selected
    end)
    
    menuItem.MouseLeave:Connect(function()
        menuItem.BackgroundColor3 = COLORS.Accent
    end)
    
    return menuItem
end

function UILib:CreateTabBar(parent, tabs)
    local tabBar = self:Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COLORS.Primary,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = tabBar
    })
    
    local tabButtons = {}
    local tabWidth = 1 / #tabs
    
    for i, tabName in ipairs(tabs) do
        local tabBtn = self:Create("TextButton", {
            Name = tabName .. "Tab",
            Size = UDim2.new(tabWidth, -4, 1, -4),
            Position = UDim2.new(tabWidth * (i - 1), 2, 0, 2),
            BackgroundColor3 = COLORS.Accent,
            Text = tabName,
            TextColor3 = COLORS.Text,
            TextSize = 12,
            Font = Enum.Font.GothamSemibold,
            Parent = tabBar
        })
        
        self:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = tabBtn
        })
        
        tabButtons[tabName] = tabBtn
    end
    
    return tabBar, tabButtons
end

function UILib:CreateButton(parent, text, callback, position, size)
    local button = self:Create("TextButton", {
        Name = text .. "Button",
        Size = size or UDim2.new(1, -10, 0, 28),
        Position = position or UDim2.new(0, 5, 0, 0),
        BackgroundColor3 = COLORS.Accent,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = button
    })
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = COLORS.Primary
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = COLORS.Accent
    end)
    
    return button
end

function UILib:CreateToggle(parent, text, default, callback, position)
    local toggleFrame = self:Create("Frame", {
        Name = text .. "Toggle",
        Size = UDim2.new(1, -10, 0, 28),
        Position = position or UDim2.new(0, 5, 0, 0),
        BackgroundColor3 = COLORS.Accent,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = toggleFrame
    })
    
    local label = self:Create("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame
    })
    
    local toggleBtn = self:Create("TextButton", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -45, 0.5, -10),
        BackgroundColor3 = default and COLORS.Success or COLORS.Error,
        Text = "",
        Parent = toggleFrame
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleBtn
    })
    
    local indicator = self:Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = COLORS.Text,
        Parent = toggleBtn
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = indicator
    })
    
    local toggled = default
    
    toggleBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        toggleBtn.BackgroundColor3 = toggled and COLORS.Success or COLORS.Error
        indicator:TweenPosition(
            toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        if callback then callback(toggled) end
    end)
    
    return toggleFrame
end

function UILib:CreateTextBox(parent, placeholder, callback, position, size)
    local textBox = self:Create("TextBox", {
        Name = placeholder .. "TextBox",
        Size = size or UDim2.new(1, -10, 0, 28),
        Position = position or UDim2.new(0, 5, 0, 0),
        BackgroundColor3 = COLORS.Accent,
        PlaceholderText = placeholder,
        Text = "",
        TextColor3 = COLORS.Text,
        PlaceholderColor3 = COLORS.TextDark,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = textBox
    })
    
    self:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = textBox
    })
    
    if callback then
        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                callback(textBox.Text)
            end
        end)
        
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            if not textBox:IsFocused() then
                callback(textBox.Text)
            end
        end)
    end
    
    return textBox
end

function UILib:CreateScrollFrame(parent, position, size)
    local scrollFrame = self:Create("ScrollingFrame", {
        Name = "ScrollFrame",
        Size = size or UDim2.new(1, -10, 1, -10),
        Position = position or UDim2.new(0, 5, 0, 5),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 1,
        BorderColor3 = COLORS.Border,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.TextDark,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = scrollFrame
    })
    
    local listLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame
    })
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    return scrollFrame
end

function UILib:CreateLabel(parent, text, position, size)
    local label = self:Create("TextLabel", {
        Name = "Label",
        Size = size or UDim2.new(1, -10, 0, 25),
        Position = position or UDim2.new(0, 5, 0, 0),
        BackgroundColor3 = COLORS.Accent,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = label
    })
    
    self:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = label
    })
    
    return label
end

-- ============================================================================
-- PACKET TABLE UI
-- ============================================================================
function UILib:CreatePacketTable(parent)
    local tableFrame = self:Create("Frame", {
        Name = "PacketTable",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 1,
        BorderColor3 = COLORS.Border,
        Parent = parent
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = tableFrame
    })
    
    -- Header
    local header = self:Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = COLORS.Primary,
        BorderSizePixel = 0,
        Parent = tableFrame
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = header
    })
    
    local headerFix = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 1, -4),
        BackgroundColor3 = COLORS.Primary,
        BorderSizePixel = 0,
        Parent = header
    })
    
    local columns = {
        {name = "#", width = 0.08},
        {name = "DIR", width = 0.08},
        {name = "ID", width = 0.12},
        {name = "NAME", width = 0.32},
        {name = "SIZE", width = 0.1},
        {name = "PREVIEW", width = 0.3}
    }
    
    local xPos = 0
    for _, col in ipairs(columns) do
        local headerLabel = self:Create("TextLabel", {
            Size = UDim2.new(col.width, -4, 1, 0),
            Position = UDim2.new(xPos, 2, 0, 0),
            BackgroundTransparency = 1,
            Text = col.name,
            TextColor3 = COLORS.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header
        })
        
        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            Parent = headerLabel
        })
        
        xPos = xPos + col.width
    end
    
    -- Scrolling content
    local scrollFrame = self:Create("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -4, 1, -32),
        Position = UDim2.new(0, 2, 0, 30),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.TextDark,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = tableFrame
    })
    
    local listLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame
    })
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
    end)
    
    return tableFrame, scrollFrame, columns
end

function UILib:CreatePacketRow(parent, packet, columns, index)
    local row = self:Create("TextButton", {
        Name = "Row_" .. packet.number,
        Size = UDim2.new(1, -4, 0, 24),
        BackgroundColor3 = index % 2 == 0 and COLORS.RowEven or COLORS.RowOdd,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = packet.number,
        Parent = parent
    })
    
    local dirColor = COLORS.Text
    if packet.direction == DIRECTION.SEND then
        dirColor = COLORS.Send
    elseif packet.direction == DIRECTION.RECEIVE then
        dirColor = COLORS.Receive
    elseif packet.direction == DIRECTION.INJECT then
        dirColor = COLORS.Inject
    end
    
    local data = {
        tostring(packet.number),
        packet.direction,
        string.format("0x%02X", packet.id),
        packet:getName(),
        string.format("%d B", packet.size),
        packet:getHexPreview(10)
    }
    
    local xPos = 0
    for i, col in ipairs(columns) do
        local cellLabel = self:Create("TextLabel", {
            Size = UDim2.new(col.width, -4, 1, 0),
            Position = UDim2.new(xPos, 2, 0, 0),
            BackgroundTransparency = 1,
            Text = data[i] or "",
            TextColor3 = (i == 2) and dirColor or COLORS.Text,
            TextSize = 10,
            Font = (i == 1 or i == 2 or i == 3) and Enum.Font.GothamBold or Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        })
        
        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            Parent = cellLabel
        })
        
        xPos = xPos + col.width
    end
    
    row.MouseButton1Click:Connect(function()
        RakNetSpy.selected_packet = packet
        updatePacketDetails()
        updateSelectedRow()
    end)
    
    -- Right-click context menu
    row.MouseButton2Click:Connect(function()
        showContextMenu(packet, row)
    end)
    
    row.MouseEnter:Connect(function()
        if RakNetSpy.selected_packet ~= packet then
            row.BackgroundColor3 = COLORS.Primary
        end
    end)
    
    row.MouseLeave:Connect(function()
        if RakNetSpy.selected_packet ~= packet then
            row.BackgroundColor3 = index % 2 == 0 and COLORS.RowEven or COLORS.RowOdd
        end
    end)
    
    return row
end

-- ============================================================================
-- BUILD MAIN UI
-- ============================================================================
local UI = UILib:CreateWindow(string.format("RakNet Spy v%s", CONFIG.VERSION))

-- Create context menu
local contextMenu = UILib:CreateContextMenu(UI.ScreenGui)
RakNetSpy.ui.context_menu = contextMenu

-- Context menu items
UILib:AddContextMenuItem(contextMenu, "📋 Copy Hex", function()
    if RakNetSpy.selected_packet then
        setclipboard(RakNetSpy.selected_packet:getFullHex())
    end
end)

UILib:AddContextMenuItem(contextMenu, "📝 Copy as JSON", function()
    if RakNetSpy.selected_packet then
        setclipboard(RakNetSpy.selected_packet:toJSON())
    end
end)

UILib:AddContextMenuItem(contextMenu, "🔁 Replay Packet", function()
    if RakNetSpy.selected_packet then
        local p = RakNetSpy.selected_packet
        injectPacket(p.id, p.data)
    end
end)

UILib:AddContextMenuItem(contextMenu, "🔧 Load to Forge", function()
    if RakNetSpy.selected_packet then
        local p = RakNetSpy.selected_packet
        if forgeIdBox and forgeDataBox then
            forgeIdBox.Text = string.format("0x%02X", p.id)
            forgeDataBox.Text = p:getFullHex()
            -- Switch to Tools tab
            for name, content in pairs(tabs) do
                content.Visible = (name == "Tools")
                tabButtons[name].BackgroundColor3 = (name == "Tools") and COLORS.Success or COLORS.Accent
            end
            RakNetSpy.ui.current_tab = "Tools"
        end
    end
end)

UILib:AddContextMenuItem(contextMenu, "🚫 Blacklist ID", function()
    if RakNetSpy.selected_packet then
        RakNetSpy.blacklist[RakNetSpy.selected_packet.id] = true
    end
end)

UILib:AddContextMenuItem(contextMenu, "🔍 Filter by ID", function()
    if RakNetSpy.selected_packet then
        RakNetSpy.id_filter = RakNetSpy.selected_packet.id
        RakNetSpy.needs_full_refresh = true
    end
end)

UILib:AddContextMenuItem(contextMenu, "❌ Clear Filters", function()
    RakNetSpy.id_filter = nil
    RakNetSpy.text_filter = ""
    RakNetSpy.dir_filter = 0
    RakNetSpy.needs_full_refresh = true
end)

-- Hide context menu when clicking elsewhere
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.MouseButton2 then
        if contextMenu.Visible then
            contextMenu.Visible = false
        end
    end
end)

function showContextMenu(packet, row)
    RakNetSpy.selected_packet = packet
    updatePacketDetails()
    updateSelectedRow()
    
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
    local screenSize = workspace.CurrentCamera.ViewportSize
    
    -- Position context menu at mouse, but keep it on screen
    local xPos = mousePos.X
    local yPos = mousePos.Y - 36 -- Adjust for top bar
    
    if xPos + 180 > screenSize.X then
        xPos = screenSize.X - 180
    end
    
    if yPos + contextMenu.AbsoluteSize.Y > screenSize.Y then
        yPos = screenSize.Y - contextMenu.AbsoluteSize.Y
    end
    
    contextMenu.Position = UDim2.new(0, xPos, 0, yPos)
    contextMenu.Visible = true
end

local tabBar, tabButtons = UILib:CreateTabBar(UI.ContentFrame, {"Main", "Packets", "Details", "Tools", "Export", "Stats"})

-- Tab content containers
local tabs = {}
for tabName in pairs(tabButtons) do
    local tabContent = UILib:Create("Frame", {
        Name = tabName .. "Content",
        Size = UDim2.new(1, 0, 1, -37),
        Position = UDim2.new(0, 0, 0, 37),
        BackgroundTransparency = 1,
        Visible = (tabName == "Main"),
        Parent = UI.ContentFrame
    })
    tabs[tabName] = tabContent
end

-- Tab switching
for tabName, button in pairs(tabButtons) do
    button.MouseButton1Click:Connect(function()
        for name, content in pairs(tabs) do
            content.Visible = (name == tabName)
            tabButtons[name].BackgroundColor3 = (name == tabName) and COLORS.Success or COLORS.Accent
        end
        RakNetSpy.ui.current_tab = tabName
        
        -- Force refresh packet table when switching to Packets tab
        if tabName == "Packets" then
            RakNetSpy.needs_full_refresh = true
        end
    end)
end

tabButtons["Main"].BackgroundColor3 = COLORS.Success

-- ============================================================================
-- MAIN TAB
-- ============================================================================
local mainScroll = UILib:CreateScrollFrame(tabs["Main"])

local yPos = 5

UILib:CreateButton(mainScroll, "▶ Start Capture", function()
    RakNetSpy.running = true
    RakNetSpy.paused = false
    if RakNetSpy.stats.start_time == 0 then
        RakNetSpy.stats.start_time = tick()
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(mainScroll, "⏹ Stop Capture", function()
    RakNetSpy.running = false
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(mainScroll, "⏸ Toggle Pause", function()
    RakNetSpy.paused = not RakNetSpy.paused
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(mainScroll, "🗑 Clear All Packets", function()
    clearPackets()
    if RakNetSpy.ui.details_text then
        RakNetSpy.ui.details_text.Text = "No packet selected"
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 35

UILib:CreateToggle(mainScroll, "Enable Sending", true, function(value)
    RakNetSpy.snd_enabled = value
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateToggle(mainScroll, "Drop All Received", false, function(value)
    RakNetSpy.drop_rcv = value
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 35

UILib:CreateLabel(mainScroll, "Direction Filter:", UDim2.new(0, 5, 0, yPos))
yPos = yPos + 27

UILib:CreateButton(mainScroll, "All", function()
    RakNetSpy.dir_filter = 0
    RakNetSpy.needs_full_refresh = true
end, UDim2.new(0, 5, 0, yPos), UDim2.new(0.3, -7, 0, 28))

UILib:CreateButton(mainScroll, "Sent Only", function()
    RakNetSpy.dir_filter = 1
    RakNetSpy.needs_full_refresh = true
end, UDim2.new(0.35, 0, 0, yPos), UDim2.new(0.3, -7, 0, 28))

UILib:CreateButton(mainScroll, "Received Only", function()
    RakNetSpy.dir_filter = 2
    RakNetSpy.needs_full_refresh = true
end, UDim2.new(0.7, 2, 0, yPos), UDim2.new(0.3, -7, 0, 28))
yPos = yPos + 35

UILib:CreateTextBox(mainScroll, "Search (name, ID, hex)...", function(value)
    RakNetSpy.text_filter = value
    RakNetSpy.needs_full_refresh = true
end, UDim2.new(0, 5, 0, yPos))

-- ============================================================================
-- PACKETS TAB
-- ============================================================================
local packetTableFrame, packetScrollFrame, packetColumns = UILib:CreatePacketTable(tabs["Packets"])
RakNetSpy.ui.scroll_frame = packetScrollFrame

function updateSelectedRow()
    if not RakNetSpy.ui.scroll_frame then return end
    
    for _, child in ipairs(RakNetSpy.ui.scroll_frame:GetChildren()) do
        if child:IsA("TextButton") and child.Name:match("^Row_") then
            local rowNum = tonumber(child.Name:match("%d+"))
            if RakNetSpy.selected_packet and rowNum == RakNetSpy.selected_packet.number then
                child.BackgroundColor3 = COLORS.Selected
            else
                local index = child.LayoutOrder
                child.BackgroundColor3 = index % 2 == 0 and COLORS.RowEven or COLORS.RowOdd
            end
        end
    end
end

function updatePacketTable()
    if not RakNetSpy.ui.scroll_frame then return end
    
    local filtered = filterPackets()
    local current_count = #filtered
    
    -- Full rebuild only when needed
    if RakNetSpy.needs_full_refresh then
        -- Clear all rows
        for _, child in ipairs(RakNetSpy.ui.scroll_frame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        RakNetSpy.ui.packet_row_map = {}
        
        -- Show only last N packets for performance
        local start_index = math.max(1, current_count - CONFIG.MAX_VISIBLE_PACKETS + 1)
        
        for i = start_index, current_count do
            local packet = filtered[i]
            local row = UILib:CreatePacketRow(RakNetSpy.ui.scroll_frame, packet, packetColumns, i)
            RakNetSpy.ui.packet_row_map[packet.number] = row
        end
        
        RakNetSpy.last_packet_count = current_count
        RakNetSpy.needs_full_refresh = false
        
        -- Auto scroll to bottom
        task.defer(function()
            RakNetSpy.ui.scroll_frame.CanvasPosition = Vector2.new(0, RakNetSpy.ui.scroll_frame.AbsoluteCanvasSize.Y)
        end)
    else
        -- Incremental update - only add new packets
        if current_count > RakNetSpy.last_packet_count then
            for i = RakNetSpy.last_packet_count + 1, current_count do
                local packet = filtered[i]
                
                -- Remove oldest if exceeding max
                if i > CONFIG.MAX_VISIBLE_PACKETS then
                    local old_packet_num = filtered[i - CONFIG.MAX_VISIBLE_PACKETS].number
                    if RakNetSpy.ui.packet_row_map[old_packet_num] then
                        RakNetSpy.ui.packet_row_map[old_packet_num]:Destroy()
                        RakNetSpy.ui.packet_row_map[old_packet_num] = nil
                    end
                end
                
                local row = UILib:CreatePacketRow(RakNetSpy.ui.scroll_frame, packet, packetColumns, i)
                RakNetSpy.ui.packet_row_map[packet.number] = row
            end
            
            RakNetSpy.last_packet_count = current_count
            
            -- Auto scroll to bottom
            task.defer(function()
                RakNetSpy.ui.scroll_frame.CanvasPosition = Vector2.new(0, RakNetSpy.ui.scroll_frame.AbsoluteCanvasSize.Y)
            end)
        end
    end
end

-- ============================================================================
-- DETAILS TAB
-- ============================================================================
local detailsContainer = UILib:Create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Parent = tabs["Details"]
})

local detailsScroll = UILib:CreateScrollFrame(detailsContainer)

local detailsText = UILib:Create("TextLabel", {
    Name = "DetailsText",
    Size = UDim2.new(1, -10, 1, 0),
    BackgroundTransparency = 1,
    Text = "No packet selected",
    TextColor3 = COLORS.Text,
    TextSize = 11,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Parent = detailsScroll
})

RakNetSpy.ui.details_text = detailsText

function updatePacketDetails()
    if not RakNetSpy.selected_packet then
        detailsText.Text = "No packet selected"
        return
    end
    
    local p = RakNetSpy.selected_packet
    
    local info = string.format(
        "═══════════════════════════════════════════════════════════\n" ..
        "PACKET #%d DETAILS\n" ..
        "═══════════════════════════════════════════════════════════\n\n" ..
        "ID:         0x%02X (%d)\n" ..
        "Name:       %s\n" ..
        "Direction:  %s\n" ..
        "Size:       %d bytes\n" ..
        "Timestamp:  %.3f\n" ..
        "Modified:   %s\n\n" ..
        "───────────────────────────────────────────────────────────\n" ..
        "HEX DUMP\n" ..
        "───────────────────────────────────────────────────────────\n\n%s\n",
        p.number,
        p.id, p.id,
        p:getName(),
        p.direction,
        p.size,
        p.timestamp,
        p.modified and "YES" or "NO",
        p:getFormatted()
    )
    
    detailsText.Text = info
    
    -- Auto-size
    task.defer(function()
        local textBounds = game:GetService("TextService"):GetTextSize(
            info,
            11,
            Enum.Font.Code,
            Vector2.new(detailsScroll.AbsoluteSize.X - 20, math.huge)
        )
        detailsText.Size = UDim2.new(1, -10, 0, textBounds.Y + 10)
    end)
end

-- ============================================================================
-- TOOLS TAB
-- ============================================================================
local toolsScroll = UILib:CreateScrollFrame(tabs["Tools"])

yPos = 5

local forgeIdBox = UILib:CreateTextBox(toolsScroll, "Packet ID (0x83 or 131)", nil, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

local forgeDataBox = UILib:CreateTextBox(toolsScroll, "Hex Data (AA BB CC DD...)", nil, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 35

UILib:CreateButton(toolsScroll, "🔨 Forge & Inject Packet", function()
    local id_str = forgeIdBox.Text
    local id = tonumber(id_str:match("0x%x+")) or tonumber(id_str)
    
    if not id then return end
    
    local data_str = parseHexString(forgeDataBox.Text)
    if data_str then
        injectPacket(id, data_str)
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(toolsScroll, "Load from Selected Packet", function()
    if RakNetSpy.selected_packet then
        local p = RakNetSpy.selected_packet
        forgeIdBox.Text = string.format("0x%02X", p.id)
        forgeDataBox.Text = p:getFullHex()
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(toolsScroll, "Copy Selected Hex to Clipboard", function()
    if RakNetSpy.selected_packet then
        setclipboard(RakNetSpy.selected_packet:getFullHex())
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(toolsScroll, "Replay Selected Packet", function()
    if RakNetSpy.selected_packet then
        local p = RakNetSpy.selected_packet
        injectPacket(p.id, p.data)
    end
end, UDim2.new(0, 5, 0, yPos))

-- ============================================================================
-- EXPORT TAB
-- ============================================================================
local exportScroll = UILib:CreateScrollFrame(tabs["Export"])

yPos = 5

UILib:CreateLabel(exportScroll, "Export Packets to Clipboard", UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📄 Export All as JSON", function()
    local json = exportToJSON(RakNetSpy.packets)
    setclipboard(json)
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📊 Export All as CSV", function()
    local csv = exportToCSV(RakNetSpy.packets)
    setclipboard(csv)
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📝 Export All as Text", function()
    local text = exportToText(RakNetSpy.packets)
    setclipboard(text)
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 35

UILib:CreateLabel(exportScroll, "Export Filtered Packets", UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📄 Export Filtered as JSON", function()
    local filtered = filterPackets()
    local json = exportToJSON(filtered)
    setclipboard(json)
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📊 Export Filtered as CSV", function()
    local filtered = filterPackets()
    local csv = exportToCSV(filtered)
    setclipboard(csv)
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📝 Export Filtered as Text", function()
    local filtered = filterPackets()
    local text = exportToText(filtered)
    setclipboard(text)
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 35

UILib:CreateLabel(exportScroll, "Export Selected Packet", UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📄 Export Selected as JSON", function()
    if RakNetSpy.selected_packet then
        setclipboard(RakNetSpy.selected_packet:toJSON())
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📋 Export Selected Hex", function()
    if RakNetSpy.selected_packet then
        setclipboard(RakNetSpy.selected_packet:getFullHex())
    end
end, UDim2.new(0, 5, 0, yPos))
yPos = yPos + 30

UILib:CreateButton(exportScroll, "📝 Export Selected Details", function()
    if RakNetSpy.selected_packet then
        local text = exportToText({RakNetSpy.selected_packet})
        setclipboard(text)
    end
end, UDim2.new(0, 5, 0, yPos))

-- ============================================================================
-- STATS TAB
-- ============================================================================
local statsScroll = UILib:CreateScrollFrame(tabs["Stats"])

local statsLabel = UILib:CreateLabel(statsScroll, "Statistics", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 1, -10))
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 11
RakNetSpy.ui.stats_label = statsLabel

function updateStats()
    if not RakNetSpy.ui.stats_label then return end
    
    local stats = RakNetSpy.stats
    local uptime = tick() - (stats.start_time ~= 0 and stats.start_time or tick())
    local total = #RakNetSpy.packets
    local pps = total / math.max(uptime, 1)
    
    local statsText = string.format(
        "═══════════════════════════════════════════════════════════\n" ..
        "RAKNET SPY STATISTICS\n" ..
        "═══════════════════════════════════════════════════════════\n\n" ..
        "Status:        %s\n" ..
        "Uptime:        %s\n" ..
        "Total Packets: %d (%.2f/sec)\n\n" ..
        "───────────────────────────────────────────────────────────\n" ..
        "PACKET BREAKDOWN\n" ..
        "───────────────────────────────────────────────────────────\n\n" ..
        "Sent:          %d\n" ..
        "Received:      %d\n" ..
        "Injected:      %d\n" ..
        "Dropped:       %d\n" ..
        "Blacklisted:   %d\n" ..
        "Modified:      %d\n\n" ..
        "───────────────────────────────────────────────────────────\n" ..
        "FILTERS\n" ..
        "───────────────────────────────────────────────────────────\n\n" ..
        "Direction:     %s\n" ..
        "ID Filter:     %s\n" ..
        "Text Filter:   %s\n" ..
        "Blacklisted:   %d packet types\n",
        RakNetSpy.running and (RakNetSpy.paused and "PAUSED" or "RUNNING") or "STOPPED",
        formatTime(uptime),
        total, pps,
        stats.sent,
        stats.received,
        stats.injected,
        stats.dropped,
        stats.blacklisted,
        stats.modified,
        RakNetSpy.dir_filter == 0 and "All" or (RakNetSpy.dir_filter == 1 and "Sent Only" or "Received Only"),
        RakNetSpy.id_filter and string.format("0x%02X", RakNetSpy.id_filter) or "None",
        RakNetSpy.text_filter ~= "" and RakNetSpy.text_filter or "None",
        (function()
            local count = 0
            for _ in pairs(RakNetSpy.blacklist) do count = count + 1 end
            return count
        end)()
    )
    
    RakNetSpy.ui.stats_label.Text = statsText
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
local last_time = tick()
local last_table_update = 0
local RunService = game:GetService("RunService")

RunService.RenderStepped:Connect(function()
    local current_time = tick()
    local dt = current_time - last_time
    last_time = current_time
    
    generateMockPackets(dt)
    
    -- Update UI periodically
    if current_time - last_table_update > CONFIG.UI_UPDATE_INTERVAL then
        last_table_update = current_time
        
        if RakNetSpy.ui.current_tab == "Packets" then
            updatePacketTable()
        elseif RakNetSpy.ui.current_tab == "Stats" then
            updateStats()
        end
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
updateStats()

-- Export API
return {
    interceptOutgoing = interceptOutgoing,
    interceptIncoming = interceptIncoming,
    injectPacket = injectPacket,
    RakNetSpy = RakNetSpy,
    Packet = Packet,
    UI = UI
}