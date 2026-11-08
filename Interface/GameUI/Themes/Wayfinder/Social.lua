-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
local A = AnchorPoint;
local groups = {};
local rowHeight = 96;
local textureDir = "Interface/GameUI/Themes/Wayfinder/Textures/";
local classIcons = { Warrior = true, Mage = true, Scout = true, Cleric = true, Acolyte = true };

local function Place(frame, parent, x, y, width, height)
	frame:ClearAnchors();
	frame:SetWidth(width);
	frame:SetHeight(height);
	frame:SetAnchor(A.LEFT, A.LEFT, parent, x);
	frame:SetAnchor(A.TOP, A.TOP, parent, y);
end

local function AddLabel(parent, key)
	local label = TextSmall:Clone();
	label:SetProperty("Clickable", "false");
	label:SetProperty("MousePassThrough", "true");
	label:SetProperty("Font", "FriendDetailFont");
	label:SetProperty("TextColor", "FFCCB388");
	label:SetProperty("VertAlign", "CENTER");
	label:SetText(Localize(key));
	parent:AddChild(label);
	return label;
end

function WayfinderSocial_Setup(window, inviteClicked)
	window:SetHeight(1080);
	local title = window:GetChild(0);
	title:SetText(Localize("WAYFINDER_SOCIAL"));
	FriendListSummary:SetAnchor(A.TOP, A.BOTTOM, title, 20);
	FriendListSummary:SetProperty("TextColor", "FFADB7BD");
	FriendListEmptyLabel:SetAnchor(A.RIGHT, A.RIGHT, FriendListFrame, -48);
	WayfinderEmpty:CopyVisuals(FriendListFrame);
	WayfinderEmpty:CopyVisuals(FriendActionButtonsFrame);

	local divider = WayfinderRule:Clone();
	FriendActionButtonsFrame:AddChild(divider);
	Place(divider, FriendActionButtonsFrame, 24, 6, 880, 2);

	local groupInvite = GlueButton:Clone();
	FriendActionButtonsFrame:AddChild(groupInvite);
	groupInvite:SetClickedHandler(inviteClicked);
	local buttons = { FriendInviteButton, FriendWhisperButton, groupInvite, FriendRemoveButton };
	local labels = { "FRIEND_INVITE", "WAYFINDER_WHISPER", "WAYFINDER_INVITE", "WAYFINDER_REMOVE" };
	for i, button in ipairs(buttons) do
		WayfinderButton:CopyVisuals(button);
		button:SetProperty("Font", "DefaultSmall");
		button:SetText(Localize(labels[i]));
		Place(button, FriendActionButtonsFrame, 24 + (i - 1) * 224, 25, 208, 68);
	end

	for i = 0, GameUITheme.FriendsVisibleRows - 1 do
		local row = FriendListContent:GetChild(i);
		WayfinderFriendRow:CopyVisuals(row);
		row:SetHeight(rowHeight);
		local icon = IconTemplate:Clone();
		icon:SetProperty("Clickable", "false");
		icon:SetProperty("MousePassThrough", "true");
		row:AddChild(icon);
		Place(icon, row, 14, 20, 56, 56);

		local dot, name, level, detail = row:GetChild(0), row:GetChild(1), row:GetChild(2), row:GetChild(4);
		IconTemplate:CopyVisuals(dot);
		Place(dot, row, 73, 37, 22, 22);
		for _, label in ipairs({ name, detail }) do
			label:ClearAnchors();
			label:SetAnchor(A.LEFT, A.LEFT, row, 104);
			label:SetAnchor(A.RIGHT, A.RIGHT, row, -174);
			label:SetProperty("HorzAlign", "LEFT");
			label:SetProperty("VertAlign", "CENTER");
		end
		name:SetHeight(34);
		detail:SetHeight(25);
		detail:SetAnchor(A.TOP, A.TOP, row, 51);
		level:ClearAnchors();
		level:SetWidth(148);
		level:SetHeight(46);
		level:SetAnchor(A.RIGHT, A.RIGHT, row, -20);
		level:SetAnchor(A.V_CENTER, A.V_CENTER, row, 0);
		level:SetProperty("HorzAlign", "RIGHT");
		level:SetProperty("VertAlign", "CENTER");
	end
	for i = GameUITheme.FriendsVisibleRows, FriendListContent:GetChildCount() - 1 do
		FriendListContent:GetChild(i):Hide();
	end
	for _, online in ipairs({ true, false }) do
		local label = AddLabel(FriendListContent, online and "FRIEND_ONLINE" or "FRIEND_OFFLINE");
		local rule = WayfinderRule:Clone();
		label:AddChild(rule);
		rule:SetHeight(2);
		rule:SetAnchor(A.LEFT, A.LEFT, label, 190);
		rule:SetAnchor(A.RIGHT, A.RIGHT, label, -12);
		rule:SetAnchor(A.V_CENTER, A.V_CENTER, label, 0);
		groups[online] = label;
	end
	return groupInvite;
end

function WayfinderSocial_Update(friends, offset)
	for _, label in pairs(groups) do
		label:Hide();
	end

	local y, previousOnline = 0, nil;
	for i = 1, GameUITheme.FriendsVisibleRows do
		local friend = friends[offset + i];
		if not friend then
			break;
		end
		if friend.online ~= previousOnline then
			local label = groups[friend.online];
			label:SetHeight(35);
			label:SetAnchor(A.LEFT, A.LEFT, FriendListContent, 12);
			label:SetAnchor(A.RIGHT, A.RIGHT, FriendListContent, 0);
			label:SetAnchor(A.TOP, A.TOP, FriendListContent, y);
			label:Show();
			y = y + 39;
			previousOnline = friend.online;
		end

		local row = FriendListContent:GetChild(i - 1);
		row:SetAnchor(A.TOP, A.TOP, FriendListContent, y);
		row:GetChild(3):Hide();
		row:GetChild(0):SetProperty("Icon", textureDir .. (friend.online and "Online.htex" or "Offline.htex"));
		local name, level, detail, icon = row:GetChild(1), row:GetChild(2), row:GetChild(4), row:GetChild(5);
		name:SetProperty("TextColor", friend.online and "FFF3EAD8" or "FFADB7BF");
		name:SetAnchor(A.TOP, A.TOP, row, friend.online and 15 or 31);
		level:SetProperty("TextColor", "FFCBBC9D");
		local className = friend.className or "";
		detail:SetText(friend.online and className or "");
		detail:SetProperty("TextColor", "FFACB9C4");
		icon:SetProperty("Icon", classIcons[className] and (textureDir .. className .. ".htex") or "Interface/Icons/FriendMarker.htex");
		icon:SetOpacity(friend.online and 1 or 0.45);
		if friend.online then
			level:Show();
		else
			level:Hide();
		end
		y = y + rowHeight;
	end
end
