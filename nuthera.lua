--==================================================
-- COMPONENT BASE
--==================================================

local Elements = {}

local function BaseDestroy(object)
	if object.Destroyed then
		return
	end

	object.Destroyed = true

	if object.Maid then
		object.Maid:DoCleaning()
	end

	UnregisterOption(object)

	if object.Owner and typeof(object.Owner._Elements) == "table" then
		for index, entry in ipairs(object.Owner._Elements) do
			if entry == object then
				table.remove(object.Owner._Elements, index)
				break
			end
		end
	end

	if object.Element then
		pcall(function()
			object.Element:Destroy()
		end)
	end
end

local function AttachChanged(object)
	object._Changed = {}

	function object:OnChanged(callback)
		if typeof(callback) == "function" then
			table.insert(self._Changed, callback)
		end
		return self
	end

	function object:_FireChanged(...)
		for _, callback in ipairs(self._Changed) do
			SafeCallback(callback, ...)
		end

		SafeCallback(self.Callback, ...)
	end

	function object:GetValue()
		return self.Value
	end
end

local function CreateBase(parent, config)
	config = config or {}

	local maid = Maid.new()

	local element = New("Frame", {
		Name = config.Name or "NFElement",
		BackgroundColor3 = T("Element"),
		BackgroundTransparency = config.Transparent and 1 or 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = config.LayoutOrder or 1,
		ClipsDescendants = false,
		Parent = parent,
	})

	Corner(element, 10)

	if not config.Transparent then
		Stroke(element, "Border", 1, 0.12)
		RegisterTheme(element, { BackgroundColor3 = "Element" })
	end

	New("UISizeConstraint", {
		Parent = element,
		MinSize = Vector2.new(0, config.MinHeight or 56),
	})

	Padding(element, 12, 12, 14, 14)
	ListLayout(element, 8)

	local row

	if config.Interactive then
		row = New("TextButton", {
			Name = "Row",
			Parent = element,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		})
	else
		row = New("Frame", {
			Name = "Row",
			Parent = element,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		})
	end

	local rowLayout = New("UIListLayout", {
		Parent = row,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	})

	local rightWidth = config.RightWidth or 0
	local reserved = rightWidth > 0 and (rightWidth + 10) or 0

	local textHolder = New("Frame", {
		Name = "Text",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -reserved, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	})

	ListLayout(textHolder, 4)
	local accessory = New("Frame", {
		Name = "Accessory", Parent = row, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(rightWidth, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2, Visible = rightWidth > 0,
	})
	ListLayout(accessory, 10, Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center)
	local function UpdateRowLayout()
		local width = row.AbsoluteSize.X
		local stacked = rightWidth >= 80 and width > 0 and width < rightWidth + 180
		rowLayout.FillDirection = stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
		textHolder.Size = UDim2.new(1, stacked and 0 or -reserved, 0, 0)
		accessory.Size = stacked and UDim2.new(1, 0, 0, 0) or UDim2.fromOffset(rightWidth, 0)
		element:SetAttribute("StackedControls", stacked)
	end
	maid:Give(row:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateRowLayout))
	task.defer(function() if row.Parent then UpdateRowLayout() end end)

	local titleText = tostring(config.Title or "")

	local title = New("TextLabel", {
		Name = "Title",
		Parent = textHolder,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT_MEDIUM,
		Text = titleText,
		TextColor3 = T("Text"),
		TextSize = config.TitleSize or 15,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.08,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 1,
	})

	RegisterTheme(title, { TextColor3 = "Text" })

	local descriptionText = config.Description and tostring(config.Description) or ""

	local description = New("TextLabel", {
		Name = "Description",
		Parent = textHolder,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		Text = descriptionText,
		TextColor3 = T("SubText"),
		TextSize = config.DescriptionSize or 13,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 2,
		Visible = descriptionText ~= "",
	})

	RegisterTheme(description, { TextColor3 = function(theme) return theme.SubText:Lerp(theme.Text, .12) end })

	local base = {
		Maid = maid,
		Element = element,
		Row = row,
		Accessory = accessory,
		TextHolder = textHolder,
		TitleLabel = title,
		DescriptionLabel = description,
		InteractiveEnabled = true,
	}

	function base:SetInteractiveEnabled(state)
		self.InteractiveEnabled = state == true
		Tween(element, {BackgroundColor3 = T("Element")}, SPEED.Fast)
		pcall(function()
			row.Interactable = self.InteractiveEnabled
		end)
	end

	maid:Give(element)

	if config.Interactive then
		maid:Give(row.MouseEnter:Connect(function()
			if not base.InteractiveEnabled then
				return
			end
			Tween(element, { BackgroundColor3 = T("ElementHover") }, SPEED.Fast)
		end))

		maid:Give(row.MouseLeave:Connect(function()
			if not base.InteractiveEnabled then
				return
			end
			Tween(element, { BackgroundColor3 = T("Element") }, SPEED.Fast)
		end))

		maid:Give(row.MouseButton1Down:Connect(function()
			if not base.InteractiveEnabled then
				return
			end
			Tween(element, { BackgroundColor3 = T("Border") }, SPEED.Fast)
		end))

		maid:Give(row.MouseButton1Up:Connect(function()
			if not base.InteractiveEnabled then
				return
			end
			Tween(element, { BackgroundColor3 = T("ElementHover") }, SPEED.Fast)
		end))
	end

	return base
end

local function AttachBaseMethods(object, base, owner)
	object.Maid = base.Maid
	object.Element = base.Element
	object.Row = base.Row
	object.Owner = owner

	function object:SetTitle(text)
		base.TitleLabel.Text = tostring(text or "")
		return self
	end

	function object:SetDescription(text)
		local value = tostring(text or "")
		base.DescriptionLabel.Text = value
		base.DescriptionLabel.Visible = value ~= ""
		return self
	end

	function object:SetVisible(state)
		base.Element.Visible = state and true or false
		return self
	end

	function object:AddCleanup(item)
		return self.Maid:Give(item)
	end

	object.GiveTask = object.AddCleanup

	function object:Destroy()
		BaseDestroy(self)
	end

	if owner and typeof(owner._Elements) == "table" then
		table.insert(owner._Elements, object)
	end

	return object
end

--==================================================
-- LABEL
--==================================================

function Elements.Label(parent, config, owner)
	if typeof(config) == "string" then
		config = { Title = config }
	end

	config = config or {}

	local base = CreateBase(parent, {
		Name = "NFLabel",
		Title = config.Title or config.Text or "Label",
		Description = config.Description,
		MinHeight = 36,
		TitleSize = 15,
	})

	local object = { Type = "Label", Value = tostring(config.Title or config.Text or "") }

	AttachBaseMethods(object, base, owner)

	function object:UpdateLabel(text)
		self.Value = tostring(text or "")
		return self:SetTitle(text)
	end

	object.SetText = object.UpdateLabel
	object.Set = object.UpdateLabel

	return object
end

--==================================================
-- PARAGRAPH
--==================================================

function Elements.Paragraph(parent, config, owner)
	config = config or {}

	local base = CreateBase(parent, {
		Name = "NFParagraph",
		Title = config.Title or "Paragraph",
		Description = config.Content or config.Description or "",
		MinHeight = 48,
		TitleSize = 15,
		DescriptionSize = 13,
	})

	local object = { Type = "Paragraph" }

	AttachBaseMethods(object, base, owner)

	function object:SetContent(text)
		return self:SetDescription(text)
	end

	object.UpdateParagraph = object.SetContent

	return object
end

--==================================================
-- BUTTON
--==================================================

