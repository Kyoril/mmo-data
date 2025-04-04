
ErrorTimer = 0.0

ItemQualityColors = {};
ItemQualityColors[0] = "FF9C9C9C"; -- Poor
ItemQualityColors[1] = "FFFFFFFF"; -- Common
ItemQualityColors[2] = "FF20FF00"; -- Uncommon
ItemQualityColors[3] = "FF0070DD"; -- Rare
ItemQualityColors[4] = "FFA335EE"; -- Epic
ItemQualityColors[5] = "FFFF8000"; -- Legendary

UIPanelWindows = {};
UIPanelWindows["GameMenu"] = { area = "center", pushable = 0 };
UIPanelWindows["SpellBook"] = { area = "left", pushable = 0 };
UIPanelWindows["CharacterWindow"] = { area = "left", pushable = 2 };
UIPanelWindows["TrainerFrame"] = { area = "left", pushable = 0 };
UIPanelWindows["VendorFrame"] = { area = "left", pushable = 0 };
UIPanelWindows["LootFrame"] = { area = "left", pushable = 7 };
UIPanelWindows["QuestFrame"] = { area = "left", pushable = 0 };
UIPanelWindows["QuestLogFrame"] = { area = "left", pushable = 0 };
UIPanelWindows["GuildFrame"] = { area = "left", pushable = 1 };

local menuOffsetY = BUTTON_V_PADDING

function SidePanel_OnClose(closeButton)
	-- Parent of the button is the titlebar, whose parent is the frame
	HideUIPanel(closeButton:GetParent():GetParent());
end

MAX_ERROR_MESSAGES = 3;
ERROR_HOLD_TIME = 4;

function GameParent_OnPartyInviteRequest(gameParent, inviterName)
	ChatFrame:AddMessage(string.format(Localize("INVITATION"), inviterName), 1.0, 1.0, 0.0);
	StaticDialog_Show("PARTY_INVITE", inviterName);
end

function GameParent_OnGuildInviteRequest(gameParent, inviterName, guildName)
	ChatFrame:AddMessage(string.format(Localize("GUILD_INVITATION"), inviterName, guildName), 1.0, 1.0, 0.0);
	StaticDialog_Show("GUILD_INVITE", inviterName, guildName);
end

function GameParent_OnRandomRollResult(self, playerName, min, max, result)
	ChatFrame:AddMessage(string.format(Localize("RANDOM_ROLL_RESULT"), playerName, result, min, max), 1.0, 1.0, 0.0);
end

function UIErrorFrame_OnLoad(this)
	for i = 1, MAX_ERROR_MESSAGES do
		local text = _G["ErrorText"..i];
		text.userData = nil;
		text:Hide();
	end

	this:RegisterEvent("SYSMSG", UIErrorFrame_OnSysMessage);
	this:RegisterEvent("UI_INFO_MESSAGE", UIErrorFrame_OnInfoMessage);
	this:RegisterEvent("UI_ERROR_MESSAGE", UIErrorFrame_OnErrorMessage);
end

function UIErrorFrame_SetMessage(text, message, color)
	text.userData = ERROR_HOLD_TIME;
	text:SetProperty("TextColor", color);
	text:SetText(message);
	text:Show();
end

function UIErrorText_OnUpdate(this, elapsed)
	if this.userData then
		this.userData = this.userData - elapsed;
	end
end

function UIErrorFrame_AddMessage(message, color)
	for i = 1, MAX_ERROR_MESSAGES do
		local text = _G["ErrorText"..i];
		if not text.userData then
			UIErrorFrame_SetMessage(text, message, color);
			return;
		end
	end

	-- No free text fields, so shift everything up
	for i = 1, MAX_ERROR_MESSAGES - 1 do
		local text = _G["ErrorText"..i];
		local nextText = _G["ErrorText"..(i + 1)];
		text.userData = nextText.userData;
		text:SetProperty("TextColor", nextText:GetProperty("TextColor"));
		text:SetText(nextText:GetText());
	end

	-- Add the last message
	UIErrorFrame_SetMessage(_G["ErrorText"..MAX_ERROR_MESSAGES], message, color);
end

function UIErrorFrame_OnSysMessage(this, msg)
	UIErrorFrame_AddMessage(msg, "FFFFFF00");
end

function UIErrorFrame_OnInfoMessage(this, msg)
	UIErrorFrame_AddMessage(msg, "FFFFFF00");
end

function UIErrorFrame_OnErrorMessage(this, msg)
	UIErrorFrame_AddMessage(msg, "FFFF1900");
end

