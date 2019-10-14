local tooltips = {}
local featureOutput = {
	hideincombat = "hide in combat",
	offsets = "adjust the tooltip position",
	showonmouse = "anchor to the cursor",
	tooltiphorizontalpoint = "anchor the horizontal axis",
	tooltipverticalpoint = "anchor the vertical axis",
}
local defaults = {
	hideincombat = false,
	offsets = true,
	showonmouse = true,
	tooltiphorizontalpoint = "center",
	tooltipverticalpoint = "bottom",
}
local featureKey = {
	hideincombat = 1,
	offsets = 2,
	showonmouse = 3,
	tooltiphorizontalpoint = 4,
	tooltipverticalpoint = 5,
}
local featureAliases = {
	combat = "hideincombat",
	offset = "offsets",
	mouse = "showonmouse",
	vertical = "tooltiphorizontalpoint",
	horizontal = "tooltipverticalpoint",
	c = "hideincombat",
	o = "offsets",
	m = "showonmouse",
	v = "tooltiphorizontalpoint",
	h = "tooltipverticalpoint",
}
local features = {}

for feature in pairs(featureOutput) do
	features[feature] = true
end

local initEvent = "VARIABLES_LOADED"

local function initVars(self, reset, ...)
	if reset and reset ~= initEvent then
		TooltipOnMouse = {}
	else
		TooltipOnMouse = TooltipOnMouse or {}
	end
	TooltipOnMouse.hideInCombat = nil -- this element is no longer used; but it was before, so set it to nil to get rid of it.
	TooltipOnMouse.showOnMouse = nil -- this element is no longer used; but it was before, so set it to nil to get rid of it.
	TooltipOnMouse.x = TooltipOnMouse.x or 0
	TooltipOnMouse.y = TooltipOnMouse.y or 0
	TooltipOnMouse.features = TooltipOnMouse.features or {}
	for feature, state in pairs(defaults) do
		if (TooltipOnMouse.features[feature] == nil) then
			TooltipOnMouse.features[feature] = state
		end
	end
	self:UnregisterEvent(initEvent)
end

local f = CreateFrame("Frame")
f:RegisterEvent(initEvent)
f:SetScript("OnEvent", initVars)

local function SetPoint(tooltip)
	local mX, mY, oX, oY = 0, 0, 0, 0
	local point = "BOTTOMLEFT"
	if TooltipOnMouse.features.offsets then
		oX, oY = TooltipOnMouse.x, TooltipOnMouse.y
	elseif not TooltipOnMouse.features.showonmouse then -- if the control structure makes it to here, then .offsets is false, checking for it being false is redundant.
		oX, oY = -CONTAINER_OFFSET_X - 13,CONTAINER_OFFSET_Y
		point = "BOTTOMRIGHT"
	end
	-- Logic to support ANCHOR_CURSOR position calculation from right
	if TooltipOnMouse.features.showonmouse then
		local scale = UIParent:GetEffectiveScale()
		mX, mY = GetCursorPosition()
		mX, mY = mX / scale, mY / scale
		if TooltipOnMouse.features.tooltiphorizontalpoint == "right" then
			mX = mX - tooltip:GetWidth()
		elseif TooltipOnMouse.features.tooltiphorizontalpoint == "center" then
			mX = mX - (tooltip:GetWidth() / 2)
		end
		if TooltipOnMouse.features.tooltipverticalpoint == "top" then
			mY = mY - tooltip:GetHeight()
		elseif TooltipOnMouse.features.tooltipverticalpoint == "middle" then
			mY = mY - (tooltip:GetHeight() / 2)
		end
	end
	tooltip:ClearAllPoints()
	-- "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y -- the default behavior
	tooltip:SetPoint(point, "UIParent", point, oX + mX, oY + mY)
end

local TooltipUpdate = function(self, ...)
	if InCombatLockdown() and TooltipOnMouse.features.hideincombat then
		self:Hide()
	else
		if self.default then
			SetPoint(self)
		end
	end
end

local TooltipHide = function(self)
	self.default = nil
	self.unit = nil
end

--[[
local TooltipOnTooltipCleared = function(self, ...)
	print(self:GetName() .. " cleared.")
end
local TooltipOnTooltipSetUnit = function(self, ...)
	print(self:GetName() .. " unit.")
end

local TooltipOnEvent = function(self, event, ...) -- this may be overkill, but meh.
	if event == "CURSOR_UPDATE" and self:IsShown() and self:IsOwned(UIParent) then
		self:Hide()
	end
end
--]]