function Elements.Button(parent, config, owner)
	config = config or {}

	local buttonLabelText = config.ButtonText or (config.Icon == nil and typeof(config.Text) == "string" and config.Text) or nil
	local hasButtonPill = buttonLabelText ~= nil and tostring(buttonLabelText) ~= ""
	local rightActionWidth = hasButtonPill and Clamp(#tostring(buttonLabelText) * 7 + 24, 72, 160) or 36

	local base = CreateBase(parent, {
		Name = "NFButton",
		Title = config.Title or "Button",
		Description = config.Description,
		Interactive = true,
		RightWidth = rightActionWidth,
	})

	local action = New("Frame", {
		Name = "Action",
		Parent = base.Accessory,
		BackgroundColor3 = T("ElementHover"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 2,
	})
	Corner(action, 8)
	local actionStroke = Stroke(action, "Border", 1, 0.25)
	RegisterTheme(action, { BackgroundColor3 = "ElementHover" })

	local iconParts = nil
	local normalIconVisual = nil
	local actionLabel = nil

	if hasButtonPill then
		actionLabel = New("TextLabel", {
			Name = "ButtonLabel",
			Parent = action,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.fromOffset(8, 0),
			Font = FONT_MEDIUM,
			Text = tostring(buttonLabelText),
			TextColor3 = T("Text"),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = action.ZIndex + 1,
		})
		normalIconVisual = actionLabel
		RegisterTheme(actionLabel, { TextColor3 = "Text" })
	else
		local rawIcon = config.Icon
		local iconKey = rawIcon and tostring(rawIcon):lower()
		local resolvedKind = "chevron-right"

		if rawIcon ~= nil then
			if ICONS[iconKey] then
				resolvedKind = ICONS[iconKey]
			elseif typeof(rawIcon) == "string" and (rawIcon:sub(1, 13) == "rbxassetid://" or tonumber(rawIcon) ~= nil) then
				resolvedKind = rawIcon
			else
				resolvedKind = ResolveTabIcon(rawIcon, rawIcon)
			end
		end

		local iconHolder
		iconHolder, iconParts = CreateLineGlyph(action, resolvedKind, 15, action.ZIndex + 1)
		normalIconVisual = iconHolder
		iconHolder.AnchorPoint = Vector2.new(0.5, 0.5)
		iconHolder.Position = UDim2.fromScale(0.5, 0.5)
		RegisterGlyphTheme(iconParts, "SubText")
	end

	local loadingIcon, loadingIconParts = CreateLineGlyph(action, "loading", 15, action.ZIndex + 2)
	loadingIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingIcon.Position = UDim2.fromScale(0.5, 0.5)
	loadingIcon.Visible = false
	RegisterGlyphTheme(loadingIconParts, "Accent")

	local object = {
		Type = "Button",
		Callback = config.Callback,
		Value = false,
		Disabled = config.Disabled == true,
		Loading = config.Loading == true,
		LoadingText = tostring(config.LoadingText or "Loading..."),
	}

	AttachBaseMethods(object, base, owner)

	object._IdleTitle = tostring(config.Title or "Button")
	local BaseSetTitle = object.SetTitle
	local loadingConnection
	local feedbackSerial = 0
	base.Maid:Give(function()
		if loadingConnection then loadingConnection:Disconnect(); loadingConnection = nil end
	end)

	function object:SetTitle(text)
		self._IdleTitle = tostring(text or "")
		if not self.Loading then
			BaseSetTitle(self, self._IdleTitle)
		end
		return self
	end

	local function RenderState()
		feedbackSerial += 1
		local blocked = object.Disabled or object.Loading
		base:SetInteractiveEnabled(not blocked)

		base.TitleLabel.Text = object.Loading and object.LoadingText or object._IdleTitle
		base.TitleLabel.TextTransparency = object.Disabled and 0.3 or 0
		base.DescriptionLabel.TextTransparency = object.Disabled and 0.35 or 0
		base.Element.BackgroundTransparency = object.Disabled and 0.2 or 0
		action.BackgroundTransparency = object.Disabled and 0.55 or 0
		if actionLabel then actionLabel.TextTransparency = object.Disabled and .35 or 0 end

		if normalIconVisual then
			normalIconVisual.Visible = not object.Loading
		end
		loadingIcon.Visible = object.Loading
		if object.Loading and not loadingConnection then
			loadingConnection = RunService.Heartbeat:Connect(function(dt)
				if Settings.Animations and loadingIcon.Parent then
					loadingIcon.Rotation = (loadingIcon.Rotation + dt * 180) % 360
				end
			end)
		elseif not object.Loading and loadingConnection then
			loadingConnection:Disconnect()
			loadingConnection = nil
			loadingIcon.Rotation = 0
		end
		Tween(action, {BackgroundColor3 = T("ElementHover")}, SPEED.Fast)
		Tween(actionStroke, {Color = T("Border"), Transparency = object.Disabled and .6 or .25}, SPEED.Fast)

		if object.Loading then
			SetGlyphColor(loadingIconParts, T("Accent"))
		elseif iconParts then
			SetGlyphColor(iconParts, object.Disabled and T("Border") or T("SubText"))
		end
	end

	function object:SetDisabled(state)
		self.Disabled = state == true
		RenderState()
		return self
	end

	function object:IsDisabled()
		return self.Disabled == true
	end

	function object:SetLoading(state, text)
		self.Loading = state == true
		if text ~= nil then
			self.LoadingText = tostring(text)
		end
		RenderState()
		return self
	end

	function object:IsLoading()
		return self.Loading == true
	end

	local function TriggerButtonPress()
		if object.Disabled or object.Loading then
			return
		end

		feedbackSerial += 1
		local serial = feedbackSerial
		Tween(action, { BackgroundColor3 = T("Accent") }, 0.06, Enum.EasingStyle.Quad)
		if actionLabel then
			Tween(actionLabel, { TextColor3 = T("Background") }, 0.06, Enum.EasingStyle.Quad)
		elseif iconParts then
			SetGlyphColor(iconParts, T("Background"))
		end

		task.delay(0.10, function()
			if action.Parent and feedbackSerial == serial and not object.Disabled and not object.Loading then
				Tween(action, { BackgroundColor3 = T("ElementHover") }, 0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				if actionLabel then
					Tween(actionLabel, { TextColor3 = T("Text") }, 0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				elseif iconParts then
					SetGlyphColor(iconParts, T("SubText"))
				end
			end
		end)

		SafeCallback(object.Callback)
	end

	base.Maid:Give(base.Row.MouseButton1Click:Connect(TriggerButtonPress))
	base.Maid:Give(base.Row.MouseEnter:Connect(function()
		if not object.Disabled and not object.Loading then
			Tween(actionStroke, {Color = T("Accent"), Transparency = .15}, SPEED.Fast)
		end
	end))
	base.Maid:Give(base.Row.MouseLeave:Connect(function()
		Tween(actionStroke, {Color = T("Border"), Transparency = object.Disabled and .6 or .25}, SPEED.Fast)
	end))

	function object:UpdateButton(text)
		return self:SetTitle(text)
	end

	function object:SetCallback(callback)
		self.Callback = callback
		return self
	end

	function object:Fire()
		if self.Disabled or self.Loading then
			return self
		end
		SafeCallback(self.Callback)
		return self
	end
	OnThemeChanged(function() if base.Element.Parent then RenderState() end end)
	RenderState()

	return object
end

function Elements.Toggle(parent, id, config, owner)
	config = config or {}

	local base = CreateBase(parent, {
		Name = "NFToggle",
		Title = config.Title or "Toggle",
		Description = config.Description,
		Interactive = true,
		RightWidth = 44,
	})

	local value = config.Default == true

	local track = New("Frame", {
		Name = "Track",
		Parent = base.Accessory,
		BackgroundColor3 = value and T("Accent") or T("Border"),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(44, 22),
		LayoutOrder = 2,
	})

	Corner(track, 11)

	local knob = New("Frame", {
		Name = "Knob",
		Parent = track,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, value and 25 or 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = value and T("Background") or T("SubText"),
		BorderSizePixel = 0,
	})

	Corner(knob, 8)

	local object = {
		Type = "Toggle",
		Value = value,
		Callback = config.Callback,
		Save = config.Save ~= false,
	}

	AttachChanged(object)
	AttachBaseMethods(object, base, owner)

	RegisterTheme(track, {
		BackgroundColor3 = function(theme)
			return object.Value and theme.Accent or theme.Border
		end,
	})

	RegisterTheme(knob, {
		BackgroundColor3 = function(theme)
			return object.Value and theme.Background or theme.SubText
		end,
	})

	local function Render()
		local targetPos = object.Value and 25 or 3
		Tween(track, { BackgroundColor3 = object.Value and T("Accent") or T("Border") }, SPEED.Fast)
		Tween(knob, {
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = object.Value and T("Background") or T("SubText"),
			Position = UDim2.new(0, targetPos, 0.5, 0),
		}, .16, Enum.EasingStyle.Quart)
	end

	function object:SetValue(newValue, silent)
		local state = newValue == true

		if typeof(newValue) == "string" then
			state = newValue == "true"
		end

		self.Value = state
		Render()

		if not silent then
			self:_FireChanged(state)
		end

		return self
	end

	object.Set = object.SetValue

	function object:Toggle()
		return self:SetValue(not self.Value)
	end

	base.Maid:Give(base.Row.MouseButton1Click:Connect(function()
		object:SetValue(not object.Value)
	end))

	if id then
		RegisterOption(id, object)
	end

	if value and config.FireOnInit ~= false then
		task.defer(function()
			if not object.Destroyed then
				object:_FireChanged(true)
			end
		end)
	end

	return object
end

--==================================================
-- SLIDER
--==================================================

function Elements.Slider(parent, id, config, owner)
	config = config or {}

	local minimum = tonumber(config.Min) or 0
	local maximum = tonumber(config.Max) or 100

	if minimum > maximum then
		minimum, maximum = maximum, minimum
	end

	local rounding = math.floor(tonumber(config.Rounding) or 0)
	local suffix = config.Suffix and tostring(config.Suffix) or ""

	local base = CreateBase(parent, {
		Name = "NFSlider",
		Title = config.Title or "Slider",
		Description = config.Description,
		RightWidth = 64,
		MinHeight = 56,
	})

	local valueLabel = New("TextLabel", {
		Name = "Value",
		Parent = base.Accessory,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(64, 20),
		Font = FONT_MEDIUM,
		Text = "0",
		TextColor3 = T("Text"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = 2,
	})

	RegisterTheme(valueLabel, { TextColor3 = "Text" })

	local barArea = New("Frame", {
		Name = "BarArea",
		Parent = base.Element,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 2,
	})

	local track = New("Frame", {
		Name = "Track",
		Parent = barArea,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = T("Border"),
		BorderSizePixel = 0,
	})

	Corner(track, 3)
	RegisterTheme(track, { BackgroundColor3 = "Border" })

	local fill = New("Frame", {
		Name = "Fill",
		Parent = track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = T("Accent"),
		BorderSizePixel = 0,
	})

	Corner(fill, 3)
	RegisterTheme(fill, { BackgroundColor3 = "Accent" })

	local knob = New("Frame", {
		Name = "Knob",
		Parent = track,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = T("Accent"),
		BorderSizePixel = 0,
		ZIndex = 2,
	})

	Corner(knob, 7)
	Stroke(knob, "Background", 2)
	RegisterTheme(knob, { BackgroundColor3 = "Accent" })

	local object = {
		Type = "Slider",
		Value = minimum,
		Min = minimum,
		Max = maximum,
		Rounding = rounding,
		Callback = config.Callback,
		Save = config.Save ~= false,
	}

	AttachChanged(object)
	AttachBaseMethods(object, base, owner)

	local function FormatValue(value)
		if rounding <= 0 then
			return tostring(math.floor(value + 0.5)) .. suffix
		end
		return string.format("%." .. rounding .. "f", value) .. suffix
	end

	local function Render(animate)
		local range = maximum - minimum
		local alpha = range == 0 and 0 or (object.Value - minimum) / range
		alpha = Clamp(alpha, 0, 1)

		valueLabel.Text = FormatValue(object.Value)

		if animate then
			Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, SPEED.Fast, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			Tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, SPEED.Fast, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		else
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		end
	end

	function object:SetValue(newValue, silent)
		local number = tonumber(newValue)

		if number == nil then
			return self
		end

		number = Round(Clamp(number, minimum, maximum), rounding)

		local changed = number ~= self.Value
		self.Value = number

		Render(true)

		if not silent and changed then
			self:_FireChanged(number)
		end

		return self
	end

	object.Set = object.SetValue

	function object:SetMin(newMin)
		minimum = tonumber(newMin) or minimum
		self.Min = minimum
		return self:SetValue(self.Value, true)
	end

	function object:SetMax(newMax)
		maximum = tonumber(newMax) or maximum
		self.Max = maximum
		return self:SetValue(self.Value, true)
	end

	BindSlide(barArea, base.Maid, function(position)
		local absolutePosition = track.AbsolutePosition.X
		local absoluteSize = math.max(track.AbsoluteSize.X, 1)
		local alpha = Clamp((position.X - absolutePosition) / absoluteSize, 0, 1)

		object:SetValue(minimum + (maximum - minimum) * alpha)
	end)

	base.Maid:Give(barArea.MouseEnter:Connect(function()
		Tween(knob, { Size = UDim2.fromOffset(18, 18) }, SPEED.Fast)
	end))

	base.Maid:Give(barArea.MouseLeave:Connect(function()
		Tween(knob, { Size = UDim2.fromOffset(14, 14) }, SPEED.Fast)
	end))

	object.Value = Round(Clamp(tonumber(config.Default) or minimum, minimum, maximum), rounding)
	Render(false)

	if id then
		RegisterOption(id, object)
	end

	return object
end

--==================================================
-- INPUT / TEXTBOX
--==================================================

function Elements.Input(parent, id, config, owner)
	config = config or {}

	local viewport = GetViewport()
	local boxWidth = viewport.X < 620 and 120 or 150

	local base = CreateBase(parent, {
		Name = "NFInput",
		Title = config.Title or "Input",
		Description = config.Description,
		RightWidth = boxWidth,
	})

	local holder = New("Frame", {
		Name = "InputHolder",
		Parent = base.Accessory,
		BackgroundColor3 = T("Background"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 2,
	})

	Corner(holder, 6)
	local focusStroke = Stroke(holder, "Border")
	RegisterTheme(holder, { BackgroundColor3 = "Background" })

	local textBox = New("TextBox", {
		Name = "Box",
		Parent = holder,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		Font = FONT,
		Text = tostring(config.Default or ""),
		PlaceholderText = tostring(config.Placeholder or ""),
		TextColor3 = T("Text"),
		PlaceholderColor3 = T("SubText"),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
	})

	RegisterTheme(textBox, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

	local object = {
		Type = "Input",
		Value = tostring(config.Default or ""),
		Callback = config.Callback,
		Save = config.Save ~= false,
		Numeric = config.Numeric == true,
		Finished = config.Finished == true,
	}

	AttachChanged(object)
	AttachBaseMethods(object, base, owner)

	local updating = false

	local function Commit(text)
		if updating then
			return
		end

		object.Value = tostring(text)
		object:_FireChanged(object.Value)
	end

	function object:SetValue(newValue, silent)
		updating = true
		local text = tostring(newValue == nil and "" or newValue)
		self.Value = text
		textBox.Text = text
		updating = false

		if not silent then
			self:_FireChanged(text)
		end

		return self
	end

	object.Set = object.SetValue

	function object:Clear()
		return self:SetValue("")
	end

	base.Maid:Give(textBox:GetPropertyChangedSignal("Text"):Connect(function()
		if object.Numeric then
			local filtered = string.gsub(textBox.Text, "[^%d%.%-]", "")

			if filtered ~= textBox.Text then
				updating = true
				textBox.Text = filtered
				updating = false
			end
		end

		if not object.Finished then
			Commit(textBox.Text)
		end
	end))

	base.Maid:Give(textBox.Focused:Connect(function()
		Tween(holder, { BackgroundColor3 = T("ElementHover") }, SPEED.Fast)
		Tween(focusStroke, {Color = T("Accent")}, SPEED.Fast)
	end))

	base.Maid:Give(textBox.FocusLost:Connect(function()
		Tween(holder, { BackgroundColor3 = T("Background") }, SPEED.Fast)
		Tween(focusStroke, {Color = T("Border")}, SPEED.Fast)

		if object.Finished then
			Commit(textBox.Text)
		end
	end))

	if id then
		RegisterOption(id, object)
	end

	return object
end

--==================================================
-- DROPDOWN / MULTI DROPDOWN
--==================================================

local DROPDOWN_MAX_HEIGHT = 156

function Elements.Dropdown(parent, id, config, owner)
	config = config or {}

	local multi = config.Multi == true
	local values = config.Values or config.Options or config.List or {}
	local searchThreshold = tonumber(config.SearchThreshold) or 6
	local searchable = config.Searchable == true
		or (config.Searchable ~= false and #values >= searchThreshold)

	local base = CreateBase(parent, {
		Name = "NFDropdown",
		Title = config.Title or "Dropdown",
		Description = config.Description,
		Interactive = true,
		RightWidth = 148,
	})

	local display = New("TextLabel", {
		Name = "Display",
		Parent = base.Accessory,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -26, 0, 32),
		Font = FONT,
		Text = "None",
		TextColor3 = T("Text"),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
	})

	RegisterTheme(display, { TextColor3 = "Text" })

	local arrow, arrowParts = CreateLineGlyph(base.Accessory, "chevron-down", 16, base.Row.ZIndex + 1)
	arrow.Name = "Arrow"
	arrow.LayoutOrder = 3
	RegisterGlyphTheme(arrowParts, "SubText")

	local holder = New("Frame", {
		Name = "ListHolder",
		Parent = base.Element,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 2,
	})

	local scroller = New("ScrollingFrame", {
		Name = "Options",
		Parent = holder,
		BackgroundColor3 = T("Background"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T("Border"),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
	})

	Corner(scroller, 6)
	Stroke(scroller, "Border")
	RegisterTheme(scroller, { BackgroundColor3 = "Background", ScrollBarImageColor3 = "Border" })
	Padding(scroller, 6, 6, 6, 6)

	local optionLayout = ListLayout(scroller, 4)

	local object = {
		Type = "Dropdown",
		Multi = multi,
		Searchable = searchable,
		Values = values,
		Value = multi and {} or nil,
		Callback = config.Callback,
		Save = config.Save ~= false,
	}

	AttachChanged(object)
	AttachBaseMethods(object, base, owner)

	local listMaid = Maid.new()
	base.Maid:Give(listMaid)

	local buttons = {}
	local expanded = false
	local searchBox = nil

	if searchable then
		searchBox = New("TextBox", {
			Name = "Search",
			Parent = scroller,
			BackgroundColor3 = T("Element"),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = FONT,
			PlaceholderText = tostring(config.SearchPlaceholder or "Search options..."),
			PlaceholderColor3 = T("SubText"),
			Text = "",
			TextColor3 = T("Text"),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, IsTouchDevice() and 38 or 34),
			LayoutOrder = 0,
		})
		Corner(searchBox, 7)
		Stroke(searchBox, "Border", 1, 0.15)
		Padding(searchBox, 0, 0, 10, 10)
		RegisterTheme(searchBox, {
			BackgroundColor3 = "Element",
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		})
	end

	local function DisplayText()
		if multi then
			local selected = {}

			for _, value in ipairs(object.Values) do
				if object.Value[tostring(value)] then
					table.insert(selected, tostring(value))
				end
			end

			if #selected == 0 then
				return "None"
			end

			return table.concat(selected, ", ")
		end

		if object.Value == nil then
			return "None"
		end

		return tostring(object.Value)
	end

	local function Render()
		display.Text = DisplayText()

		for text, entry in pairs(buttons) do
			local selected = false

			if multi then
				selected = object.Value[text] == true
			else
				selected = object.Value ~= nil and tostring(object.Value) == text
			end

			entry.Check.Visible = selected
			entry.Label.TextColor3 = selected and T("Text") or T("SubText")
			Tween(entry.Button, {
				BackgroundColor3 = selected and T("ElementHover") or T("Element"),
			}, SPEED.Fast)
		end
	end

	local SetExpanded

	local function Select(text)
		if multi then
			object.Value[text] = not object.Value[text]

			if object.Value[text] == false then
				object.Value[text] = nil
			end

			Render()
			object:_FireChanged(object.Value)
		else
			local raw = text

			for _, value in ipairs(object.Values) do
				if tostring(value) == text then
					raw = value
					break
				end
			end

			object.Value = raw
			Render()
			SetExpanded(false)
			object:_FireChanged(raw)
		end
	end

	local function ApplySearchFilter()
		local query = searchBox and tostring(searchBox.Text):lower() or ""

		for text, entry in pairs(buttons) do
			entry.Button.Visible = query == ""
				or string.find(text:lower(), query, 1, true) ~= nil
		end

		if expanded then
			task.defer(function()
				if expanded and holder.Parent then
					SetExpanded(true)
				end
			end)
		end
	end

	if searchBox then
		base.Maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(ApplySearchFilter))
	end

	local function BuildOptions()
		listMaid:DoCleaning()
		buttons = {}

		for _, child in ipairs(scroller:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for index, value in ipairs(object.Values) do
			local text = tostring(value)

			local button = New("TextButton", {
				Name = "Option",
				Parent = scroller,
				BackgroundColor3 = T("Element"),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, IsTouchDevice() and 44 or 38),
				Font = FONT,
				Text = "",
				LayoutOrder = index,
			})

			Corner(button, 6)

			local function IsSelected()
				if multi then
					return object.Value[text] == true
				end

				return object.Value ~= nil and tostring(object.Value) == text
			end

			RegisterTheme(button, {
				BackgroundColor3 = function(theme)
					return IsSelected() and theme.ElementHover or theme.Element
				end,
			})

			local label = New("TextLabel", {
				Parent = button,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -36, 1, 0),
				Font = FONT,
				Text = text,
				TextColor3 = T("SubText"),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				RichText = false,
			})

			RegisterTheme(label, {
				TextColor3 = function(theme)
					return IsSelected() and theme.Text or theme.SubText
				end,
			})

			local check = New("TextLabel", {
				Parent = button,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				Font = FONT_BOLD,
				Text = GLYPH.Check,
				TextColor3 = T("Accent"),
				TextSize = 14,
				Visible = false,
			})

			RegisterTheme(check, { TextColor3 = "Accent" })

			buttons[text] = { Button = button, Label = label, Check = check }

			listMaid:Give(button.MouseButton1Click:Connect(function()
				Select(text)
			end))

			listMaid:Give(button.MouseEnter:Connect(function()
				Tween(button, { BackgroundColor3 = T("ElementHover") }, SPEED.Fast)
			end))

			listMaid:Give(button.MouseLeave:Connect(function()
				Tween(button, {
					BackgroundColor3 = IsSelected() and T("ElementHover") or T("Element"),
				}, SPEED.Fast)
			end))
		end

		ApplySearchFilter()
		Render()
	end

	SetExpanded = function(state)
		expanded = state and true or false

		if expanded then
			holder.Visible = true

			local contentHeight = optionLayout.AbsoluteContentSize.Y + 12
			local target = math.min(math.max(contentHeight, 34), DROPDOWN_MAX_HEIGHT)

			Tween(holder, { Size = UDim2.new(1, 0, 0, target) }, SPEED.Normal, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			Tween(arrow, { Rotation = 180 }, SPEED.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			Tween(holder, { Size = UDim2.new(1, 0, 0, 0) }, SPEED.Normal, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
			Tween(arrow, { Rotation = 0 }, SPEED.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

			task.delay(Settings.Animations and (SPEED.Normal + 0.02) or 0, function()
				if not expanded and holder.Parent then
					holder.Visible = false
				end
			end)
		end
	end

	function object:SetValue(newValue, silent)
		if multi then
			local map = {}

			if typeof(newValue) == "table" then
				local isArray = #newValue > 0

				if isArray then
					for _, entry in ipairs(newValue) do
						map[tostring(entry)] = true
					end
				else
					for key, state in pairs(newValue) do
						if state then
							map[tostring(key)] = true
						end
					end
				end
			elseif newValue ~= nil then
				map[tostring(newValue)] = true
			end

			local filtered = {}

			for _, value in ipairs(self.Values) do
				local text = tostring(value)

				if map[text] then
					filtered[text] = true
				end
			end

			self.Value = filtered
		else
			local resolved = nil

			if typeof(newValue) == "number" and self.Values[newValue] ~= nil then
				resolved = self.Values[newValue]
			elseif newValue ~= nil then
				for _, value in ipairs(self.Values) do
					if tostring(value) == tostring(newValue) then
						resolved = value
						break
					end
				end
			end

			self.Value = resolved
		end

		Render()

		if not silent then
			self:_FireChanged(self.Value)
		end

		return self
	end

	object.Set = object.SetValue

	function object:Refresh(newValues, keepSelection)
		self.Values = newValues or {}
		BuildOptions()

		if keepSelection == false then
			self.Value = multi and {} or nil
			Render()
		else
			self:SetValue(self.Value, true)
		end

		if expanded then
			SetExpanded(true)
		end

		return self
	end

	object.SetValues = object.Refresh

	function object:Open()
		SetExpanded(true)
		return self
	end

	function object:Close()
		SetExpanded(false)
		return self
	end

	function object:SetSearch(text)
		if searchBox then
			searchBox.Text = tostring(text or "")
			ApplySearchFilter()
		end
		return self
	end

	function object:ClearSearch()
		return self:SetSearch("")
	end

	base.Maid:Give(base.Row.MouseButton1Click:Connect(function()
		SetExpanded(not expanded)
	end))

	BuildOptions()

	if config.Default ~= nil then
		object:SetValue(config.Default, true)
	end

	Render()

	if id then
		RegisterOption(id, object)
	end

	return object
end

--==================================================
-- COLOR PICKER
--==================================================

function Elements.Colorpicker(parent, id, config, owner)
	config = config or {}

	local supportsTransparency = config.Transparency ~= nil

	local base = CreateBase(parent, {
		Name = "NFColorpicker",
		Title = config.Title or "Color",
		Description = config.Description,
		Interactive = true,
		RightWidth = 40,
	})

	local defaultColor = typeof(config.Default) == "Color3" and config.Default
		or Color3.fromRGB(255, 255, 255)

	local hue, saturation, value = defaultColor:ToHSV()

	local preview = New("Frame", {
		Name = "Preview",
		Parent = base.Accessory,
		BackgroundColor3 = defaultColor,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(40, 28),
		LayoutOrder = 2,
	})

	Corner(preview, 6)
	Stroke(preview, "Border")

	local panelHeight = supportsTransparency and 168 or 142

	local panel = New("Frame", {
		Name = "Panel",
		Parent = base.Element,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 2,
	})

	local inner = New("Frame", {
		Name = "Inner",
		Parent = panel,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, panelHeight),
	})

	ListLayout(inner, 8)

	local satval = New("Frame", {
		Name = "SatVal",
		Parent = inner,
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 110),
		LayoutOrder = 1,
	})

	Corner(satval, 6)

	local whiteOverlay = New("Frame", {
		Parent = satval,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	})

	Corner(whiteOverlay, 6)

	New("UIGradient", {
		Parent = whiteOverlay,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	local blackOverlay = New("Frame", {
		Parent = satval,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	})

	Corner(blackOverlay, 6)

	New("UIGradient", {
		Parent = blackOverlay,
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})

	local satvalCursor = New("Frame", {
		Parent = satval,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromScale(saturation, 1 - value),
		ZIndex = 3,
	})

	Corner(satvalCursor, 6)

	New("UIStroke", {
		Parent = satvalCursor,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 2,
	})

	local hueBar = New("Frame", {
		Name = "Hue",
		Parent = inner,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 2,
	})

	Corner(hueBar, 8)

	New("UIGradient", {
		Parent = hueBar,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		}),
	})

	local hueCursor = New("Frame", {
		Parent = hueBar,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(6, 22),
		Position = UDim2.new(hue, 0, 0.5, 0),
		ZIndex = 3,
	})

	Corner(hueCursor, 3)

	New("UIStroke", {
		Parent = hueCursor,
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1,
		Transparency = 0.4,
	})

	local transparencyBar, transparencyCursor, transparencyGradient

	if supportsTransparency then
		transparencyBar = New("Frame", {
			Name = "Transparency",
			Parent = inner,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = 3,
		})

		Corner(transparencyBar, 8)

		transparencyGradient = New("UIGradient", {
			Parent = transparencyBar,
			Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), defaultColor),
		})

		transparencyCursor = New("Frame", {
			Parent = transparencyBar,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(6, 22),
			Position = UDim2.new(1 - (tonumber(config.Transparency) or 0), 0, 0.5, 0),
			ZIndex = 3,
		})

		Corner(transparencyCursor, 3)

		New("UIStroke", {
			Parent = transparencyCursor,
			Color = Color3.fromRGB(0, 0, 0),
			Thickness = 1,
			Transparency = 0.4,
		})
	end

	local object = {
		Type = "Colorpicker",
		Value = defaultColor,
		Transparency = tonumber(config.Transparency) or 0,
		Callback = config.Callback,
		Save = config.Save ~= false,
	}

	AttachChanged(object)
	AttachBaseMethods(object, base, owner)

	local expanded = false

	local function Render(silent)
		local color = Color3.fromHSV(hue, saturation, value)

		object.Value = color

		satval.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		satvalCursor.Position = UDim2.fromScale(saturation, 1 - value)
		hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
		preview.BackgroundColor3 = color
		preview.BackgroundTransparency = object.Transparency or 0

		if supportsTransparency then
			transparencyGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), color)
			transparencyCursor.Position = UDim2.new(1 - (object.Transparency or 0), 0, 0.5, 0)
		end

		if not silent then
			object:_FireChanged(color, object.Transparency)
		end
	end

	local function SetExpanded(state)
		expanded = state and true or false

		if expanded then
			panel.Visible = true
			Tween(panel, { Size = UDim2.new(1, 0, 0, panelHeight) }, SPEED.Normal, Enum.EasingStyle.Quart)
		else
			Tween(panel, { Size = UDim2.new(1, 0, 0, 0) }, SPEED.Normal, Enum.EasingStyle.Quart)

			task.delay(Settings.Animations and (SPEED.Normal + 0.02) or 0, function()
				if not expanded and panel.Parent then
					panel.Visible = false
				end
			end)
		end
	end

	base.Maid:Give(base.Row.MouseButton1Click:Connect(function()
		SetExpanded(not expanded)
	end))

	BindSlide(satval, base.Maid, function(position)
		local absolutePosition = satval.AbsolutePosition
		local absoluteSize = satval.AbsoluteSize

		saturation = Clamp((position.X - absolutePosition.X) / math.max(absoluteSize.X, 1), 0, 1)
		value = 1 - Clamp((position.Y - absolutePosition.Y) / math.max(absoluteSize.Y, 1), 0, 1)

		Render()
	end)

	BindSlide(hueBar, base.Maid, function(position)
		local absolutePosition = hueBar.AbsolutePosition.X
		local absoluteSize = math.max(hueBar.AbsoluteSize.X, 1)

		hue = Clamp((position.X - absolutePosition) / absoluteSize, 0, 1)

		Render()
	end)

	if supportsTransparency then
		BindSlide(transparencyBar, base.Maid, function(position)
			local absolutePosition = transparencyBar.AbsolutePosition.X
			local absoluteSize = math.max(transparencyBar.AbsoluteSize.X, 1)

			object.Transparency = 1 - Clamp((position.X - absolutePosition) / absoluteSize, 0, 1)

			Render()
		end)
	end

	function object:SetValueRGB(color, transparency, silent)
		if typeof(color) == "Color3" then
			hue, saturation, value = color:ToHSV()
		end

		if tonumber(transparency) then
			self.Transparency = Clamp(tonumber(transparency), 0, 1)
		end

		Render(silent)

		return self
	end

	function object:SetValue(newValue, transparency, silent)
		if typeof(newValue) == "Color3" then
			return self:SetValueRGB(newValue, transparency, silent)
		end

		if typeof(newValue) == "table" then
			hue = tonumber(newValue[1]) or tonumber(newValue.H) or hue
			saturation = tonumber(newValue[2]) or tonumber(newValue.S) or saturation
			value = tonumber(newValue[3]) or tonumber(newValue.V) or value

			if tonumber(transparency) then
				self.Transparency = Clamp(tonumber(transparency), 0, 1)
			end

			Render(silent)
		end

		return self
	end

	object.Set = object.SetValue

	function object:SetTransparency(transparency, silent)
		self.Transparency = Clamp(tonumber(transparency) or 0, 0, 1)
		Render(silent)
		return self
	end

	function object:GetValue()
		return self.Value
	end

	Render(true)

	if id then
		RegisterOption(id, object)
	end

	return object
end

--==================================================
-- KEYBIND
--==================================================

local KEY_DISPLAY = {
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
	Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	KeypadZero = "Num0", KeypadOne = "Num1", KeypadTwo = "Num2",
	KeypadThree = "Num3", KeypadFour = "Num4", KeypadFive = "Num5",
	KeypadSix = "Num6", KeypadSeven = "Num7", KeypadEight = "Num8",
	KeypadNine = "Num9",
	LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftShift = "LShift", RightShift = "RShift",
	LeftAlt = "LAlt", RightAlt = "RAlt",
	LeftSuper = "LWin", RightSuper = "RWin",
	Return = "Enter", Escape = "Esc", Backspace = "Bksp",
	Delete = "Del", Insert = "Ins", PageUp = "PgUp", PageDown = "PgDn",
	LeftBracket = "[", RightBracket = "]",
	Semicolon = ";", Quote = "'", Comma = ",", Period = ".",
	Slash = "/", BackSlash = "\\", Minus = "-", Equals = "=",
	Backquote = "`", Tilde = "~",
	Up = "Up", Down = "Down", Left = "Left", Right = "Right",
	MB1 = "Mouse1", MB2 = "Mouse2", MB3 = "Mouse3",
}

local function DisplayKeyName(name)
	name = tostring(name or "None")
	return KEY_DISPLAY[name] or name
end

local MOUSE_NAMES = {
	MB1 = Enum.UserInputType.MouseButton1,
	MB2 = Enum.UserInputType.MouseButton2,
	MB3 = Enum.UserInputType.MouseButton3,
}

local function ResolveKey(key)
	if typeof(key) == "EnumItem" then
		if key.EnumType == Enum.KeyCode then
			return key, key.Name
		end

		if key.EnumType == Enum.UserInputType then
			for name, inputType in pairs(MOUSE_NAMES) do
				if inputType == key then
					return key, name
				end
			end
		end

		return nil, "None"
	end

	if typeof(key) == "string" then
		if key == "" or key == "None" then
			return nil, "None"
		end

		if MOUSE_NAMES[key] then
			return MOUSE_NAMES[key], key
		end

		local ok, keyCode = pcall(function()
			return Enum.KeyCode[key]
		end)

		if ok and keyCode then
			return keyCode, keyCode.Name
		end
	end

	return nil, "None"
end

function Elements.Keybind(parent, id, config, owner)
	config = config or {}

	local base = CreateBase(parent, {
		Name = "NFKeybind",
		Title = config.Title or "Keybind",
		Description = config.Description,
		RightWidth = 100,
	})

	local currentKey, currentName = ResolveKey(config.Default)

	local keyButton = New("TextButton", {
		Name = "Key",
		Parent = base.Accessory,
		BackgroundColor3 = T("Background"),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 36),
		Font = FONT_MEDIUM,
		Text = DisplayKeyName(currentName),
		TextColor3 = T("Text"),
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
	})

	Corner(keyButton, 6)
	Stroke(keyButton, "Border")
	RegisterTheme(keyButton, { BackgroundColor3 = "Background", TextColor3 = "Text" })

	local object = {
		Type = "Keybind",
		Value = currentName,
		Mode = config.Mode or "Toggle",
		State = false,
		Callback = config.Callback,
		ChangedCallback = config.ChangedCallback,
		Save = config.Save ~= false,
	}

	AttachChanged(object)
	AttachBaseMethods(object, base, owner)

	object._Clicked = {}

	function object:OnClick(callback)
		if typeof(callback) == "function" then
			table.insert(self._Clicked, callback)
		end
		return self
	end

	function object:GetState()
		if self.Mode == "Always" then
			return true
		end
		return self.State == true
	end

	local picking = false

	local function Render()
		keyButton.Text = picking and "..." or DisplayKeyName(object.Value)
	end

	function object:SetValue(key, mode, silent)
		local resolved, name = ResolveKey(key)

		currentKey = resolved
		currentName = name

		self.Value = name

		if typeof(mode) == "string" then
			self.Mode = mode
		end

		if self.Mode ~= "Toggle" and self.Mode ~= "Hold" and self.Mode ~= "Always" then
			self.Mode = "Toggle"
		end

		if self.Mode == "Hold" then
			self.State = false
		end

		Render()

		if not silent then
			SafeCallback(self.ChangedCallback, name)

			for _, callback in ipairs(self._Changed) do
				SafeCallback(callback, name)
			end
		end

		return self
	end

	object.Set = object.SetValue

	function object:SetMode(mode, silent)
		return self:SetValue(self.Value, mode, silent)
	end

	local function FireClicked()
		for _, callback in ipairs(object._Clicked) do
			SafeCallback(callback)
		end
	end

	local function Matches(input)
		if not currentKey then
			return false
		end

		if currentKey.EnumType == Enum.KeyCode then
			return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey
		end

		return input.UserInputType == currentKey
	end

	base.Maid:Give(keyButton.MouseButton1Click:Connect(function()
		if picking then
			return
		end

		picking = true
		Render()
		Tween(keyButton, { BackgroundColor3 = T("ElementHover") }, SPEED.Fast)
	end))

	base.Maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if picking then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					picking = false
					Render()
					Tween(keyButton, { BackgroundColor3 = T("Background") }, SPEED.Fast)
					return
				end

				if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					picking = false
					object:SetValue(nil, nil)
					Tween(keyButton, { BackgroundColor3 = T("Background") }, SPEED.Fast)
					return
				end

				picking = false
				object:SetValue(input.KeyCode)
				Tween(keyButton, { BackgroundColor3 = T("Background") }, SPEED.Fast)
				return
			end

			for name, inputType in pairs(MOUSE_NAMES) do
				if input.UserInputType == inputType then
					picking = false
					object:SetValue(name)
					Tween(keyButton, { BackgroundColor3 = T("Background") }, SPEED.Fast)
					return
				end
			end

			return
		end

		if gameProcessed then
			return
		end

		if not Matches(input) then
			return
		end

		if object.Mode == "Toggle" then
			object.State = not object.State
			SafeCallback(object.Callback, object.State)
		elseif object.Mode == "Hold" then
			object.State = true
			SafeCallback(object.Callback, true)
		else
			object.State = true
			SafeCallback(object.Callback, true)
		end

		FireClicked()
	end))

	base.Maid:Give(UserInputService.InputEnded:Connect(function(input)
		if picking then
			return
		end

		if object.Mode ~= "Hold" then
			return
		end

		if Matches(input) and object.State then
			object.State = false
			SafeCallback(object.Callback, false)
		end
	end))

	object:SetValue(config.Default, config.Mode, true)

	if id then
		RegisterOption(id, object)
	end

	return object
