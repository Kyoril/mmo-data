-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
local A = AnchorPoint;

function Wayfinder_SearchText(value)
	local folded = value:lower():gsub(utf8.charpattern, function(letter)
		local point = utf8.codepoint(letter);
		if (point >= 0xC0 and point <= 0xDE and point ~= 0xD7) or (point >= 0x410 and point <= 0x42F) then
			return utf8.char(point + 32);
		end
		if point == 0x401 then return "ё"; end
		if point == 0x152 then return "œ"; end
		if point == 0x1E9E then return "ß"; end
		return letter;
	end);
	return folded;
end

local function MakeIcon(parent, name, width, inset)
	local icon = IconTemplate:Clone();
	icon:SetProperty("MousePassThrough", "true");
	icon:SetProperty("Clickable", "false");
	icon:SetProperty("Icon", Wayfinder_Art(name));
	icon:SetSize(width, width);
	parent:AddChild(icon);
	icon:SetAnchor(A.LEFT, A.LEFT, parent, inset);
	icon:SetAnchor(A.V_CENTER, A.V_CENTER, parent, 0);
end

function Wayfinder_CreateSearch(parent, top, inset, labelKey, onSearch)
	local field = WayfinderSearchField:Clone();
	parent:AddChild(field);
	field:SetAnchor(A.TOP, A.TOP, parent, top);
	field:SetAnchor(A.LEFT, A.LEFT, parent, inset);
	field:SetAnchor(A.RIGHT, A.RIGHT, parent, -inset);
	field:SetHeight(52);
	field:SetTextAreaOffset(Rect(58, 0, 52, 0));
	MakeIcon(field, "GlyphSearch", 30, 14);

	local placeholder = TextSmall:Clone();
	placeholder:SetProperty("MousePassThrough", "true");
	placeholder:SetProperty("Clickable", "false");
	placeholder:SetProperty("Font", "SmallLabelFont");
	placeholder:SetProperty("TextColor", "FFAAAFAF");
	placeholder:SetProperty("VertAlign", "CENTER");
	placeholder:SetText(Localize(labelKey));
	field:AddChild(placeholder);
	placeholder:SetAnchor(A.LEFT, A.LEFT, field, 58);
	placeholder:SetAnchor(A.RIGHT, A.RIGHT, field, -50);
	placeholder:SetAnchor(A.TOP, A.TOP, field, 0);
	placeholder:SetAnchor(A.BOTTOM, A.BOTTOM, field, 0);

	local clear = ChatButton:Clone();
	WayfinderUtility:CopyVisuals(clear);
	clear:SetProperty("Icon", Wayfinder_Art("GlyphClose"));
	clear:SetSize(46, 50);
	field:AddChild(clear);
	clear:SetAnchor(A.RIGHT, A.RIGHT, field, -4);
	clear:SetAnchor(A.V_CENTER, A.V_CENTER, field, 0);
	clear:SetClickedHandler(function()
		field:SetText("");
		field:CaptureInput();
	end);
	clear:Hide();
	field:SetOnTextChangedHandler(function(self)
		local text = self:GetText();
		if text == "" then
			placeholder:Show();
			clear:Hide();
		else
			placeholder:Hide();
			clear:Show();
		end
		onSearch(Wayfinder_SearchText(text:match("^%s*(.-)%s*$")));
	end);
	return field;
end