function GameTooltip_SetDefaultAnchor(tooltip, parent, ...)
	if InCombatLockdown() and TooltipOnMouse.features.hideincombat then
		tooltip:Hide()
	else
		if not parent then
			parent = GetMouseFocus()
		end
		if not parent or (parent.GetName and parent:GetName() == "WorldFrame") then
			parent = UIParent
		end
		
		-- Logic to support anchoring on cursor or UIParent
		if TooltipOnMouse.features.showonmouse then
			if parent.unit then -- If it's a unit frame, use _PRESERVE; otherwise, use _CURSOR -- this fixes the problem with the tooltip not showing when switching between UF's.
				tooltip:SetOwner(parent, "ANCHOR_PRESERVE")
			else
				tooltip:SetOwner(parent, "ANCHOR_CURSOR")
			end
		else
			tooltip:SetOwner(parent, "ANCHOR_NONE")
		end
		SetPoint(tooltip)
		tooltip.default = 0
		if not tooltips[tostring(tooltip)] then
			tooltips[tostring(tooltip)] = 0
			tooltip:HookScript("OnUpdate", TooltipUpdate)
--			tooltip:HookScript("OnHide", TooltipHide)
--			tooltip:HookScript("OnEvent", TooltipOnEvent)
--			tooltip:RegisterEvent("CURSOR_UPDATE")
--			tooltip:HookScript("OnTooltipCleared", TooltipOnTooltipCleared)
--			tooltip:HookScript("OnTooltipSetUnit", TooltipOnTooltipSetUnit)
		end
	end
end