end

--==================================================
-- COMPONENT API (modern + legacy)
--==================================================

local ComponentAPI = {}

function ComponentAPI:_GetContainer()
	return self.Container
end

local function NormalizeIdConfig(id, config)
	if typeof(id) == "table" then
		config = id
		id = config.Id or config.Flag or config.Name or config.Title
	end

	config = config or {}

	if typeof(id) ~= "string" then
		id = config.Id or config.Flag or config.Title
	end

	if typeof(id) ~= "string" then
		id = nil
	end

	return id, config
end

function ComponentAPI:AddLabel(config)
	return Elements.Label(self:_GetContainer(), config, self)
end

function ComponentAPI:AddParagraph(config)
	return Elements.Paragraph(self:_GetContainer(), config, self)
end

function ComponentAPI:AddButton(a, b, c)
	local config
	if typeof(a) == "table" then
		config = a
	elseif typeof(a) == "string" then
		if typeof(b) == "function" then
			config = { Title = a, Callback = b, Description = "" }
		elseif typeof(b) == "string" and typeof(c) == "function" then
			config = { Title = a, Description = b, Callback = c }
		elseif typeof(b) == "table" then
			config = b
			config.Title = config.Title or a
		else
			config = { Title = a }
		end
	else
		config = {}
	end
	return Elements.Button(self:_GetContainer(), config, self)