function UIErrorFrame_OnUpdate(this, elapsed)
	local text = _G["ErrorText1"];
	if not text.userData then
		return;
	end

	if text.userData <= 0 then
		for i = 1, MAX_ERROR_MESSAGES - 1 do
			local current = _G["ErrorText"..i];
			local nextText = _G["ErrorText"..(i + 1)];
			current.userData = nextText.userData;
			current:SetProperty("TextColor", nextText:GetProperty("TextColor"));
			current:SetText(nextText:GetText());

			if current.userData == nil then
				current:Hide();
			end
		end

		local lastText = _G["ErrorText"..MAX_ERROR_MESSAGES];
		lastText.userData = nil;
		lastText:Hide();
	end
end

function SidePanel_OnLoad(self)
	self.titleBar = self:GetChild(0);
	self.titleBar.closeButton = self.titleBar:GetChild(0);
	self.titleBar.closeButton:SetClickedHandler(SidePanel_OnClose);
end

function GameParent_OnSpellError(self, spellError)
	UIErrorFrame_OnErrorMessage(ErrorFrame, Localize(spellError));
end

function GameParent_OnGameError(self, gameError)
	UIErrorFrame_OnErrorMessage(ErrorFrame, Localize(gameError));
end

function GameParent_OnAttackSwingError(self, attackSwingError)
	UIErrorFrame_OnErrorMessage(ErrorFrame, Localize(attackSwingError));
end

function GameParent_OnPlayerDead()
    CloseAllWindows(true);
    StaticDialog_Show("DEATH");
end

function GameParent_OnHoveredObjectChanged(self)
	local mouseOverUnit = GetUnit("mouseover");
	if ( not mouseOverUnit ) then
		GameTooltip_FadeOut(1.0, 1.0);
		return;
	end

    GameTooltip_Clear();
	GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, self, -256.0);
    GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, self, -32.0);

	local color = "FFFFD100";
	if (mouseOverUnit:IsFriendly()) then
		color = "FF00FF00";
	elseif (mouseOverUnit:IsHostile()) then
		color = "FFFF0000";
	end

    GameTooltip_AddLine(mouseOverUnit:GetName(), TOOLTIP_LINE_LEFT, color);
	if (mouseOverUnit:GetType() == "PLAYER") then
		GameTooltip_AddLine(Localize("PLAYER"), TOOLTIP_LINE_LEFT, "FFFFFFFF");
	end

	GameTooltip_AddLine(string.format(Localize("LEVEL_FORMAT"), mouseOverUnit:GetLevel()), TOOLTIP_LINE_LEFT, "FFFFFFFF");
    GameTooltip:Show();
end

function GameParent_OnLoad(self)
    self:RegisterEvent("GAME_ERROR", GameParent_OnGameError);
    self:RegisterEvent("PLAYER_SPELL_CAST_FAILED", GameParent_OnSpellError);
    self:RegisterEvent("ATTACK_SWING_ERROR", GameParent_OnAttackSwingError);
    self:RegisterEvent("PLAYER_DEAD", GameParent_OnPlayerDead);
	self:RegisterEvent("PARTY_INVITE_REQUEST", GameParent_OnPartyInviteRequest);
	self:RegisterEvent("RANDOM_ROLL_RESULT", GameParent_OnRandomRollResult);
	self:RegisterEvent("HOVERED_OBJECT_CHANGED", GameParent_OnHoveredObjectChanged);
	self:RegisterEvent("GUILD_INVITE_REQUEST", GameParent_OnGuildInviteRequest);
end

function ShowUIPanel(frame, force)
	if ( not frame or frame:IsVisible() ) then
		return;
	end

	local info = UIPanelWindows[frame:GetName()];
	if ( not info ) then
		frame:Show();
		return;
	end

	local player = GetUnit("player");
	if ( player:GetHealth() <= 0 and (info.area ~= center) and (frame ~= SuggestFrame) ) then
		return;
	end

	-- If we have a full-screen frame open, ignore other non-fullscreen open requests
	if ( GetFullScreenFrame() and (info.area ~= "full") ) then
		if ( force ) then
			SetFullScreenFrame(nil);
		else
			return;
		end
	end

	-- If we have a "center" frame open, only listen to other "center" open requests
	local centerFrame = GetCenterFrame();
	local centerInfo = nil;
	if ( centerFrame ) then
		centerInfo = UIPanelWindows[centerFrame:GetName()];
		if ( centerInfo and (centerInfo.area == "center")  and (info.area ~= "center") ) then
			if ( force ) then
				SetCenterFrame(nil);
			else
				return;
			end
		end
	end
	
	if ( info.area == "full" ) then
		CloseAllWindows();
		SetFullScreenFrame(frame);
		return;
	end
	
	if ( info.area == "center" ) then
		SetCenterFrame(frame, 1);
		return;
	end

	local leftFrame = GetLeftFrame();
	if ( not leftFrame ) then
		SetLeftFrame(frame);
		return;
	end

	if ( centerFrame and centerInfo) then
		if ( (info.pushable > 0) and (info.pushable < centerInfo.pushable) ) then
			MovePanelToLeft();
			SetCenterFrame(frame);
		else
			SetLeftFrame(frame);
		end
		return;
	end

	local leftInfo = UIPanelWindows[leftFrame:GetName()];
	if ( not leftInfo or (leftInfo.pushable <= 0) ) then
		if ( info.pushable > 0 ) then
			SetCenterFrame(frame);
		else
			SetLeftFrame(frame);
		end
		return;
	end

	if ( (info.pushable > 0) and (info.pushable < leftInfo.pushable) ) then
		SetCenterFrame(frame);
	else
		MovePanelToCenter();
		SetLeftFrame(frame);
	end