SLASH_TooltipOnMouse1 = "/ttom"
SLASH_TooltipOnMouse2 = "/tooltiponmouse"
SlashCmdList["TooltipOnMouse"] = function(msg, editFrame, noOutput)
	msg = msg:trim():lower()
	local cmd, therest = msg:match("(.*)%s+(.*)")
	local success = ""
	if msg == "" then
		msg = "help"
	end
	for key, alias in pairs(featureAliases) do
		if msg == key then
			msg = alias
			break
		end
	end
	if msg == "hideincombat" then
		return SlashCmdList["TooltipOnMouse"]("feature combat", editFrame)
	elseif msg == "offsets" then
		return SlashCmdList["TooltipOnMouse"]("feature offset", editFrame)
	elseif msg == "showonmouse" then
		return SlashCmdList["TooltipOnMouse"]("feature mouse", editFrame)
	elseif msg == "tooltiphorizontalpoint" then
		if TooltipOnMouse.features.tooltiphorizontalpoint == "center" then
			TooltipOnMouse.features.tooltiphorizontalpoint = "left"
		elseif TooltipOnMouse.features.tooltiphorizontalpoint == "left" then
			TooltipOnMouse.features.tooltiphorizontalpoint = "right"
		elseif TooltipOnMouse.features.tooltiphorizontalpoint == "right" then
			TooltipOnMouse.features.tooltiphorizontalpoint = "center"
		end
		success = "horizontal"
	elseif msg == "tooltipverticalpoint" then
		if TooltipOnMouse.features.tooltipverticalpoint == "middle" then
			TooltipOnMouse.features.tooltipverticalpoint = "bottom"
		elseif TooltipOnMouse.features.tooltipverticalpoint == "bottom" then
			TooltipOnMouse.features.tooltipverticalpoint = "top"
		elseif TooltipOnMouse.features.tooltipverticalpoint == "top" then
			TooltipOnMouse.features.tooltipverticalpoint = "middle"
		end
		success = "vertical"
	elseif cmd == "feature" then
		if featureAliases[therest] then
			therest = featureAliases[therest]
		end
		if featureOutput[therest] then
			TooltipOnMouse.features[therest] = not TooltipOnMouse.features[therest]
			print("|cff00ff00The tooltip will", TooltipOnMouse.features[therest] and featureOutput[therest] .. " if told to do so." or "no longer " .. featureOutput[therest] .. " regardless of the settings.|r")
		else
			print('|cffff0000"' .. therest .. '"', "is not a valid feature.|r")
		end
		noOutput = 1
	elseif msg == "help" or cmd == "help" then
		if msg == "help" then
			print(SLASH_TooltipOnMouse2 .. " (|cff00ff00x|r, |cff00ff00y|r)")
			print(SLASH_TooltipOnMouse2 .. " X=|cff00ff00x|r Y=|cff00ff00y|r")
			print(SLASH_TooltipOnMouse2 .. " X=|cff00ff00x|r")
			print(SLASH_TooltipOnMouse2 .. " Y=|cff00ff00y|r")
			print(SLASH_TooltipOnMouse2 .. " |cff00ff00hideincombat|r\124\124|cff00ff00combat|r\124\124|cff00ff00c|r")
			print(SLASH_TooltipOnMouse2 .. " |cff00ff00showonmouse|r\124\124|cff00ff00mouse|r\124\124|cff00ff00m|r")
			print(SLASH_TooltipOnMouse2 .. " |cff00ff00offsets|r\124\124|cff00ff00offset|r\124\124|cff00ff00o|r")
			print(SLASH_TooltipOnMouse2 .. " |cff00ff00reset|r")
			print(SLASH_TooltipOnMouse2 .. " |cff00ff00help [feature]|r")
		end
		if (cmd == "help" and therest == "feature") or msg == "help" then
			print(SLASH_TooltipOnMouse2 .. " |cff00ff00feature|r [|cffff0000hideincombat|r\124\124|cffff0000offsets|r\124\124|cffff0000showonmouse|r\124\124|cffff0000combat|r\124\124|cffff0000offset|r\124\124|cffff0000mouse|r\124\124|cffff0000c|r\124\124|cffff0000o|r\124\124|cffff0000m|r]")
			if therest then
				print("  |cffff0000hideincombat|r, |cffff0000combat|r, |cffff0000c|r: toggle hiding while in combat. If off, show the tooltip while in combat regardless of the combat setting.")
				print("  |cffff0000offsets|r, |cffff0000offset|r, |cffff0000o|r: toggle moving the tooltip by (x, y). If off, the position will be attached to the mouse (or lower left corner) regardless of the offsets.")
				print("  |cffff0000showonmouse|r, |cffff0000mouse|r, |cffff0000m|r: toggle putting the tooltip on the mouse. If off, put the tooltip in the lower left corner and adjust its position based on the offsets.")
			end
		end
		if msg == "help" then
			print("  |cff00ff00x|r: the x offset - negative numbers go left, positive numbers go right.")
			print("  |cff00ff00y|r: the y offset - negative numbers go down, positive numbers go up.")
			print("  |cff00ff00hideincombat|r\124\124|cff00ff00combat|r\124\124|cff00ff00c|r: alias for '|cff00ff00feature|r |cffff0000hideincombat|r\124\124|cffff0000combat|r\124\124|cffff0000c|r'.")
			print("  |cff00ff00showonmouse|r\124\124|cff00ff00mouse|r\124\124|cff00ff00m|r: alias for '|cff00ff00feature|r |cffff0000showonmouse|r\124\124|cffff0000mouse|r\124\124|cffff0000m|r'.")
			print("  |cff00ff00offsets|r\124\124|cff00ff00offset|r\124\124|cff00ff00o|r: alias for '|cff00ff00feature|r |cffff0000offsets|r\124\124|cffff0000offset|r\124\124|cffff0000o|r'.")
			print("  |cff00ff00feature|r: toggle the state of the given feature.")
			print("  |cff00ff00reset|r: restore default settings.")
			print("  |cff00ff00help [feature]|r: show this crap or details for the 'feature' option if given.")
			print(SLASH_TooltipOnMouse1 .. " (alias)")
		end
		noOutput = 1
	elseif msg == "reset" then
		initVars(f, 1)
		noOutput = 1
	else
		local x, y = msg:match("%(%s*([-]*%d*)%s*,%s*([-]*%d*)%s*%)")
		if x and y then
			TooltipOnMouse.x = tonumber(x)
			TooltipOnMouse.y = tonumber(y)
			success = "coords"
		else
			x = msg:match("x%s*=%s*([-]*%d*)%s*")
			y = msg:match("y%s*=%s*([-]*%d*)%s*")
			if y then
				TooltipOnMouse.y = tonumber(y)
				success = "coords"
			end
			if x then
				TooltipOnMouse.x = tonumber(x)
				success = "coords"
			end
		end
	end
	if not noOutput then
		if success == "coords" then
			print("|cff00ff00Offsets changed to (" .. TooltipOnMouse.x .. ", " .. TooltipOnMouse.y .. ")|r")
		elseif success == "horizontal" then
			print("|cff00ff00horizontal point changed to '" .. TooltipOnMouse.features.tooltiphorizontalpoint .. "'|r")
		elseif success == "vertical" then
			print("|cff00ff00Vertical point changed to '" .. TooltipOnMouse.features.tooltipverticalpoint .. "'|r")
		else
			print("|cff00ff00Current offsets are (" .. TooltipOnMouse.x .. ", " .. TooltipOnMouse.y .. ")|r")
			print("|cff00ff00Current vertical and horizontal points are " .. TooltipOnMouse.features.tooltipverticalpoint .. " and " .. TooltipOnMouse.features.tooltiphorizontalpoint .. "|r")
		end
	end
	TooltipOnMouseConfig_OnLoad(TooltipOnMouseConfig)