end

function ComponentAPI:AddToggle(id, config)
	local resolvedId, resolvedConfig = NormalizeIdConfig(id, config)
	return Elements.Toggle(self:_GetContainer(), resolvedId, resolvedConfig, self)
end

function ComponentAPI:AddSlider(id, config)
	local resolvedId, resolvedConfig = NormalizeIdConfig(id, config)
	return Elements.Slider(self:_GetContainer(), resolvedId, resolvedConfig, self)
end

function ComponentAPI:AddInput(id, config)
	local resolvedId, resolvedConfig = NormalizeIdConfig(id, config)
	return Elements.Input(self:_GetContainer(), resolvedId, resolvedConfig, self)
end

function ComponentAPI:AddDropdown(id, config)
	local resolvedId, resolvedConfig = NormalizeIdConfig(id, config)
	return Elements.Dropdown(self:_GetContainer(), resolvedId, resolvedConfig, self)
end

function ComponentAPI:AddColorpicker(id, config)
	local resolvedId, resolvedConfig = NormalizeIdConfig(id, config)
	return Elements.Colorpicker(self:_GetContainer(), resolvedId, resolvedConfig, self)
end

ComponentAPI.AddColorPicker = ComponentAPI.AddColorpicker

function ComponentAPI:AddKeybind(id, config)
	local resolvedId, resolvedConfig = NormalizeIdConfig(id, config)
	return Elements.Keybind(self:_GetContainer(), resolvedId, resolvedConfig, self)
end

function ComponentAPI:NewLabel(text)
	return Elements.Label(self:_GetContainer(), { Title = text }, self)
end

function ComponentAPI:NewParagraph(title, content)
	return Elements.Paragraph(self:_GetContainer(), { Title = title, Content = content }, self)
end

function ComponentAPI:NewButton(title, description, callback)
	if typeof(description) == "function" and callback == nil then
		callback = description
		description = ""
	end
	return Elements.Button(self:_GetContainer(), {
		Title = title,
		Description = description,
		Callback = callback,
	}, self)
end

function ComponentAPI:NewToggle(title, description, callback, default)
	return Elements.Toggle(self:_GetContainer(), tostring(title), {
		Title = title,
		Description = description,
		Default = default == true,
		Callback = callback,
	}, self)
end

function ComponentAPI:NewSlider(title, description, maximum, minimum, callback, default)
	return Elements.Slider(self:_GetContainer(), tostring(title), {
		Title = title,
		Description = description,
		Min = minimum,
		Max = maximum,
		Default = default or minimum,
		Rounding = 0,
		Callback = callback,
	}, self)
end

function ComponentAPI:NewTextBox(title, description, callback, placeholder)
	return Elements.Input(self:_GetContainer(), tostring(title), {
		Title = title,
		Description = description,
		Placeholder = placeholder or title,
		Finished = true,
		Callback = callback,
	}, self)
end

ComponentAPI.NewInput = ComponentAPI.NewTextBox

function ComponentAPI:NewDropdown(title, description, values, callback, default)
	return Elements.Dropdown(self:_GetContainer(), tostring(title), {
		Title = title,
		Description = description,
		Values = values,
		Multi = false,
		Default = default,
		Callback = callback,
	}, self)
end

function ComponentAPI:NewColorPicker(title, description, default, callback)
	return Elements.Colorpicker(self:_GetContainer(), tostring(title), {
		Title = title,
		Description = description,
		Default = default,
		Callback = callback,
	}, self)
end

function ComponentAPI:NewKeybind(title, description, key, callback)
	return Elements.Keybind(self:_GetContainer(), tostring(title), {
		Title = title,
		Description = description,
		Default = key,
		Mode = "Always",
		Callback = callback,
	}, self)
end

local function AttachComponentAPI(target)
	for name, fn in pairs(ComponentAPI) do
		if name ~= "_GetContainer" or target._GetContainer == nil then
			target[name] = fn
		end
	end

	return target
end

--==================================================
-- SECTION
--==================================================

