-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
local A = AnchorPoint;
local modeMenu = "WAYFINDER_CHAT_MODE";
local modes = { "SAY", "YELL", "PARTY", "RAID", "GUILD", "WHISPER", "EMOTE" };

local function SelectMode(mode, target)
	ChatType = mode;
	if mode == "WHISPER" then
		ChatFrame_WhisperTarget = target;
	elseif mode == "CHANNEL" then
		ChatFrame_ChannelTarget = target;
	end
	ChatEdit_UpdateHeader();
	ChatFrame_ResetActivity();
	ChatInput:CaptureInput();
end

local function ModeItems()
	local items = {};
	local inGroup = GetPartySize() > 0;
	local inGuild = IsInGuild();
	for _, mode in ipairs(modes) do
		local chatMode = mode;
		local available = chatMode ~= "PARTY" and chatMode ~= "RAID" or inGroup;
		items[#items + 1] = {
			text = Localize("CHAT_TYPE_" .. chatMode),
			enabled = available and (chatMode ~= "GUILD" or inGuild),
			visual = ChatType == chatMode and WayfinderMenuSelected or nil,
			callback = function()
				if chatMode == "WHISPER" then
					local dialog = StaticDialog_Show("WAYFINDER_WHISPER_WHO");
					if dialog and dialog.editBox then
						dialog.editBox:SetText(ChatFrame_WhisperTarget or ChatFrame_ReplyTarget or "");
					end
				else
					SelectMode(chatMode);
				end
			end,
		};
	end
	for i = 1, GetNumChannels() do
		local channel = GetChannelInfo(i);
		if channel then
			local id = i;
			items[#items + 1] = {
				text = id .. ". " .. Localize(channel.name),
				visual = ChatType == "CHANNEL" and ChatFrame_ChannelTarget == id and WayfinderMenuSelected or nil,
				callback = function() SelectMode("CHANNEL", id); end,
			};
		end
	end
	return items;
end

function WayfinderChat_CloseModeMenu()
	if ContextMenu_IsShown(modeMenu) then
		ContextMenu_Hide();
		return true;
	end
	return false;
end

function WayfinderChat_Update()
	if ChatFrame:IsAtBottom() then
		ChatScrollEndButton:Hide();
	else
		ChatScrollEndButton:Show();
	end
end

function WayfinderChat_Setup()
	ChatBubbleButton:Hide();
	ChatScrollUpButton:Hide();
	ChatScrollDownButton:Hide();

	WayfinderChatRail:CopyVisuals(ChatInputFrame);
	ChatInputFrame:SetAnchor(A.BOTTOM, A.BOTTOM, GameParent, -28);
	ChatInputFrame:SetAnchor(A.LEFT, A.LEFT, GameParent, 28);
	ChatInputFrame:SetHeight(62);
	ChatFrame:SetProperty("Font", "WayfinderChatFont");
	ChatInput:SetProperty("Font", "WayfinderChatFont");
	ChatInputHeader:SetProperty("Font", "WayfinderChatFont");
	ChatInputHeader:SetProperty("MousePassThrough", "true");
	ChatInputHeader:SetAnchor(A.LEFT, A.LEFT, ChatInputFrame, 18);

	ChatFrame:ClearAnchors();
	ChatFrame:SetHeight(260);
	ChatFrame:SetAnchor(A.LEFT, A.LEFT, ChatInputFrame, 4);
	ChatFrame:SetAnchor(A.RIGHT, A.RIGHT, ChatInputFrame, -30);
	ChatFrame:SetAnchor(A.BOTTOM, A.TOP, ChatInputFrame, -10);

	WayfinderUtility:CopyVisuals(ChatScrollEndButton);
	ChatScrollEndButton:SetProperty("Icon", Wayfinder_Art("GlyphChevron"));
	ChatScrollEndButton:ClearAnchors();
	ChatScrollEndButton:SetFrameLevel(1);
	ChatScrollEndButton:SetSize(38, 38);
	ChatScrollEndButton:SetAnchor(A.RIGHT, A.RIGHT, ChatInputFrame, 0);
	ChatScrollEndButton:SetAnchor(A.BOTTOM, A.BOTTOM, ChatFrame, 0);

	local picker = ChatButton:Clone();
	picker:SetFrameLevel(-1);
	ChatInputFrame:AddChild(picker);
	WayfinderChatMode:CopyVisuals(picker);
	picker:ClearAnchors();
	picker:SetAnchor(A.LEFT, A.LEFT, ChatInputFrame, 5);
	picker:SetAnchor(A.RIGHT, A.RIGHT, ChatInputHeader, 47);
	picker:SetAnchor(A.TOP, A.TOP, ChatInputFrame, 5);
	picker:SetAnchor(A.BOTTOM, A.BOTTOM, ChatInputFrame, -5);
	picker:SetClickedHandler(function()
		ContextMenu_Toggle(modeMenu);
		ChatInput:CaptureInput();
	end);
	ChatInputClipper:SetAnchor(A.LEFT, A.RIGHT, picker, 12);
	ChatInputClipper:SetAnchor(A.RIGHT, A.RIGHT, ChatInputFrame, -14);

	local arrow = IconTemplate:Clone();
	arrow:SetProperty("Clickable", "false");
	arrow:SetProperty("MousePassThrough", "true");
	arrow:SetProperty("Icon", Wayfinder_Art("GlyphChevron"));
	picker:AddChild(arrow);
	arrow:SetSize(31, 31);
	arrow:SetAnchor(A.RIGHT, A.RIGHT, picker, -8);
	arrow:SetAnchor(A.V_CENTER, A.V_CENTER, picker, 0);

	WayfinderPanel:CopyVisuals(ContextMenu);
	WayfinderMenuRow:CopyVisuals(ContextMenuButtonTemplate);
	RegisterContextMenu(modeMenu, {
		items = ModeItems,
		above = picker,
		onDismiss = function()
			if ChatInputFrame:IsVisible() and not StaticDialog:IsVisible() then
				ChatInput:CaptureInput();
			end
		end,
	});
	StaticDialogs["WAYFINDER_WHISPER_WHO"] = {
		text = Localize("WAYFINDER_WHISPER_WHO"),
		button1 = Localize("ACCEPT"),
		button2 = Localize("CANCEL"),
		hasEditBox = true,
		timeout = 0,
		exclusive = false,
		OnAccept = function()
			local name = StaticDialog.editBox:GetText():match("^%s*(%S+)%s*$");
			if name then
				SelectMode("WHISPER", name);
			else
				ChatInput:CaptureInput();
			end
		end,
		OnCancel = function() ChatInput:CaptureInput(); end,
	};
	WayfinderChat_Update();
end