end

function TooltipOnMouseConfig_OnTextChanged(self, ...)
	local off = self:GetName():sub(-1):lower()
	local text = self:GetText()
	if not tonumber(text) and text ~= "-" then
		text = self.oldValue
		self:SetText(text)
	end
	TooltipOnMouse[off] = tonumber(text)
	self.oldValue = text
end

function TooltipOnMouseConfig_OnClick(self, ...)
	local combat, x, y
	x = _G[self:GetParent():GetName() .. "OffsetX"]
	y = _G[self:GetParent():GetName() .. "OffsetY"]
	EditBox_ClearFocus(x)
	EditBox_ClearFocus(y)
	if self.feature == "tooltiphorizontalpoint" or self.feature == "tooltipverticalpoint" then
		SlashCmdList["TooltipOnMouse"](self.feature, nil, 1)
	elseif self:GetChecked() then
		TooltipOnMouse.features[self.feature] = true
		if self.linked then
			self.linked:SetTextColor(1, 1, 1)
		end
	else
		TooltipOnMouse.features[self.feature] = false
		if self.linked then
			self.linked:SetTextColor(.5, .5, .5)
		end
	end
	if self.feature == "offsets" then
		x:EnableMouse(TooltipOnMouse.features[self.feature])
		y:EnableMouse(TooltipOnMouse.features[self.feature])
		x:SetAlpha(TooltipOnMouse.features[self.feature] and 1 or .5)
		y:SetAlpha(TooltipOnMouse.features[self.feature] and 1 or .5)
	end
end

function TooltipOnMouseConfig_OnLoad(self)
	local t, c, mouse, combat, x, y, cR, cG, cB
	x = _G[self:GetName() .. "OffsetX"]
	y = _G[self:GetName() .. "OffsetY"]
	local i
	for feature, featureText in pairs(featureOutput) do
		i = featureKey[feature]
		t = _G[self:GetName() .. "Feature" .. i]
		c = _G[self:GetName() .. "Feature" .. i .. "Checked"]
		t:SetText(featureText:sub(1, 1):upper() .. featureText:sub(2) .. ":")
		if c then -- it's a CheckButton, do this
			if feature == "offsets" then
				c.linked = _G[self:GetName() .. "Offsets"]
			end
			if TooltipOnMouse.features[feature] then
				if feature == "offsets" then
					x:EnableMouse(true)
					y:EnableMouse(true)
				end
				c:SetChecked(true)
				cR,cG,cB = 1,1,1
			else
				if feature == "offsets" then
					x:EnableMouse(false)
					y:EnableMouse(false)
				end
				c:SetChecked(false)
				cR,cG,cB = .5,.5,.5
			end
			if c.linked then
				c.linked:SetTextColor(cR,cG,cB)
			end
	
			c.feature = feature
			x:SetAlpha(TooltipOnMouse.features[feature] and 1 or .5)
			y:SetAlpha(TooltipOnMouse.features[feature] and 1 or .5)
		elseif feature == "tooltiphorizontalpoint" or feature == "tooltipverticalpoint" then
			c = _G[self:GetName() .. "Feature" .. i .. "Button"]
			if c then
				c.feature = feature
				c:SetText(TooltipOnMouse.features[feature]:sub(1, 1):upper() .. TooltipOnMouse.features[feature]:sub(2))
			end
		end
	end
	x:SetText(TooltipOnMouse.x or 0)
	y:SetText(TooltipOnMouse.y or 0)
end