local function CreateSection(tab, title, layoutOrder)
	local section = {
		Type = "Section",
		Tab = tab,
		Window = tab.Window,
		_Elements = {},
		Maid = Maid.new(),
	}

	local frame = New("Frame", {
		Name = "NFSection",
		Parent = tab.Page,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = layoutOrder or 1,
	})

	ListLayout(frame, 8)

	local headerHolder = New("Frame", {
		Name = "Header",
		Parent = frame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Visible = title ~= nil and tostring(title) ~= "",
	})

	ListLayout(headerHolder, 6)

	local headerLabel = New("TextLabel", {
		Name = "Title",
		Parent = headerHolder,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT_BOLD,
		Text = tostring(title or ""),
		TextColor3 = T("Text"),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 1,
	})

	RegisterTheme(headerLabel, { TextColor3 = "Text" })

	local divider = New("Frame", {
		Name = "Divider",
		Parent = headerHolder,
		BackgroundColor3 = T("Border"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = 2,
	})

	RegisterTheme(divider, { BackgroundColor3 = "Border" })

	local container = New("Frame", {
		Name = "Container",
		Parent = frame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})

	ListLayout(container, 8)

	section.Instance = frame
	section.Container = container
	section.HeaderLabel = headerLabel

	section.Maid:Give(frame)

	function section:UpdateSection(text)
		headerLabel.Text = tostring(text or "")
		headerHolder.Visible = tostring(text or "") ~= ""
		return self
	end

	section.SetTitle = section.UpdateSection

	function section:Destroy()
		for index = #self._Elements, 1, -1 do
			local element = self._Elements[index]

			if element and typeof(element.Destroy) == "function" then
				pcall(function()
					element:Destroy()
				end)
			end
		end

		self._Elements = {}
		self.Maid:DoCleaning()

		if self.Tab and typeof(self.Tab._Sections) == "table" then
			for index, entry in ipairs(self.Tab._Sections) do
				if entry == self then
					table.remove(self.Tab._Sections, index)
					break
				end
			end
		end
	end

	AttachComponentAPI(section)

	table.insert(tab._Sections, section)

	return section
end

--==================================================
-- TAB
--==================================================

local function CreateTab(window, config)
	if typeof(config) == "string" then
		config = { Title = config }
	end

	config = config or {}

	local tab = {
		Type = "Tab",
		Window = window,
		_Sections = {},
		_Elements = {},
		Maid = Maid.new(),
		SectionOrder = 0,
	}

	local index = #window.Tabs + 1

	local button = New("TextButton", {
		Name = "TabButton",
		ClipsDescendants = true,
		Parent = window.TabList,
		BackgroundColor3 = T("Element"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 42),
		Font = FONT,
		Text = "",
		LayoutOrder = config.LayoutOrder or index,
	})

	Corner(button, 9)
	Stroke(button, "Border", 1, 0.55)

	local function IsSelected()
		return window.CurrentTab == tab
	end

	local iconKind = ResolveTabIcon(config.Icon, config.Title)
	local iconHolder, iconParts = CreateLineGlyph(button, iconKind, 20, button.ZIndex + 1)
	iconHolder.Name = "Icon"
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.new(0, 10, 0.5, 0)

	local indicator = New("Frame", {
		Name = "ActiveIndicator",
		Parent = button,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(3, 22),
		BackgroundColor3 = T("Accent"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 2,
	})
	Corner(indicator, 2)

	local titleLabel = New("TextLabel", {
		Name = "Title",
		Parent = button,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Font = FONT_MEDIUM,
		Text = tostring(config.Title or ("Tab " .. index)),
		TextColor3 = T("SubText"),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
	})

	RegisterTheme(button, {
		BackgroundColor3 = function(theme)
			return IsSelected() and theme.ElementHover or theme.Element
		end,
		BackgroundTransparency = function()
			return IsSelected() and 0 or 1
		end,
	})

	RegisterGlyphTheme(iconParts, function(theme)
		return IsSelected() and theme.Accent or theme.SubText
	end)

	RegisterTheme(indicator, {
		BackgroundColor3 = "Accent",
		BackgroundTransparency = function()
			return IsSelected() and 0 or 1
		end,
	})

	RegisterTheme(titleLabel, {
		TextColor3 = function(theme)
			return IsSelected() and theme.Text or theme.SubText
		end,
	})

	local page = New("ScrollingFrame", {
		Name = "TabPage",
		Parent = window.Content,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T("Border"),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
	})

	RegisterTheme(page, { ScrollBarImageColor3 = "Border" })
	local pagePadding = Padding(page, 14, 20, 14, 14)
	ListLayout(page, 12)

	tab.Button = button
	tab.Page = page
	tab.Instance = button
	tab.Index = index
	tab.Title = tostring(config.Title or ("Tab " .. index))
	tab.IsSettings = config.IsSettings == true
	tab.PagePadding = pagePadding

	tab.Maid:Give(button)
	tab.Maid:Give(page)

	function tab:_GetContainer()
		if not self._DefaultSection then
			self.SectionOrder = self.SectionOrder + 1
			self._DefaultSection = CreateSection(self, nil, self.SectionOrder)
		end

		return self._DefaultSection.Container
	end

	function tab:NewSection(title)
		self.SectionOrder = self.SectionOrder + 1
		return CreateSection(self, title or "Section", self.SectionOrder)
	end

	tab.AddSection = tab.NewSection

	function tab:Select()
		self.Window:SelectTab(self)
		return self
	end

	function tab:SetTitle(text)
		self.Title = tostring(text or "")
		titleLabel.Text = self.Title
		button:SetAttribute("Tooltip", self.Title)
		return self
	end

	function tab:_SetSidebarCollapsed(collapsed, instant)
		self.SidebarCollapsed = collapsed == true
		titleLabel.Visible = true
		local pose = {
			AnchorPoint = Vector2.new(self.SidebarCollapsed and 0.5 or 0, 0.5),
			Position = self.SidebarCollapsed and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 10, 0.5, 0),
		}
		if instant then
			titleLabel.TextTransparency = self.SidebarCollapsed and 1 or 0
			iconHolder.AnchorPoint, iconHolder.Position = pose.AnchorPoint, pose.Position
		else
			Tween(titleLabel, {TextTransparency = self.SidebarCollapsed and 1 or 0}, SPEED.Fast)
			Tween(iconHolder, pose, SPEED.Normal, Enum.EasingStyle.Quart)
		end

		return self
	end

	function tab:_SetMobile(mobile)
		self.Mobile = mobile == true
		button.Size = UDim2.new(1, 0, 0, self.Mobile and 46 or 42)
		pagePadding.PaddingTop = UDim.new(0, self.Mobile and 10 or 14)
		pagePadding.PaddingBottom = UDim.new(0, self.Mobile and 14 or 20)
		pagePadding.PaddingLeft = UDim.new(0, self.Mobile and 10 or 14)
		pagePadding.PaddingRight = UDim.new(0, self.Mobile and 10 or 14)
		return self
	end

	function tab:SetIcon(icon)
		local replacementKind = ResolveTabIcon(icon, self.Title)
		if replacementKind == iconKind then
			return self
		end

		iconKind = replacementKind
		iconHolder:Destroy()
		iconHolder, iconParts = CreateLineGlyph(button, iconKind, 20, button.ZIndex + 1)
		iconHolder.Name = "Icon"
		RegisterGlyphTheme(iconParts, function(theme)
			return IsSelected() and theme.Accent or theme.SubText
		end)
		SetGlyphColor(iconParts, IsSelected() and T("Accent") or T("SubText"))
		self:_SetSidebarCollapsed(self.SidebarCollapsed)
		return self
	end

	function tab:GetIcon()
		return iconKind
	end

	function tab:_Render(selected)
		if selected then
			Tween(button, { BackgroundTransparency = 0, BackgroundColor3 = T("ElementHover") }, SPEED.Fast)
			Tween(titleLabel, { TextColor3 = T("Text"), Position = UDim2.fromOffset(43, 0) }, SPEED.Fast)
			Tween(indicator, { Size = UDim2.fromOffset(3, 24), BackgroundTransparency = 0 }, SPEED.Fast, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenGlyphColor(iconParts, T("Accent"))
			local canvas = iconHolder.Canvas
			local scale = canvas:FindFirstChildOfClass("UIScale")
			canvas.Rotation = Settings.Animations and -6 or 0
			scale.Scale = Settings.Animations and 1.12 or 1
			Tween(canvas, {Rotation = 0}, SPEED.Normal, Enum.EasingStyle.Quart)
			Tween(scale, {Scale = 1}, SPEED.Normal, Enum.EasingStyle.Quart)
		else
			Tween(button, { BackgroundTransparency = 1 }, SPEED.Fast)
			Tween(titleLabel, { TextColor3 = T("SubText"), Position = UDim2.fromOffset(40, 0) }, SPEED.Fast)
			Tween(indicator, { Size = UDim2.fromOffset(3, 8), BackgroundTransparency = 1 }, SPEED.Fast, Enum.EasingStyle.Quad)
			TweenGlyphColor(iconParts, T("SubText"))
			Tween(iconHolder.Canvas, {Rotation = 0}, SPEED.Fast)
			Tween(iconHolder.Canvas:FindFirstChildOfClass("UIScale"), {Scale = 1}, SPEED.Fast)
		end
	end

	function tab:Destroy()
		if self.Destroyed then
			return
		end

		self.Destroyed = true

		for index2 = #self._Sections, 1, -1 do
			local section = self._Sections[index2]

			if section and typeof(section.Destroy) == "function" then
				pcall(function()
					section:Destroy()
				end)
			end
		end

		for index2 = #self._Elements, 1, -1 do
			local element = self._Elements[index2]

			if element and typeof(element.Destroy) == "function" then
				pcall(function()
					element:Destroy()
				end)
			end
		end

		self.Maid:DoCleaning()

		for index2, entry in ipairs(self.Window.Tabs) do
			if entry == self then
				table.remove(self.Window.Tabs, index2)
				break
			end
		end

		if self.Window.CurrentTab == self then
			self.Window.CurrentTab = nil
			self.Window:SelectTab(1)
		end
	end

	tab.Maid:Give(button.MouseButton1Down:Connect(function()
		Tween(iconHolder.Canvas:FindFirstChildOfClass("UIScale"), {Scale = .9}, .08)
	end))

	tab.Maid:Give(button.MouseButton1Up:Connect(function()
		Tween(iconHolder.Canvas:FindFirstChildOfClass("UIScale"), {Scale = 1}, .16, Enum.EasingStyle.Quart)
	end))

	tab.Maid:Give(button.MouseButton1Click:Connect(function()
		window:SelectTab(tab)
	end))

	tab.Maid:Give(button.MouseEnter:Connect(function()
		Tween(iconHolder.Canvas:FindFirstChildOfClass("UIScale"), {Scale = 1.06}, SPEED.Fast)
		if window.CurrentTab ~= tab then
			Tween(button, { BackgroundTransparency = 0.55, BackgroundColor3 = T("Element") }, SPEED.Fast)
			Tween(titleLabel, { Position = UDim2.fromOffset(42, 0) }, SPEED.Fast)
		end
	end))

	tab.Maid:Give(button.MouseLeave:Connect(function()
		Tween(iconHolder.Canvas:FindFirstChildOfClass("UIScale"), {Scale = 1}, SPEED.Fast)
		if window.CurrentTab ~= tab then
			Tween(button, { BackgroundTransparency = 1 }, SPEED.Fast)
			Tween(titleLabel, { Position = UDim2.fromOffset(40, 0) }, SPEED.Fast)
		end
	end))

	button:SetAttribute("Tooltip", tab.Title)
	tab:_SetSidebarCollapsed(window.SidebarCollapsed, true)
	tab:_SetMobile(window.Mobile)

	AttachComponentAPI(tab)

	table.insert(window.Tabs, tab)

	if window.SettingsTab and window.SettingsTab ~= tab then
		for index2, entry in ipairs(window.Tabs) do
			if entry == window.SettingsTab then
				table.remove(window.Tabs, index2)
				break
			end
		end

		table.insert(window.Tabs, window.SettingsTab)
	end

	if window.CreditsTab and window.CreditsTab ~= tab then
		for index2, entry in ipairs(window.Tabs) do
			if entry == window.CreditsTab then
				table.remove(window.Tabs, index2)
				break
			end
		end

		table.insert(window.Tabs, window.CreditsTab)
	end

	local isSpecialTab = tab.IsSettings or tab.IsCredits
	local currentIsSpecial = window.CurrentTab and (window.CurrentTab.IsSettings or window.CurrentTab.IsCredits)

	if not window.CurrentTab or (currentIsSpecial and not isSpecialTab) then
		window:SelectTab(tab)
	end

	return tab
end

--==================================================
-- FLOATING BUTTON (WITHOUT GIFT LOGO)
--==================================================

local function RenderFloatingButton(isOpen)
	if not FloatingButton or not FloatingButton.Parent then
		return
	end

	FloatingButton:SetAttribute("NFOpen", isOpen)
	Tween(FloatingButton, {
		BackgroundColor3 = isOpen and T("Header") or T("Background"),
	}, SPEED.Fast)

	Tween(FloatingLabel, {
		TextColor3 = T("Accent"),
	}, SPEED.Fast)
end

local function EnsureFloatingButton()
	if FloatingButton and FloatingButton.Parent then
		return FloatingButton
	end

	EnsureRoot()

	local size = IsTouchDevice() and 58 or 50
	local viewport = GetViewport()
	local offset = GetRootOffset()

	FloatingButton = New("TextButton", {
		Name = "NFFloatingButton",
		Parent = ScreenGui,
		BackgroundColor3 = T("Background"),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromOffset(18, math.floor(viewport.Y * 0.35 - offset.Y)),
		ZIndex = 800,
	})

	Corner(FloatingButton, math.floor(size / 3))
	Stroke(FloatingButton, "Border", 2)

	FloatingLabel = New("TextLabel", {
		Name = "Label",
		Parent = FloatingButton,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = FONT_BOLD,
		Text = "NF",
		TextColor3 = T("Accent"),
		TextSize = math.floor(size / 2.6),
		ZIndex = 801,
	})

	LibraryMaid:Give(FloatingButton)

	local dragHandle = New("TextButton", {
		Name = "NFDragHandle", Parent = FloatingButton, BackgroundTransparency = 1,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true,
		Size = UDim2.fromScale(1, 1), ZIndex = 805,
	})
	FloatingButton:SetAttribute("NFHovered", false)
	FloatingButton:SetAttribute("NFDragging", false)
	local function RenderInteraction()
		local pressed = FloatingButton:GetAttribute("NFDragging")
		local hovered = FloatingButton:GetAttribute("NFHovered")
		local targetSize = size + (pressed and -3 or (hovered and 2 or 0))
		Tween(FloatingButton, {Size = UDim2.fromOffset(targetSize, targetSize)}, SPEED.Fast)
	end
	LibraryMaid:Give(dragHandle.MouseEnter:Connect(function()
		FloatingButton:SetAttribute("NFHovered", true)
		RenderInteraction()
	end))
	LibraryMaid:Give(dragHandle.MouseLeave:Connect(function()
		FloatingButton:SetAttribute("NFHovered", false)
		RenderInteraction()
	end))

	MakeDraggable(FloatingButton, dragHandle, LibraryMaid, {
		KeepInBounds = true,
		OnStart = function()
			FloatingButton:SetAttribute("NFDragging", true)
			RenderInteraction()
		end,

		OnEnd = function(moved)
			FloatingButton:SetAttribute("NFDragging", false)
			RenderInteraction()

			if moved then
				FloatingMoved = true
			else
				Library:ToggleUI()
			end
		end,
	})

	OnThemeChanged(function()
		RenderFloatingButton(Library:IsOpen())
	end)

	task.defer(ApplyRootOffset)

	RenderFloatingButton(false)

	return FloatingButton
end

--==================================================
-- WINDOW
--==================================================

local function CreateWindowInternal(config)
	if typeof(config) == "string" then
		config = { Title = config }
	end

	config = config or {}

	if Library.Window and not Library.Window.Destroyed then
		return Library.Window
	end

	EnsureRoot()

	local window = {
		Type = "Window",
		Tabs = {},
		CurrentTab = nil,
		Maid = Maid.new(),
		Destroyed = false,
		Visible = true,
	}

	local viewport = GetViewport()
	local requestedSize = typeof(config.Size) == "UDim2" and config.Size or DEFAULT_WINDOW_SIZE

	local width = math.floor(math.min(requestedSize.X.Offset, viewport.X - 24))
	local height = math.floor(math.min(requestedSize.Y.Offset, viewport.Y - 24))

	width = math.max(width, 300)
	height = math.max(height, 260)

	local tabWidth = tonumber(config.TabWidth) or 150

	if width < 470 then
		tabWidth = 112
	end

	window.ExpandedTabWidth = tabWidth
	window.CollapsedTabWidth = IsTouchDevice() and 60 or 58
	window.Mobile = IsTouchDevice() or width < 470
	window.SidebarCollapsed = config.SidebarCollapsed == true
		or config.Collapsed == true
		or window.Mobile
	window.SidebarManuallySet = config.SidebarCollapsed ~= nil or config.Collapsed ~= nil

	local initialSidebarWidth = window.SidebarCollapsed and window.CollapsedTabWidth or tabWidth

	local rootOffset = GetRootOffset()

	local defaultPosition = UDim2.fromOffset(
		math.floor((viewport.X - width) / 2 - rootOffset.X),
		math.floor((viewport.Y - height) / 2 - rootOffset.Y)
	)

	local main = New("Frame", {
		Name = "NFWindow",
		Parent = ScreenGui,
		BackgroundColor3 = T("Background"),
		BackgroundTransparency = Settings.Transparency or 0,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(width, height),
		Position = typeof(Settings.Position) == "UDim2" and Settings.Position or defaultPosition,
		ClipsDescendants = true,
		ZIndex = 100,
	})

	Corner(main, 12)
	Stroke(main, "Border")
	RegisterTheme(main, { BackgroundColor3 = "Background" })

	local uiScale = New("UIScale", { Parent = main, Scale = Settings.Scale or 1 })

	window.Instance = main
	window.Frame = main
	window.Scale = uiScale
	window.DefaultPosition = defaultPosition
	window.DefaultSize = UDim2.fromOffset(width, height)

	local header = New("Frame", {
		Name = "Header",
		Parent = main,
		BackgroundColor3 = T("Header"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 46),
		ZIndex = 101,
	})

	RegisterTheme(header, { BackgroundColor3 = "Header" })

	Corner(header, 12)

	local headerFill = New("Frame", {
		Name = "HeaderFill",
		Parent = header,
		BackgroundColor3 = T("Header"),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
		ZIndex = 101,
	})

	RegisterTheme(headerFill, { BackgroundColor3 = "Header" })

	local headerLine = New("Frame", {
		Name = "HeaderLine",
		Parent = header,
		BackgroundColor3 = T("Border"),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 102,
	})

	RegisterTheme(headerLine, { BackgroundColor3 = "Border" })

	local logo = New("Frame", {
		Name = "Logo",
		Parent = header,
		BackgroundColor3 = T("Accent"),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(36, 36),
		ZIndex = 102,
	})

	Corner(logo, 8)
	RegisterTheme(logo, { BackgroundColor3 = "Accent" })

	local logoLabel = New("TextLabel", {
		Parent = logo,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = FONT_BOLD,
		Text = "NF",
		TextColor3 = T("Background"),
		TextSize = 14,
		ZIndex = 103,
	})

	RegisterTheme(logoLabel, { TextColor3 = "Background" })

	local titleLabel = New("TextLabel", {
		Name = "Title",
		Parent = header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(50, 6),
		Size = UDim2.new(1, -140, 0, 20),
		Font = FONT_BOLD,
		Text = tostring(config.Title or "NUTHERAFROX"),
		TextColor3 = T("Text"),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
		ZIndex = 102,
	})

	RegisterTheme(titleLabel, { TextColor3 = "Text" })

	local subtitleText = tostring(config.Subtitle or "")

	local subtitleLabel = New("TextLabel", {
		Name = "Subtitle",
		Parent = header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(50, 24),
		Size = UDim2.new(1, -140, 0, 16),
		Font = FONT,
		Text = subtitleText,
		TextColor3 = T("SubText"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
		Visible = subtitleText ~= "",
		ZIndex = 102,
	})

	RegisterTheme(subtitleLabel, { TextColor3 = "SubText" })

	if subtitleText == "" then
		titleLabel.Position = UDim2.fromOffset(50, 0)
		titleLabel.Size = UDim2.new(1, -140, 1, 0)
	end

	local function HeaderButton(kind, offset, callback)
		local button = New("TextButton", {
			Name = kind == "close" and "CloseButton" or "MinimizeButton",
			Parent = header,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = T("Element"),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 103,
		})

		Corner(button, 8)
		Stroke(button, "Border", 1, 0.35)
		RegisterTheme(button, { BackgroundColor3 = "Element" })

		local glyph, glyphParts = CreateLineGlyph(button, kind, kind == "close" and 14 or 15, 104)
		glyph.AnchorPoint = Vector2.new(0.5, 0.5)
		glyph.Position = UDim2.fromScale(0.5, 0.5)
		RegisterGlyphTheme(glyphParts, "SubText")

		window.Maid:Give(button.MouseEnter:Connect(function()
			local hoverColor = kind == "close" and Color3.fromRGB(210, 62, 62) or T("ElementHover")
			Tween(button, { BackgroundTransparency = 0, BackgroundColor3 = hoverColor }, SPEED.Fast)
			SetGlyphColor(glyphParts, kind == "close" and Color3.fromRGB(255, 255, 255) or T("Text"))
		end))

		window.Maid:Give(button.MouseLeave:Connect(function()
			Tween(button, { BackgroundTransparency = 0.55, BackgroundColor3 = T("Element"), Rotation = 0 }, SPEED.Fast)
			SetGlyphColor(glyphParts, T("SubText"))
		end))

		window.Maid:Give(button.MouseButton1Down:Connect(function()
			Tween(button, { BackgroundTransparency = .1 }, SPEED.Fast)
		end))

		window.Maid:Give(button.MouseButton1Up:Connect(function()
			Tween(button, { BackgroundTransparency = 0 }, SPEED.Fast)
		end))

		window.Maid:Give(button.MouseButton1Click:Connect(callback))

		return button
	end

	HeaderButton("close", -10, function()
		window:Hide()
	end)

	HeaderButton("minimize", -48, function()
		window:Hide()
	end)

	local body = New("Frame", {
		Name = "Body",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -46),
		ZIndex = 100,
	})

	local sidebar = New("Frame", {
		Name = "Sidebar",
		Parent = body,
		BackgroundColor3 = T("Header"),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.new(0, initialSidebarWidth, 1, 0),
		ZIndex = 100,
	})

	RegisterTheme(sidebar, { BackgroundColor3 = "Header" })

	local sidebarLine = New("Frame", {
		Name = "SidebarLine",
		Parent = sidebar,
		BackgroundColor3 = T("Border"),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 101,
	})

	RegisterTheme(sidebarLine, { BackgroundColor3 = "Border" })

	local tabList = New("ScrollingFrame", {
		Name = "TabList",
		Parent = sidebar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -44),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T("Border"),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 101,
	})

	RegisterTheme(tabList, { ScrollBarImageColor3 = "Border" })
	local tabPadding = Padding(tabList, 10, 8, 8, 8)
	ListLayout(tabList, 6)

	local collapseButton = New("TextButton", {
		Name = "CollapseSidebar",
		Parent = sidebar,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 30),
		BackgroundColor3 = T("Element"),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 102,
	})
	Corner(collapseButton, 8)
	Stroke(collapseButton, "Border", 1, 0.35)
	RegisterTheme(collapseButton, { BackgroundColor3 = "Element" })

	local collapseGlyph, collapseGlyphParts = CreateLineGlyph(collapseButton, "chevron-right", 14, 103)
	collapseGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	collapseGlyph.Position = UDim2.fromScale(0.5, 0.5)
	RegisterGlyphTheme(collapseGlyphParts, "SubText")

	local content = New("Frame", {
		Name = "Content",
		Parent = body,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(initialSidebarWidth, 0),
		Size = UDim2.new(1, -initialSidebarWidth, 1, 0),
		ClipsDescendants = true,
		ZIndex = 100,
	})

	window.Header = header
	window.TabList = tabList
	window.Content = content
	window.Sidebar = sidebar
	window.CollapseButton = collapseButton

	window.Maid:Give(main)
	window.Maid:Give(collapseButton.MouseEnter:Connect(function()
		Tween(collapseButton, { BackgroundTransparency = 0 }, SPEED.Fast)
		SetGlyphColor(collapseGlyphParts, T("Text"))
	end))
	window.Maid:Give(collapseButton.MouseLeave:Connect(function()
		Tween(collapseButton, { BackgroundTransparency = 0.35 }, SPEED.Fast)
		SetGlyphColor(collapseGlyphParts, T("SubText"))
	end))
	window.Maid:Give(collapseButton.MouseButton1Click:Connect(function()
		window:ToggleSidebar()
	end))

	MakeDraggable(main, header, window.Maid, {
		OnEnd = function()
			window.PositionCustomised = true
			Settings.Position = main.Position
			SaveInterface()
		end,
	})

	function window:AddTab(tabConfig)
		local title = typeof(tabConfig) == "table" and tabConfig.Title or tabConfig

		if
			typeof(title) == "string"
			and title:lower() == "settings"
			and self.SettingsTab
			and not self.SettingsTab.Destroyed
		then
			return self.SettingsTab
		end

		if
			typeof(title) == "string"
			and title:lower() == "credits"
			and self.CreditsTab
			and not self.CreditsTab.Destroyed
		then
			return self.CreditsTab
		end

		return CreateTab(self, tabConfig)
	end

	window.NewTab = window.AddTab

	function window:SetSidebarCollapsed(state, instant, automatic)
		self.SidebarCollapsed = state == true
		if not automatic then
			self.SidebarManuallySet = true
		end

		local targetWidth = self.SidebarCollapsed and self.CollapsedTabWidth or self.ExpandedTabWidth
		local sidebarSize = UDim2.new(0, targetWidth, 1, 0)
		local contentPosition = UDim2.fromOffset(targetWidth, 0)
		local contentSize = UDim2.new(1, -targetWidth, 1, 0)

		if instant or not Settings.Animations then
			sidebar.Size = sidebarSize
			content.Position = contentPosition
			content.Size = contentSize
			collapseGlyph.Rotation = self.SidebarCollapsed and 0 or 180
		else
			Tween(sidebar, { Size = sidebarSize }, SPEED.Normal, Enum.EasingStyle.Quart)
			Tween(content, { Position = contentPosition, Size = contentSize }, SPEED.Normal, Enum.EasingStyle.Quart)
			Tween(collapseGlyph, { Rotation = self.SidebarCollapsed and 0 or 180 }, SPEED.Normal)
		end

		tabPadding.PaddingLeft = UDim.new(0, self.SidebarCollapsed and 6 or 8)
		tabPadding.PaddingRight = UDim.new(0, self.SidebarCollapsed and 6 or 8)
		tabList.ScrollBarThickness = self.SidebarCollapsed and 0 or 2

		for _, tab in ipairs(self.Tabs) do
			if tab and typeof(tab._SetSidebarCollapsed) == "function" then
				tab:_SetSidebarCollapsed(self.SidebarCollapsed, instant)
			end
		end

		return self
	end

	function window:ToggleSidebar()
		return self:SetSidebarCollapsed(not self.SidebarCollapsed)
	end

	function window:IsSidebarCollapsed()
		return self.SidebarCollapsed == true
	end

	function window:SelectTab(target)
		local tab = target

		if typeof(target) == "number" then
			tab = self.Tabs[target]
		elseif typeof(target) == "string" then
			for _, entry in ipairs(self.Tabs) do
				if entry.Title == target then
					tab = entry
					break
				end
			end
		end

		if typeof(tab) ~= "table" or not tab.Page then
			return self
		end

		if self.CurrentTab == tab then
			tab.Page.Visible = true
			return self
		end

		for _, entry in ipairs(self.Tabs) do
			if entry ~= tab then
				entry.Page.Visible = false
				entry:_Render(false)
			end
		end

		local previous = self.CurrentTab
		self.CurrentTab = tab
		tab:_Render(true)

		tab.Page.Visible = true
		local direction = previous and (tab.Button.LayoutOrder < previous.Button.LayoutOrder and -1 or 1) or 1
		tab.Page.Position = Settings.Animations and UDim2.fromOffset(direction * 14, 6) or UDim2.fromOffset(0, 0)
		Tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, .24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		return self
	end

	function window:Show()
		self.Visible = true
		main.Visible = true

		uiScale.Scale = (Settings.Scale or 1) * (Settings.Animations and 0.92 or 1)
		Tween(uiScale, { Scale = Settings.Scale or 1 }, SPEED.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		RenderFloatingButton(true)

		return self
	end

	function window:Hide()
		self.Visible = false

		Tween(uiScale, { Scale = (Settings.Scale or 1) * 0.94 }, SPEED.Fast)

		task.delay(Settings.Animations and SPEED.Fast or 0, function()
			if not self.Visible and main.Parent then
				main.Visible = false
			end
		end)

		RenderFloatingButton(false)

		return self
	end

	function window:Toggle()
		if self.Visible then
			return self:Hide()
		end

		return self:Show()
	end

	function window:IsVisible()
		return self.Visible == true
	end

	function window:SetTitle(text)
		titleLabel.Text = tostring(text or "")
		return self
	end

	function window:SetSubtitle(text)
		local value = tostring(text or "")
		subtitleLabel.Text = value
		subtitleLabel.Visible = value ~= ""

		if value == "" then
			titleLabel.Position = UDim2.fromOffset(50, 0)
			titleLabel.Size = UDim2.new(1, -140, 1, 0)
		else
			titleLabel.Position = UDim2.fromOffset(50, 6)
			titleLabel.Size = UDim2.new(1, -140, 0, 20)
		end

		return self
	end

	function window:_ApplyResponsiveLayout(instant)
		local currentViewport = GetViewport()
		local maxWidth = math.max(240, currentViewport.X - 12)
		local maxHeight = math.max(220, currentViewport.Y - 12)
		local minimumWidth = math.min(300, maxWidth)
		local minimumHeight = math.min(260, maxHeight)
		local targetWidth = Clamp(requestedSize.X.Offset, minimumWidth, maxWidth)
		local targetHeight = Clamp(requestedSize.Y.Offset, minimumHeight, maxHeight)
		local targetSize = UDim2.fromOffset(math.floor(targetWidth), math.floor(targetHeight))

		if instant or not Settings.Animations then
			main.Size = targetSize
		else
			Tween(main, { Size = targetSize }, SPEED.Normal, Enum.EasingStyle.Quart)
		end

		self.Mobile = IsTouchDevice() or targetWidth < 470
		for _, tab in ipairs(self.Tabs) do
			if tab and typeof(tab._SetMobile) == "function" then
				tab:_SetMobile(self.Mobile)
			end
		end

		if not self.SidebarManuallySet then
			self:SetSidebarCollapsed(self.Mobile, instant, true)
		end

		local offset = GetRootOffset()
		self.DefaultSize = targetSize
		self.DefaultPosition = UDim2.fromOffset(
			math.floor((currentViewport.X - targetWidth) / 2 - offset.X),
			math.floor((currentViewport.Y - targetHeight) / 2 - offset.Y)
		)

		if not self.PositionCustomised then
			main.Position = self.DefaultPosition
		end

		return self
	end

	function window:SetSize(size)
		if typeof(size) == "UDim2" then
			requestedSize = size
			self:_ApplyResponsiveLayout(false)
		end

		return self
	end

	function window:GetSize()
		return main.Size
	end

	function window:SetPosition(position)
		if typeof(position) == "UDim2" then
			main.Position = position
			Settings.Position = position
			self.PositionCustomised = true
		end

		return self
	end

	function window:GetPosition()
		return main.Position
	end

	function window:ResetPosition()
		self.PositionCustomised = false
		Settings.Position = nil
		main.Position = self.DefaultPosition
		ApplyRootOffset()
		SaveInterface()
		return self
	end

	function window:Dialog(dialogConfig)
		return Library:Dialog(dialogConfig)
	end

	function window:Notify(notifyConfig)
		return Library:Notify(notifyConfig)
	end

	function window:Destroy()
		if self.Destroyed then
			return
		end

		self.Destroyed = true

		for index = #self.Tabs, 1, -1 do
			local tab = self.Tabs[index]

			if tab and typeof(tab.Destroy) == "function" then
				pcall(function()
					tab:Destroy()
				end)
			end
		end

		self.Tabs = {}
		self.Maid:DoCleaning()

		if Library.Window == self then
			Library.Window = nil
		end
	end

	OnInterfaceChanged(function()
		if window.Destroyed then
			return
		end

		uiScale.Scale = Settings.Scale or 1
		main.BackgroundTransparency = Settings.Transparency or 0
		sidebar.BackgroundTransparency = 0.35 + (Settings.Transparency or 0) * 0.5

		if typeof(Settings.Position) == "UDim2" then
			main.Position = Settings.Position
		end
	end)

	window.PositionCustomised = typeof(Settings.Position) == "UDim2"
	window:SetSidebarCollapsed(window.SidebarCollapsed, true, true)
	window:_ApplyResponsiveLayout(true)

	local responsiveQueued = false
	window.Maid:Give(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if responsiveQueued or window.Destroyed then
			return
		end

		responsiveQueued = true
		task.defer(function()
			responsiveQueued = false
			if not window.Destroyed then
				window:_ApplyResponsiveLayout(true)
			end
		end)
	end))

	Library.Window = window
	table.insert(Library.Windows, window)

	task.defer(ApplyRootOffset)

	EnsureFloatingButton()
	RenderFloatingButton(true)

	window:Show()

	return window