end

function HideUIPanel(frame)
	if ( not frame or not frame:IsVisible() ) then
		return;
	end

	if ( frame == GetFullScreenFrame() ) then
		SetFullScreenFrame(nil);
		return;
	end

	-- If we're hiding the center frame, just hide it
	if ( frame == GetCenterFrame() ) then
		SetCenterFrame(nil);
		return;
	end
	
	-- If we're hiding the left frame, move the center frame back left, unless it's a native center frame
	if ( frame == GetLeftFrame() ) then
		local centerFrame = GetCenterFrame();

		if ( centerFrame ) then
			local info = UIPanelWindows[centerFrame:GetName()];
			if ( info and (info.area == "left") ) then
				MovePanelToLeft();
				return;
			end
		end

		SetLeftFrame(nil);
		return;
	end

	frame:Hide();
end

function SetLeftFrame(frame)
	local oldFrame = GameParent.left;
	GameParent.left = frame;

	if ( oldFrame ) then
		oldFrame:Hide();
	end	

	if ( frame ) then
		frame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, GameParent, 0.0);
		frame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, GameParent, 300.0);
		frame:Show();
	end
end

function SetCenterFrame(frame, skipSetPoint)
	local oldFrame = GameParent.center;
	GameParent.center = frame;

	if ( oldFrame ) then
		oldFrame:Hide();
	end

	if ( frame ) then
		frame:Show();
		if ( not skipSetPoint ) then
            frame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, GameParent, 960.0);
            frame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, GameParent, 300.0);
		end
	end
	
end

function SetFullScreenFrame(frame)
	local oldFrame = GameParent.fullscreen;
	GameParent.fullscreen = frame;

	if ( oldFrame ) then
		oldFrame:Hide();
	end

	if ( frame ) then
		GameParent:Hide();
		frame:Show();
	else
		GameParent:Show();
	end
end

function MovePanelToLeft()
	if ( GameParent.center ) then
		SetLeftFrame(nil);
        
        GameParent.center:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, GameParent, 0.0);
        GameParent.center:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, GameParent, 300.0);
        
		GameParent.left = GameParent.center
		GameParent.center = nil;
	end
end

function MovePanelToCenter()
	if ( GameParent.left ) then
		SetCenterFrame(nil);
        
        GameParent.left:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, GameParent, 960.0);
        GameParent.left:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, GameParent, 300.0);
        
		GameParent.center = GameParent.left
		GameParent.left = nil;
	end
end

function CanOpenPanels()
	local player = GetUnit("player");
	if ( player:GetHealth() <= 0 ) then
		return nil;
	end

	local centerFrame = GetCenterFrame();
	if ( not centerFrame ) then
		return 1;
	end

	local info = UIPanelWindows[centerFrame:GetName()];
	if ( info and (info.area == "center") ) then
		return nil;
	end

	return 1;
end

function GetFullScreenFrame()
	return GameParent.fullscreen;
end

function GetCenterFrame()
	return GameParent.center;
end

function GetLeftFrame()
	return GameParent.left;
end

function CloseWindows(ignoreCenter)
	-- This function will close all frames that are not the current frame
	local leftFrame = GetLeftFrame();
	local centerFrame = GetCenterFrame();
	local fullScreenFrame = GetFullScreenFrame();
	local found = leftFrame or centerFrame or fullScreenFrame;

	HideUIPanel(leftFrame);
	HideUIPanel(fullScreenFrame);

	if ( centerFrame ) then        
		local info = UIPanelWindows[centerFrame:GetName()];
		if ( not info or (info.area ~= "center") or not ignoreCenter ) then
			HideUIPanel(centerFrame);
		end
	end

	return found;
end

function CloseAllWindows(ignoreCenter)
	local windowsVisible = nil;
    windowsVisible = CloseWindows(ignoreCenter);
	return windowsVisible;
end

function ToggleGameMenu()
	if ( GameMenu:IsVisible() ) then
		HideUIPanel(GameMenu);
	elseif ( SpellStopCasting() ) then
	elseif ( CloseAllWindows() ) then
	elseif ( ClearTarget() ) then
	else
		ShowUIPanel(GameMenu);
	end
end
