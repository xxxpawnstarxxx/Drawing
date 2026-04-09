local _ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

-- delete old instance

if _G.main_run_connection then
    _G.main_run_connection:Disconnect()
    _G.main_run_connection = nil
end

if game.CoreGui:FindFirstChild("DamagedGui") then
	game.CoreGui:FindFirstChild("DamagedGui"):Destroy()
end

-- utils

local ts = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local dragging = false
local dragStart = Vector2.new(0, 0)
local startPos = UDim2.new(0, 0, 0, 0)

function update(gui, delta, speed)
	local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	gui:TweenPosition(newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, speed, true)
end

local function getTime(sec)
	local time = os.date("*t")
	local formattedTime = string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
	return formattedTime
end

local function colorsAreEqual(color1, color2)
	return color1.R == color2.R and color1.G == color2.G and color1.B == color2.B
end

-- slider shi

local slider_db = false
local coloring = false

userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		slider_db = false
	end
end)

function snap(number, factor)
	if factor == 0 then
		return number
	else
		return math.floor(number / factor + 0.5) * factor
	end
end

-- library

local lib = {}

function lib:Create(name)
	local window = {}
	
	local slacklibv2 = Instance.new("ScreenGui")
	local Main = Instance.new("Frame")
	local Tabs = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")
	local UIListLayout2 = Instance.new("UIListLayout")
	local Tab = Instance.new("ImageButton")
	local UIPadding = Instance.new("UIPadding")
	local Info = Instance.new("Frame")
	local InfoText = Instance.new("TextLabel")
	local Content = Instance.new("ScrollingFrame")

	slacklibv2.Name = "DamagedGui"
	slacklibv2.Parent = game.CoreGui
	slacklibv2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	slacklibv2.DisplayOrder = 999999
	slacklibv2.ResetOnSpawn = false
	_ProtectGui(slacklibv2)
	
	Main.Name = "Main"
	Main.Parent = slacklibv2
	Main.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
	Main.BorderColor3 = Color3.fromRGB(62, 62, 80)
	Main.Position = UDim2.new(0.257954001, 0, 0.263660014, 0)
	Main.Size = UDim2.new(0, 787, 0, 525)

	Tabs.Name = "Tabs"
	Tabs.Parent = Main
	Tabs.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
	Tabs.BorderColor3 = Color3.fromRGB(41, 41, 53)
	Tabs.Size = UDim2.new(0, 787, 0, 60)

	UIListLayout.Parent = Tabs
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0.00999999978, 0)

	UIPadding.Parent = Tabs
	UIPadding.PaddingTop = UDim.new(0, 12)

	Info.Name = "Info"
	Info.Parent = Main
	Info.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
	Info.BorderColor3 = Color3.fromRGB(41, 41, 53)
	Info.Position = UDim2.new(0, 0, 0.95047617, 0)
	Info.Size = UDim2.new(0, 787, 0, 26)

	InfoText.Name = "InfoText"
	InfoText.Parent = Info
	InfoText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	InfoText.BackgroundTransparency = 1.000
	InfoText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	InfoText.BorderSizePixel = 0
	InfoText.Position = UDim2.new(0, 5, 0, 0)
	InfoText.Size = UDim2.new(0, 249, 0, 26)
	InfoText.Font = Enum.Font.SourceSans
	InfoText.TextColor3 = Color3.fromRGB(96, 96, 124)
	InfoText.TextSize = 14.000
	InfoText.TextXAlignment = Enum.TextXAlignment.Left

	Content.Name = "Content"
	Content.Parent = Main
	Content.Active = true
	Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Content.BackgroundTransparency = 1.000
	Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Content.BorderSizePixel = 0
	Content.Position = UDim2.new(0.0165184252, 0, 0.139047623, 0)
	Content.Size = UDim2.new(0, 761, 0, 414)
	Content.ScrollBarThickness = 5
	Content.ScrollBarImageColor3 = Color3.fromRGB(41, 41, 53)
	
	UIListLayout2.Parent = Content
	UIListLayout2.FillDirection = Enum.FillDirection.Vertical
	UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout2.Padding = UDim.new(0,7)
	
	-- color picker popup
	
	local color_picker_associated_with = nil

	local ColorPickerFrame = Instance.new("Frame")
	local Color = Instance.new("Frame")
	local DragBig = Instance.new("TextButton")
	local UIGradient = Instance.new("UIGradient")
	local Colors = Instance.new("ImageLabel")
	local DragCP = Instance.new("TextButton")
	local Close = Instance.new("TextButton")
	local TextLabel = Instance.new("TextLabel")

	ColorPickerFrame.Name = "ColorPickerFrame"
	ColorPickerFrame.Parent = Main
	ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
	ColorPickerFrame.BorderColor3 = Color3.fromRGB(62, 62, 80)
	ColorPickerFrame.Position = UDim2.new(1.014,0,0,0)
	ColorPickerFrame.Size = UDim2.new(0, 145, 0, 141)
	ColorPickerFrame.Visible = false

	Color.Name = "Color"
	Color.Parent = ColorPickerFrame
	Color.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	Color.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Color.BorderSizePixel = 0
	Color.Position = UDim2.new(0.0445809215, 0, 0.190047681, 0)
	Color.Size = UDim2.new(0, 100, 0, 104)

	DragBig.Name = "DragBig"
	DragBig.Parent = Color
	DragBig.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DragBig.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DragBig.Position = UDim2.new(0.939999998, 0, 0, 0)
	DragBig.Size = UDim2.new(0, 6, 0, 6)
	DragBig.Font = Enum.Font.SourceSans
	DragBig.Text = ""
	DragBig.TextColor3 = Color3.fromRGB(0, 0, 0)
	DragBig.TextSize = 14.000

	UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
	UIGradient.Rotation = 90
	UIGradient.Parent = Color

	Colors.Name = "Colors"
	Colors.Parent = ColorPickerFrame
	Colors.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Colors.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Colors.BorderSizePixel = 0
	Colors.Position = UDim2.new(0.813103616, 0, 0.275154054, 0)
	Colors.Size = UDim2.new(0, 17, 0, 91)
	Colors.Image = "rbxassetid://18935576533"

	DragCP.Name = "Drag"
	DragCP.Parent = Colors
	DragCP.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DragCP.BackgroundTransparency = 0
	DragCP.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DragCP.BorderSizePixel = 0
	DragCP.Size = UDim2.new(0, 17, 0, 4)
	DragCP.Font = Enum.Font.SourceSans
	DragCP.Text = ""
	DragCP.TextColor3 = Color3.fromRGB(0, 0, 0)
	DragCP.TextSize = 14.000

	Close.Name = "Close"
	Close.Parent = ColorPickerFrame
	Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Close.BackgroundTransparency = 1.000
	Close.BorderColor3 = Color3.fromRGB(255, 255, 255)
	Close.BorderSizePixel = 0
	Close.Position = UDim2.new(0.813103616, 0, 0.0500000007, 0)
	Close.Size = UDim2.new(0, 17, 0, 16)
	Close.Font = Enum.Font.SourceSansBold
	Close.Text = "X"
	Close.TextColor3 = Color3.fromRGB(86, 86, 111)
	Close.TextSize = 26.000
	Close.TextWrapped = true

	TextLabel.Parent = ColorPickerFrame
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.BackgroundTransparency = 1.000
	TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.BorderSizePixel = 0
	TextLabel.Position = UDim2.new(0, 0, 0.0431486107, 0)
	TextLabel.Size = UDim2.new(0, 106, 0, 15)
	TextLabel.Font = Enum.Font.SourceSans
	TextLabel.TextColor3 = Color3.fromRGB(112, 112, 145)
	TextLabel.TextScaled = true
	TextLabel.TextSize = 14.000
	TextLabel.TextWrapped = true

	local userInputService = game:GetService("UserInputService")

	local coloring = false
	local coloring_hue = false
	local hue = 0
	local colorpicker_x = 0
	local colorpicker_y = 0
	local colorpicker_hue_y = 0

	DragBig.MouseButton1Down:Connect(function()
		coloring = true
	end)

	DragCP.MouseButton1Down:Connect(function()
		coloring_hue = true
	end)

	Close.MouseButton1Down:Connect(function()
		ColorPickerFrame.Visible = false
		coloring = false
	end)

	_G.main_run_connection = game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.date("*t")
		InfoText.Text = name.. " | "..workspace.Parent.Name.." | "..getTime()

		-- colorpicker controls

		if coloring then
			local mousePosX = userInputService:GetMouseLocation().X
			local mousePosY = game.Players.LocalPlayer:GetMouse().Y

			local scrollBg_pos = Color.AbsolutePosition.X
			local scrollBg_size = Color.AbsoluteSize.X
			colorpicker_x = math.clamp((mousePosX - scrollBg_pos) / scrollBg_size, 0, 0.98)

			local scrollBg_posY = Color.AbsolutePosition.Y
			local scrollBg_sizeY = Color.AbsoluteSize.Y
			colorpicker_y = 1 - math.clamp((mousePosY - scrollBg_posY) / scrollBg_sizeY, 0, 1)

			DragBig.Position = UDim2.new(colorpicker_x, 0, 1 - colorpicker_y, 0)
		end

		if coloring_hue then
			local mousePosY = game.Players.LocalPlayer:GetMouse().Y

			local scrollBg_posY = Color.AbsolutePosition.Y
			local scrollBg_sizeY = Color.AbsoluteSize.Y
			colorpicker_hue_y = math.clamp((mousePosY - scrollBg_posY) / scrollBg_sizeY, 0, 0.98)

			DragCP.Position = UDim2.new(0, 0, colorpicker_hue_y, 0)
		end
		
		hue = colorpicker_hue_y
		local hsvColor = Color3.fromHSV(hue, colorpicker_x, colorpicker_y)
		local rgbColor = Color3.new(hsvColor.R, hsvColor.B, hsvColor.G) 
		Color.BackgroundColor3 = rgbColor
		
		if color_picker_associated_with then
			if color_picker_associated_with:FindFirstChild("Preview") then
				 color_picker_associated_with:FindFirstChild("Preview").BackgroundColor3 = rgbColor
			end
		end
	end)
	
	-- dragging
	
	Tabs.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			update(Main, delta, 0.05)
		end
	end)

	userInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
			slacklibv2.Enabled = not slacklibv2.Enabled
		end
	end)

	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			coloring = false
			coloring_hue = false
		end
	end)
	
	-- tab
	
	local tab_contents = {}
	local tab_index = 0

	function window:Tab(image, change_color)
		local tab = {}

		local Tab = Instance.new("ImageButton")
		Tab.Name = "Tab"..tab_index
		tab_index = tab_index + 1
		Tab.Parent = Tabs
		Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Tab.BackgroundTransparency = 1.000
		Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tab.BorderSizePixel = 0
		Tab.Position = UDim2.new(0.477763653, 0, 0, 0)
		Tab.Size = UDim2.new(0, 35, 0, 35)
		Tab.Image = image
		Tab.ImageColor3 = change_color and Color3.fromRGB(93, 93, 121) or Color3.fromRGB(255,255,255)
		Tab.Modal = true

		-- show/hide content

		Tab.MouseButton1Down:Connect(function()
			for _, content in pairs(tab_contents) do
				if content[1] == Tab.Name then
					content[2].Visible = true
					content[2].Transparency = 0
				else
					local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					local tween = ts:Create(content[2], info, {Transparency = 1})
					tween:Play()
					tween.Completed:Connect(function()
						task.wait(0.01)
						content[2].Visible = false
					end)
				end
			end
			
			local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			local tween = ts:Create(Tab, info, {ImageColor3 = Color3.fromRGB(99, 99, 129)})
			tween:Play()

			tween.Completed:Connect(function()
				local info2 = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				local tween2 = ts:Create(Tab, info2, {ImageColor3 = Color3.fromRGB(93, 93, 121)})
				tween2:Play()
			end)
		end)

		-- label

		function tab:Label(text)
			local Label = Instance.new("TextLabel")
			local Corner = Instance.new("ImageLabel")
			local UIPadding = Instance.new("UIPadding")

			Label.Name = "Label"
			Label.Parent = Content
			Label.BackgroundColor3 = Color3.fromRGB(36,36,46)
			Label.BackgroundTransparency = 0
			Label.BorderColor3 = Color3.fromRGB(46, 46, 59)
			Label.Size = UDim2.new(0, 745, 0, 24)
			Label.Font = Enum.Font.SourceSans
			Label.TextColor3 = Color3.fromRGB(112, 112, 145)
			Label.TextSize = 14.000
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Text = text
			Label.Visible = false

			Corner.Name = "Corner"
			Corner.Parent = Label
			Corner.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Corner.BackgroundTransparency = 1.000
			Corner.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Corner.BorderSizePixel = 0
			Corner.Position = UDim2.new(0.967567563, 0, 0, 0)
			Corner.Size = UDim2.new(0, 24, 0, 24)
			Corner.Image = "rbxassetid://18935468360"
			Corner.ImageColor3 = Color3.fromRGB(44, 44, 57)

			UIPadding.Parent = Label
			UIPadding.PaddingLeft = UDim.new(0, 5)

			table.insert(tab_contents, {Tab.Name, Label})
		end
	
		function tab:Textbox(text, placeholder,default, fnc)
			local Textbox = Instance.new("TextLabel")
			local Corner = Instance.new("ImageLabel")
			local TextImage = Instance.new("ImageLabel")
			local UIPadding = Instance.new("UIPadding")
			local TextBox = Instance.new("TextBox")

			Textbox.Name = "Textbox"
			Textbox.Parent = Content
			Textbox.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
			Textbox.BorderColor3 = Color3.fromRGB(46, 46, 59)
			Textbox.Position = UDim2.new(0, 0, 0.432367146, 0)
			Textbox.Size = UDim2.new(0, 745, 0, 45)
			Textbox.Font = Enum.Font.SourceSans
			Textbox.Text = text
			Textbox.TextColor3 = Color3.fromRGB(112, 112, 145)
			Textbox.TextSize = 14.000
			Textbox.TextXAlignment = Enum.TextXAlignment.Left
			Textbox.Visible = false

			Corner.Name = "Corner"
			Corner.Parent = Textbox
			Corner.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Corner.BackgroundTransparency = 1.000
			Corner.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Corner.BorderSizePixel = 0
			Corner.Position = UDim2.new(0.967567623, 0, 0.839999974, 0)
			Corner.Size = UDim2.new(0, 24, 0, 24)
			Corner.Image = "rbxassetid://18935468360"
			Corner.ImageColor3 = Color3.fromRGB(44, 44, 57)

			TextImage.Name = "TextImage"
			TextImage.Parent = Textbox
			TextImage.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			TextImage.BackgroundTransparency = 1.000
			TextImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextImage.BorderSizePixel = 0
			TextImage.Position = UDim2.new(0.935135245, 0, 0.360000014, 0)
			TextImage.Size = UDim2.new(0, 24, 0, 24)
			TextImage.Image = "rbxassetid://18935517937"
			TextImage.ImageColor3 = Color3.fromRGB(66, 66, 85)

			UIPadding.Parent = Textbox
			UIPadding.PaddingBottom = UDim.new(0, 20)
			UIPadding.PaddingLeft = UDim.new(0, 5)

			TextBox.Parent = Textbox
			TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextBox.BackgroundTransparency = 1.000
			TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextBox.BorderSizePixel = 0
			TextBox.Position = UDim2.new(0.00675650919, 0, 0.870000005, 0)
			TextBox.Size = UDim2.new(0, 677, 0, 21)
			TextBox.Font = Enum.Font.SourceSans
			TextBox.Text = default
			TextBox.TextColor3 = Color3.fromRGB(138, 138, 179)
			TextBox.TextSize = 14.000
			TextBox.TextXAlignment = Enum.TextXAlignment.Left
			TextBox.TextEditable = true
			TextBox.ClearTextOnFocus = false
			TextBox.PlaceholderText = placeholder
			TextBox.PlaceholderColor3 = Color3.fromRGB(83, 83, 83)
			
			TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				fnc(TextBox.Text)
			end)
			
			table.insert(tab_contents, {Tab.Name, Textbox})
		end
	
		-- button

		function tab:Button(text, fnc)
			local Button = Instance.new("TextButton")
			local Corner = Instance.new("ImageLabel")
			local UIPadding = Instance.new("UIPadding")
			local ClickImage = Instance.new("ImageLabel")

			Button.Name = "Button"
			Button.Parent = Content
			Button.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
			Button.BorderColor3 = Color3.fromRGB(46, 46, 59)
			Button.Position = UDim2.new(0, 0, 0.0821256042, 0)
			Button.Size = UDim2.new(0, 745, 0, 24)
			Button.Font = Enum.Font.SourceSans
			Button.TextColor3 = Color3.fromRGB(112, 112, 145)
			Button.TextSize = 14.000
			Button.TextXAlignment = Enum.TextXAlignment.Left
			Button.Text = text
			Button.AutoButtonColor = false
			Button.Visible = false

			Corner.Name = "Corner"
			Corner.Parent = Button
			Corner.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Corner.BackgroundTransparency = 1.000
			Corner.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Corner.BorderSizePixel = 0
			Corner.Position = UDim2.new(0.967567563, 0, 0, 0)
			Corner.Size = UDim2.new(0, 24, 0, 24)
			Corner.Image = "rbxassetid://18935468360"
			Corner.ImageColor3 = Color3.fromRGB(44, 44, 57)

			UIPadding.Parent = Button
			UIPadding.PaddingLeft = UDim.new(0, 5)

			ClickImage.Name = "ClickImage"
			ClickImage.Parent = Button
			ClickImage.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			ClickImage.BackgroundTransparency = 1.000
			ClickImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ClickImage.BorderSizePixel = 0
			ClickImage.Position = UDim2.new(0.935135126, 0, 0, 0)
			ClickImage.Size = UDim2.new(0, 24, 0, 24)
			ClickImage.Image = "rbxassetid://16081386298"
			ClickImage.ImageColor3 = Color3.fromRGB(66, 66, 85)
			
			-- run function & animate background
			
			Button.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					local tween = ts:Create(Button, info, {BackgroundColor3 = Color3.fromRGB(42, 42, 54)})
					tween:Play()
					
					tween.Completed:Connect(function()
						local info2 = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
						local tween2 = ts:Create(Button, info2, {BackgroundColor3 = Color3.fromRGB(36, 36, 46)})
						tween2:Play()
					end)

					if fnc then
						fnc()
					end
				end
			end)
			
			table.insert(tab_contents, {Tab.Name, Button})
		end

		function tab:Toggle(text, default, fnc)
			local on = default

			local Toggle = Instance.new("TextButton")
			local Corner = Instance.new("ImageLabel")
			local UIPadding = Instance.new("UIPadding")
			local ToggleImage = Instance.new("ImageLabel")
			local ToggleBg = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local Switch = Instance.new("Frame")
			local UICorner_2 = Instance.new("UICorner")

			Toggle.Name = "Toggle"
			Toggle.Parent = Content
			Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
			Toggle.BorderColor3 = Color3.fromRGB(46, 46, 59)
			Toggle.Position = UDim2.new(0, 0, 0.0821256042, 0)
			Toggle.Size = UDim2.new(0, 745, 0, 24)
			Toggle.Font = Enum.Font.SourceSans
			Toggle.Text = text
			Toggle.TextColor3 = Color3.fromRGB(112, 112, 145)
			Toggle.TextSize = 14.000
			Toggle.TextXAlignment = Enum.TextXAlignment.Left
			Toggle.AutoButtonColor = false
			Toggle.Visible = false

			Corner.Name = "Corner"
			Corner.Parent = Toggle
			Corner.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Corner.BackgroundTransparency = 1.000
			Corner.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Corner.BorderSizePixel = 0
			Corner.Position = UDim2.new(0.967567563, 0, 0, 0)
			Corner.Size = UDim2.new(0, 24, 0, 24)
			Corner.Image = "rbxassetid://18935468360"
			Corner.ImageColor3 = Color3.fromRGB(44, 44, 57)

			UIPadding.Parent = Toggle
			UIPadding.PaddingLeft = UDim.new(0, 5)

			ToggleImage.Name = "ToggleImage"
			ToggleImage.Parent = Toggle
			ToggleImage.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			ToggleImage.BackgroundTransparency = 1.000
			ToggleImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ToggleImage.BorderSizePixel = 0
			ToggleImage.Position = UDim2.new(0.939189255, 0, 0.125, 0)
			ToggleImage.Size = UDim2.new(0, 18, 0, 18)
			ToggleImage.Image = "rbxassetid://10470895775"
			ToggleImage.ImageColor3 = Color3.fromRGB(66, 66, 85)

			ToggleBg.Name = "ToggleBg"
			ToggleBg.Parent = Toggle
			ToggleBg.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			ToggleBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ToggleBg.BorderSizePixel = 0
			ToggleBg.Position = UDim2.new(0.870270371, 0, 0.25, 0)
			ToggleBg.Size = UDim2.new(0, 34, 0, 12)

			UICorner.CornerRadius = UDim.new(0, 30)
			UICorner.Parent = ToggleBg

			Switch.Name = "Switch"
			Switch.Parent = ToggleBg
			Switch.BackgroundColor3 = default and Color3.fromRGB(116, 131, 150) or Color3.fromRGB(116, 116, 150)
			Switch.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Switch.BorderSizePixel = 0
			Switch.Position = default and UDim2.new(0.735, 0, 0, 0) or UDim2.new(-0.0120705999, 0, 0, 0)
			Switch.Size = UDim2.new(0, 12, 0, 12)

			UICorner_2.CornerRadius = UDim.new(0, 30)
			UICorner_2.Parent = Switch

			Toggle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					on = not on

					local info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					local switchPosition = on and UDim2.new(0.735, 0, 0, 0) or UDim2.new(-0.0120705999, 0, 0, 0)
					local switchColor = on and Color3.fromRGB(116, 131, 150) or Color3.fromRGB(116, 116, 150)
					local tween = ts:Create(Switch, info, {Position = switchPosition, BackgroundColor3 = switchColor})
					tween:Play()

					local info2 = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					local tween2 = ts:Create(Toggle, info2, {BackgroundColor3 = Color3.fromRGB(42, 42, 54)})
					tween2:Play()

					tween2.Completed:Connect(function()
						local info3 = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
						local tween3 = ts:Create(Toggle, info3, {BackgroundColor3 = Color3.fromRGB(36, 36, 46)})
						tween3:Play()
					end)

					if fnc then
						fnc(on)
					end
				end
			end)

			table.insert(tab_contents, {Tab.Name, Toggle})
		end
		
		function tab:Slider(text, default, min, max, step, fnc)
			local Slider = Instance.new("TextLabel")
			local UIPadding = Instance.new("UIPadding")
			local Corner = Instance.new("ImageLabel")
			local SliderImage = Instance.new("ImageLabel")
			local SliderBg = Instance.new("Frame")
			local Drag = Instance.new("TextButton")

			Slider.Name = "Slider"
			Slider.Parent = Content
			Slider.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
			Slider.BorderColor3 = Color3.fromRGB(46, 46, 59)
			Slider.Position = UDim2.new(0, 0, 0.164251208, 0)
			Slider.Size = UDim2.new(0, 745, 0, 33)
			Slider.Font = Enum.Font.SourceSans
			Slider.Text = text
			Slider.TextColor3 = Color3.fromRGB(112, 112, 145)
			Slider.TextSize = 14.000
			Slider.TextXAlignment = Enum.TextXAlignment.Left
			Slider.Visible = false

			UIPadding.Parent = Slider
			UIPadding.PaddingBottom = UDim.new(0, 18)
			UIPadding.PaddingLeft = UDim.new(0, 5)

			Corner.Name = "Corner"
			Corner.Parent = Slider
			Corner.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Corner.BackgroundTransparency = 1.000
			Corner.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Corner.BorderSizePixel = 0
			Corner.Position = UDim2.new(0.967567563, 0, 0.583333313, 0)
			Corner.Size = UDim2.new(0, 24, 0, 24)
			Corner.Image = "rbxassetid://18935468360"
			Corner.ImageColor3 = Color3.fromRGB(44, 44, 57)

			SliderImage.Name = "SliderImage"
			SliderImage.Parent = Slider
			SliderImage.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			SliderImage.BackgroundTransparency = 1.000
			SliderImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
			SliderImage.BorderSizePixel = 0
			SliderImage.Position = UDim2.new(0.939189196, 0, 0.608332813, 0)
			SliderImage.Size = UDim2.new(0, 18, 0, 14)
			SliderImage.Image = "rbxassetid://10470895631"
			SliderImage.ImageColor3 = Color3.fromRGB(66, 66, 85)

			SliderBg.Name = "SliderBg"
			SliderBg.Parent = Slider
			SliderBg.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			SliderBg.BackgroundTransparency = 0.600
			SliderBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
			SliderBg.BorderSizePixel = 0
			SliderBg.Position = UDim2.new(0.0081081083, 0, 1.27692354, 0)
			SliderBg.Size = UDim2.new(0, 672, 0, 11)

			Drag.Name = "Drag"
			Drag.Parent = SliderBg
			Drag.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Drag.BorderSizePixel = 0
			Drag.Position = UDim2.new(-0.000581787666, 0, -0.0227272734, 0)
			Drag.Size = UDim2.new(0, 11, 0, 11)
			Drag.Font = Enum.Font.SourceSans
			Drag.Text = ""
			Drag.TextColor3 = Color3.fromRGB(0, 0, 0)
			Drag.TextSize = 14.000
			Drag.AutoButtonColor = false

			local isDragging = false

			local function updateSliderPosition(mousePosX)
				local scrollBg_pos = SliderBg.AbsolutePosition.X
				local scrollBg_size = SliderBg.AbsoluteSize.X
				local size = math.clamp((mousePosX - scrollBg_pos) / scrollBg_size, 0, 1)
				local size_drag = math.clamp((mousePosX - scrollBg_pos) / scrollBg_size, 0.0225, 1)

				Drag.Position = UDim2.new(0,0,0,0)
				Drag.Size = UDim2.new(size_drag, 0, 1, 0)

				local value = min + (max - min) * size
				if fnc then
					fnc(math.floor(value / step) * step)
				end
			end

			local function setDefaultPosition()
				local normalizedValue = (default - min) / (max - min)
				local drag_half_size = Drag.AbsoluteSize.X / 2
				local size_drag = math.clamp(normalizedValue, 0.0225, 1)
				Drag.Position = UDim2.new(0,0,0,0)
				Drag.Size = UDim2.new(size_drag, 0, 1, 0)
			end

			Drag.MouseButton1Down:Connect(function()
				isDragging = true
			end)

			runService.RenderStepped:Connect(function()
				if isDragging then
					local mousePos = userInputService:GetMouseLocation().X - slacklibv2.AbsolutePosition.X
					updateSliderPosition(mousePos)
				end
			end)

			userInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					isDragging = false
				end
			end)

			setDefaultPosition()
			table.insert(tab_contents, {Tab.Name, Slider})
		end
		
		function tab:Colorpicker(text, fnc)
			local ColorPicker = Instance.new("TextButton")
			local Corner = Instance.new("ImageLabel")
			local UIPadding = Instance.new("UIPadding")
			local ColorImage = Instance.new("ImageLabel")
			local Preview = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")

			ColorPicker.Name = "ColorPicker"
			ColorPicker.Parent = Content
			ColorPicker.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
			ColorPicker.BorderColor3 = Color3.fromRGB(46, 46, 59)
			ColorPicker.Position = UDim2.new(0, 0, 0.0821256042, 0)
			ColorPicker.Size = UDim2.new(0, 745, 0, 24)
			ColorPicker.Font = Enum.Font.SourceSans
			ColorPicker.Text = text
			ColorPicker.TextColor3 = Color3.fromRGB(112, 112, 145)
			ColorPicker.TextSize = 14.000
			ColorPicker.TextXAlignment = Enum.TextXAlignment.Left
			ColorPicker.Visible = false
			ColorPicker.AutoButtonColor = false

			Corner.Name = "Corner"
			Corner.Parent = ColorPicker
			Corner.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			Corner.BackgroundTransparency = 1.000
			Corner.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Corner.BorderSizePixel = 0
			Corner.Position = UDim2.new(0.967567563, 0, 0, 0)
			Corner.Size = UDim2.new(0, 24, 0, 24)
			Corner.Image = "rbxassetid://18935468360"
			Corner.ImageColor3 = Color3.fromRGB(44, 44, 57)

			UIPadding.Parent = ColorPicker
			UIPadding.PaddingLeft = UDim.new(0, 5)

			ColorImage.Name = "ColorImage"
			ColorImage.Parent = ColorPicker
			ColorImage.BackgroundColor3 = Color3.fromRGB(86, 86, 111)
			ColorImage.BackgroundTransparency = 1.000
			ColorImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ColorImage.BorderSizePixel = 0
			ColorImage.Position = UDim2.new(0.943243265, 0, 0.25, 0)
			ColorImage.Size = UDim2.new(0, 12, 0, 12)
			ColorImage.Image = "rbxassetid://10470895932"
			ColorImage.ImageColor3 = Color3.fromRGB(66, 66, 85)

			Preview.Name = "Preview"
			Preview.Parent = ColorPicker
			Preview.BackgroundColor3 = Color3.fromRGB(0,0,0)
			Preview.BorderColor3 = Color3.fromRGB(66, 66, 66)
			Preview.Position = UDim2.new(0.891891897, 0, 0.125, 0)
			Preview.Size = UDim2.new(0, 18, 0, 18)

			UICorner.CornerRadius = UDim.new(0, 16)
			UICorner.Parent = Preview
			
			local last_color = Preview.BackgroundColor3
			
			ColorPicker.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					local tween = ts:Create(ColorPicker, info, {BackgroundColor3 = Color3.fromRGB(42, 42, 54)})
					tween:Play()

					tween.Completed:Connect(function()
						local info2 = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
						local tween2 = ts:Create(ColorPicker, info2, {BackgroundColor3 = Color3.fromRGB(36, 36, 46)})
						tween2:Play()
					end)
				end
			end)
			
			ColorPicker.MouseButton1Down:Connect(function()
				color_picker_associated_with = ColorPicker
				hue = 0
				colorpicker_x = 1
				colorpicker_y = 0
				
				ColorPickerFrame.Visible = true
				TextLabel.Text = text
			end)

			runService.RenderStepped:Connect(function()
				if not colorsAreEqual(Preview.BackgroundColor3,last_color) then
					fnc(Preview.BackgroundColor3)
					
					last_color = Preview.BackgroundColor3
				end
			end)
			
			table.insert(tab_contents, {Tab.Name, ColorPicker})
		end

		return tab
	end
	
	return window
end

return lib