end

--==================================================
-- SETTINGS TAB
--==================================================

local THEME_DISPLAY = {
	DarkTheme  = "Dark",
	LightTheme = "Light",
	Serpent    = "Serpent",
}

local DISPLAY_THEME = {
	Dark    = "DarkTheme",
	Light   = "LightTheme",
	Serpent = "Serpent",
}

local SCALE_VALUES = { "80%", "90%", "100%", "110%", "120%" }

local function ScaleToDisplay(scale)
	return tostring(math.floor((tonumber(scale) or 1) * 100 + 0.5)) .. "%"
end

local function DisplayToScale(display)
	local stripped = string.gsub(tostring(display), "%%", "")
	local number = tonumber(stripped)
	return (number or 100) / 100
end

local function SyncSettingsUI()
	local themeOption = Library.Options.__NFTheme

	if themeOption then
		themeOption:SetValue(THEME_DISPLAY[CurrentThemeName] or "Dark", true)
	end

	local scaleOption = Library.Options.__NFScale

	if scaleOption then
		scaleOption:SetValue(ScaleToDisplay(Settings.Scale), true)
	end

	local transparencyOption = Library.Options.__NFTransparency

	if transparencyOption then
		transparencyOption:SetValue(math.floor((Settings.Transparency or 0) * 100 + 0.5), true)
	end

	local animationsOption = Library.Options.__NFAnimations

	if animationsOption then
		animationsOption:SetValue(Settings.Animations == true, true)
	end

	local accentOption = Library.Options.__NFCustomAccent

	if accentOption then
		accentOption:SetValue(Settings.CustomAccent or T("Accent"), 0, true)
	end

	local keyOption = Library.Options.__NFMinimizeKey

	if keyOption then
		keyOption:SetValue(
			typeof(Settings.MinimizeKey) == "EnumItem" and Settings.MinimizeKey.Name or "None",
			"Always",
			true
		)
	end

	local configNameOption = Library.Options.__NFConfigName

	if configNameOption then
		configNameOption:SetValue(Settings.ConfigName or "", true)
	end

	local autoLoadOption = Library.Options.__NFAutoLoad

	if autoLoadOption then
		autoLoadOption:SetValue(Settings.AutoLoad ~= nil and Settings.AutoLoad ~= "", true)
	end
end

local function BuildSettingsTab(window)
	local tab = CreateTab(window, {
		Title = "Settings",
		Icon = "settings",
		LayoutOrder = 9000,
		IsSettings = true,
	})

	window.SettingsTab = tab

	local interface = tab:NewSection("Interface")

	interface:AddDropdown("__NFTheme", {
		Title = "Theme",
		Description = "Choose the appearance of the UI.",
		Values = { "Dark", "Light", "Serpent", "Midnight", "Crimson", "Emerald", "Amethyst", "Sunset", "Aqua", "Rose" },
		Default = THEME_DISPLAY[CurrentThemeName] or "Dark",
		Save = false,
		Callback = function(value)
			SetThemeInternal(DISPLAY_THEME[tostring(value)] or "DarkTheme")
			SaveInterface()
		end,
	})

	interface:AddDropdown("__NFScale", {
		Title = "UI Scale",
		Description = "Change the size of the interface.",
		Values = SCALE_VALUES,
		Default = ScaleToDisplay(Settings.Scale),
		Save = false,
		Callback = function(value)
			Settings.Scale = DisplayToScale(value)
			FireInterfaceChanged()
			SaveInterface()
		end,
	})

	interface:AddSlider("__NFTransparency", {
		Title = "Transparency",
		Description = "Background transparency of the window.",
		Min = 0,
		Max = 60,
		Default = math.floor((Settings.Transparency or 0) * 100 + 0.5),
		Rounding = 0,
		Suffix = "%",
		Save = false,
		Callback = function(value)
			Settings.Transparency = (tonumber(value) or 0) / 100
			FireInterfaceChanged()
			SaveInterface()
		end,
	})

	interface:AddToggle("__NFAnimations", {
		Title = "Animations",
		Description = "Enable or disable smooth UI animations & transitions.",
		Default = Settings.Animations == true,
		Save = false,
		Callback = function(state)
			Library:SetAnimationsEnabled(state)
		end,
	})

	interface:AddColorpicker("__NFCustomAccent", {
		Title = "Accent Color",
		Description = "Choose a custom accent color for buttons, toggles, icons, and indicators.",
		Default = Settings.CustomAccent or T("Accent"),
		Transparency = 0,
		Save = false,
		Callback = function(color)
			SetCustomAccentInternal(color)
			SaveInterface()
		end,
	})

	interface:AddButton({
		Title = "Reset Accent to Theme Default",
		Description = "Restore the accent color back to the current theme default.",
		Callback = function()
			SetCustomAccentInternal(nil)
			local defaultAccent = Themes[CurrentThemeName] and Themes[CurrentThemeName].Accent or Color3.fromRGB(255, 255, 255)
			if Library.Options.__NFCustomAccent then
				Library.Options.__NFCustomAccent:SetValue(defaultAccent, 0, true)
			end
			SaveInterface()
			Library:Notify({
				Title = "Accent Reset",
				Content = "Accent color restored to theme default.",
				Duration = 3,
			})
		end,
	})

	interface:AddKeybind("__NFMinimizeKey", {
		Title = "Minimize Key",
		Description = "Key used to hide or show the hub.",
		Mode = "Always",
		Default = typeof(Settings.MinimizeKey) == "EnumItem" and Settings.MinimizeKey.Name or "RightControl",
		Save = false,
		ChangedCallback = function(name)
			local ok, key = pcall(function()
				return Enum.KeyCode[name]
			end)

			if ok and key then
				Settings.MinimizeKey = key
			else
				Settings.MinimizeKey = nil
			end

			SaveInterface()
		end,
	})

	interface:AddButton({
		Title = "Reset UI Position",
		Description = "Move the window back to its default position.",
		Callback = function()
			Library:ResetPosition()

			Library:Notify({
				Title = "Interface",
				Content = "Window position has been reset.",
				Duration = 3,
			})
		end,
	})

	interface:AddButton({
		Title = "Reset Settings",
		Description = "Restore theme, scale and animation defaults.",
		Callback = function()
			Library:Dialog({
				Title = "Reset Settings",
				Content = "Are you sure you want to restore the default interface settings?",
				Buttons = {
					{
						Title = "Reset",
						Callback = function()
							Library:ResetSettings()

							Library:Notify({
								Title = "Interface",
								Content = "Settings restored to defaults.",
								Duration = 3,
							})
						end,
					},
					{
						Title = "Cancel",
					},
				},
			})
		end,
	})

	local configuration = tab:NewSection("Configuration")

	local configNameInput
	local configListDropdown

	local function CurrentConfigName()
		local typed = configNameInput and tostring(configNameInput.Value or "") or ""

		if typed ~= "" then
			return typed
		end

		if configListDropdown and configListDropdown.Value ~= nil then
			return tostring(configListDropdown.Value)
		end

		return Settings.ConfigName or "default"
	end

	local function RefreshConfigList()
		if configListDropdown then
			configListDropdown:Refresh(Library.Config:GetConfigs())
		end
	end

	configNameInput = configuration:AddInput("__NFConfigName", {
		Title = "Config Name",
		Description = "Enter the name of your configuration.",
		Placeholder = "MyConfig",
		Default = Settings.ConfigName or "",
		Finished = true,
		Save = false,
		Callback = function(value)
			if tostring(value) ~= "" then
				Settings.ConfigName = tostring(value)
			end
		end,
	})

	configListDropdown = configuration:AddDropdown("__NFConfigList", {
		Title = "Config List",
		Description = "Saved configurations.",
		Values = Library.Config:GetConfigs(),
		Multi = false,
		Save = false,
		Callback = function(value)
			if value ~= nil and configNameInput then
				configNameInput:SetValue(tostring(value), true)
				Settings.ConfigName = tostring(value)
			end
		end,
	})

	configuration:AddButton({
		Title = "Save Config",
		Description = "Save your current settings.",
		Callback = function()
			local name = CurrentConfigName()
			local saved = Library.Config:Save(name)

			RefreshConfigList()

			if saved then
				Library:Notify({
					Title = "Configuration",
					Content = ("Saved '%s' successfully."):format(name),
					Duration = 3,
				})
			end
		end,
	})

	configuration:AddButton({
		Title = "Load Config",
		Description = "Load your saved settings.",
		Callback = function()
			local name = CurrentConfigName()

			if Library.Config:Load(name) then
				SyncSettingsUI()

				Library:Notify({
					Title = "Configuration",
					Content = ("Loaded '%s' successfully."):format(name),
					Duration = 3,
				})
			end
		end,
	})

	configuration:AddButton({
		Title = "Delete Config",
		Description = "Delete the selected configuration.",
		Callback = function()
			local name = CurrentConfigName()

			Library:Dialog({
				Title = "Delete Configuration",
				Content = ("Delete '%s'? This cannot be undone."):format(name),
				Buttons = {
					{
						Title = "Delete",
						Callback = function()
							local deleted = Library.Config:Delete(name)

							RefreshConfigList()

							Library:Notify({
								Title = "Configuration",
								Content = deleted
									and ("Deleted '%s'."):format(name)
									or ("Could not delete '%s'."):format(name),
								Duration = 3,
							})
						end,
					},
					{
						Title = "Cancel",
					},
				},
			})
		end,
	})

	configuration:AddButton({
		Title = "Refresh List",
		Description = "Reload the list of saved configurations.",
		Callback = function()
			RefreshConfigList()

			Library:Notify({
				Title = "Configuration",
				Content = "Config list refreshed.",
				Duration = 2,
			})
		end,
	})

	configuration:AddToggle("__NFAutoLoad", {
		Title = "Auto Load Config",
		Description = "On the next hub run, automatically apply this saved configuration.",
		Default = Settings.AutoLoad ~= nil and Settings.AutoLoad ~= "",
		Save = false,
		FireOnInit = false,
		Callback = function(state)
			if state then
				local name = CurrentConfigName()
				Library.Config:SetAutoLoad(name)

				Library:Notify({
					Title = "Configuration",
					Content = ("'%s' will auto load."):format(name),
					Duration = 3,
				})
			else
				Library.Config:SetAutoLoad(nil)
			end
		end,
	})

	return tab
end

--==================================================
-- CREDITS TAB
--==================================================

local function BuildCreditsTab(window)
	local tab = CreateTab(window, {
		Title = "Credits",
		Icon = "heart",
		LayoutOrder = 9001,
		IsCredits = true,
	})

	window.CreditsTab = tab

	local credits = tab:NewSection("Credits")

	credits:AddParagraph({
		Title = "NUTHERAFROX UI",
		Content = "Created by NUTHERAFROX — 26.09.2025",
	})

	credits:AddParagraph({
		Title = "About",
		Content = "Fully isolated UI framework, no external dependencies. Custom theme system, PC + Mobile support.",
	})

	return tab
end

--==================================================
-- LIBRARY API
--==================================================

function Library:CreateWindow(config)
	if config == Library then
		config = nil
	end

	local existing = Library.Window

	if existing and not existing.Destroyed then
		return existing
	end

	local window = CreateWindowInternal(config)

	if not window.SettingsTab then
		BuildSettingsTab(window)
	end

	if not window.CreditsTab then
		BuildCreditsTab(window)
	end

	window:SelectTab(1)
	Config:QueueAutoLoad()

	return window
end

function Library.CreateLib(a, b, c)
	local title, theme = a, b

	if a == Library then
		title, theme = b, c
	end

	if theme then
		SetThemeInternal(theme)
	end

	return Library:CreateWindow({
		Title = title or "NUTHERAFROX",
		Subtitle = "",
		Theme = theme,
	})
end

Library.CreateWindowLegacy = Library.CreateLib

function Library:IsOpen()
	return self.Window ~= nil and not self.Window.Destroyed and self.Window.Visible == true
end

function Library:Show()
	if self.Window and not self.Window.Destroyed then
		self.Window:Show()
	end

	return self
end

function Library:Hide()
	if self.Window and not self.Window.Destroyed then
		self.Window:Hide()
	end

	return self
end

function Library:ToggleUI()
	if self.Window and not self.Window.Destroyed then
		self.Window:Toggle()
	end

	return self
end

Library.Toggle = Library.ToggleUI

function Library:SetTheme(theme)
	SetThemeInternal(theme)
	SyncSettingsUI()
	SaveInterface()
	RenderFloatingButton(self:IsOpen())

	return self
end

function Library:GetTheme()
	return CurrentThemeName
end

function Library:AddTheme(name, palette)
	if typeof(name) == "string" and typeof(palette) == "table" then
		Themes[name] = palette
	end

	return self
end

function Library:SetScale(scale)
	Settings.Scale = Clamp(tonumber(scale) or 1, 0.5, 2)
	FireInterfaceChanged()
	SyncSettingsUI()
	SaveInterface()

	return self
end

function Library:SetAnimationsEnabled(state)
	if state ~= true then CancelAllTweens(true) end
	Settings.Animations = state == true
	SyncSettingsUI()
	SaveInterface()

	return self
end

function Library:SetMinimizeKey(key)
	if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
		Settings.MinimizeKey = key
	elseif typeof(key) == "string" then
		local ok, keyCode = pcall(function()
			return Enum.KeyCode[key]
		end)

		Settings.MinimizeKey = (ok and keyCode) or nil
	else
		Settings.MinimizeKey = nil
	end

	SyncSettingsUI()
	SaveInterface()

	return self
end

function Library:ResetPosition()
	if self.Window and not self.Window.Destroyed then
		self.Window:ResetPosition()
	end

	if FloatingButton and FloatingButton.Parent then
		FloatingButton.Position = UDim2.fromOffset(18, math.floor(GetViewport().Y * 0.35))
	end

	return self
end

function Library:ResetTheme()
	return self:SetTheme("DarkTheme")
end

function Library:ResetSettings()
	Settings.Scale = 1
	Settings.Transparency = 0
	Settings.Animations = true
	Settings.MinimizeKey = Enum.KeyCode.RightControl
	Settings.Position = nil

	SetThemeInternal("DarkTheme")
	FireInterfaceChanged()

	if self.Window and not self.Window.Destroyed then
		self.Window:ResetPosition()
	end

	SyncSettingsUI()
	SaveInterface()
	RenderFloatingButton(self:IsOpen())

	return self
end

function Library:GetOption(id)
	return self.Options[id]
end

function Library:AddCleanup(item)
	return LibraryMaid:Give(item)
end

Library.GiveTask = Library.AddCleanup
Library.Track = Library.AddCleanup

function Library:OnUnload(callback)
	if typeof(callback) == "function" then
		table.insert(self.UnloadCallbacks, callback)
	end
	return self
end

function Library:IsCurrent()
	if self.Unloaded or self.Unloading then
		return false
	end

	for _, env in ipairs(GetSharedEnvironments()) do
		if rawget(env, "NUTHERAFROX_UI_LIBRARY") == self then
			return true
		end
	end

	return false
end

function Library:StopAllFeatures()
	local stopped = 0
	local candidates = {}

	for id, option in pairs(self.Options) do
		if typeof(id) == "string" and id:sub(1, 4) ~= "__NF" and typeof(option) == "table" then
			if (option.Type == "Toggle" and option.Value == true)
				or (option.Type == "Keybind" and option.State == true)
			then
				table.insert(candidates, option)
			end
		end
	end

	for _, option in ipairs(candidates) do
		if option.Type == "Toggle" and option.Value == true and typeof(option.SetValue) == "function" then
				local ok = pcall(function()
					option:SetValue(false)
				end)

				if ok then
					stopped = stopped + 1
				end
		elseif option.Type == "Keybind" and option.State == true then
			option.State = false
			SafeCallback(option.Callback, false)
			stopped = stopped + 1
		end
	end

	self.LastStoppedFeatureCount = stopped
	return stopped
end

function Library:Destroy(reason)
	if self.Unloaded then
		return
	end

	self.Unloading = true
	self.LastUnloadReason = tostring(reason or "manual")

	if self.Config and typeof(self.Config.CancelPendingAutoLoad) == "function" then
		self.Config:CancelPendingAutoLoad()
	end

	self:StopAllFeatures()

	for _, callback in ipairs(self.UnloadCallbacks) do
		SafeCallback(callback, self.LastUnloadReason)
	end

	table.clear(self.UnloadCallbacks)
	self.Unloaded = true

	for index = #self.Dialogs, 1, -1 do
		local dialog = self.Dialogs[index]

		pcall(function()
			dialog:Close()
		end)
	end

	for index = #self.Notifications, 1, -1 do
		local notification = self.Notifications[index]

		pcall(function()
			notification.Maid:DoCleaning()
		end)
	end

	self.Notifications = {}
	self.Dialogs = {}

	for index = #self.Windows, 1, -1 do
		local window = self.Windows[index]

		if window and typeof(window.Destroy) == "function" then
			pcall(function()
				window:Destroy()
			end)
		end
	end

	self.Windows = {}
	self.Window = nil

	CancelAllTweens()
	LibraryMaid:DoCleaning()

	table.clear(self.Options)
	table.clear(self.Flags)
	table.clear(ThemeRegistry)
	table.clear(ThemeChangedListeners)
	table.clear(InterfaceListeners)

	FloatingButton = nil
	FloatingLabel = nil
	NotificationHolder = nil
	ScreenGui = nil

	for _, env in ipairs(GetSharedEnvironments()) do
		if rawget(env, "NUTHERAFROX_UI_LIBRARY") == self then
			rawset(env, "NUTHERAFROX_UI_LIBRARY", nil)
		end
	end

	return self
end

Library.Unload = Library.Destroy

--==================================================
-- GLOBAL INPUT (minimize key)
--==================================================

LibraryMaid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or Library.Unloaded then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if typeof(Settings.MinimizeKey) ~= "EnumItem" then
		return
	end

	if input.KeyCode ~= Settings.MinimizeKey then
		return
	end

	for id, option in pairs(Library.Options) do
		if
			option.Type == "Keybind"
			and id ~= "__NFMinimizeKey"
			and option.Value == Settings.MinimizeKey.Name
		then
			return
		end
	end

	Library:ToggleUI()
end))

--==================================================
-- INITIALISATION
--==================================================

CleanupPreviousInstances()

do
	local saved = ReadInterface()

	if saved then
		if saved.Theme then
			SetThemeInternal(saved.Theme)
		end

		if saved.CustomAccent then
			local accent = DecodeValue(saved.CustomAccent)
			if typeof(accent) == "Color3" then
				SetCustomAccentInternal(accent)
			end
		end

		if tonumber(saved.Scale) then
			Settings.Scale = Clamp(tonumber(saved.Scale), 0.5, 2)
		end

		if tonumber(saved.Transparency) then
			Settings.Transparency = Clamp(tonumber(saved.Transparency), 0, 0.9)
		end

		if typeof(saved.Animations) == "boolean" then
			Settings.Animations = saved.Animations
		end

		if saved.MinimizeKey then
			local ok, key = pcall(function()
				return Enum.KeyCode[saved.MinimizeKey]
			end)

			if ok and key then
				Settings.MinimizeKey = key
			end
		end

		if typeof(saved.Position) == "table" then
			local position = DecodeValue(saved.Position)

			if typeof(position) == "UDim2" then
				Settings.Position = position
			end
		end

		if typeof(saved.AutoLoad) == "string" and saved.AutoLoad ~= "" then
			Settings.AutoLoad = saved.AutoLoad
		end

		if typeof(saved.ConfigName) == "string" and saved.ConfigName ~= "" then
			Settings.ConfigName = saved.ConfigName
		end
	end
end

for _, env in ipairs(GetSharedEnvironments()) do
	rawset(env, "NUTHERAFROX_UI_LIBRARY", Library)
end

return Library
