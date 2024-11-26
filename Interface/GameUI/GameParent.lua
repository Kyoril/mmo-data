
ErrorTimer = 0.0

UIPanelWindows = {};
UIPanelWindows["GameMenu"] = { area = "center", pushable = 0 };
UIPanelWindows["SpellBook"] = { area = "left", pushable = 0 };
UIPanelWindows["CharacterWindow"] = { area = "left", pushable = 1 };
UIPanelWindows["TrainerFrame"] = { area = "left", pushable = 0 };
UIPanelWindows["VendorFrame"] = { area = "left", pushable = 0 };
UIPanelWindows["LootFrame"] = { area = "left", pushable = 0 };

local menuOffsetY = BUTTON_V_PADDING

function SidePanel_OnClose(closeButton)
	-- Parent of the button is the titlebar, whose parent is the frame
	HideUIPanel(closeButton:GetParent():GetParent());
end

function SidePanel_OnLoad(self)
	self.titleBar = self:GetChild(0);
	self.titleBar.closeButton = self.titleBar:GetChild(0);
	self.titleBar.closeButton:SetClickedHandler(SidePanel_OnClose);
end

function GameParent_OnSpellError(self, spellError)
    ErrorTimer = 4.0;
    ErrorText:SetText(Localize(spellError));
    ErrorText:Show();
end

function GameParent_OnGameError(self, gameError)
    ErrorTimer = 4.0;
    ErrorText:SetText(Localize(gameError));
    ErrorText:Show();
end

function GameParent_OnAttackSwingError(self, attackSwingError)
    ErrorTimer = 1.0;
    ErrorText:SetText(Localize(attackSwingError));
    ErrorText:Show();
end

function GameParent_OnPlayerDead()
    CloseAllWindows(true);
    StaticDialog_Show("DEATH");
end

function GameParent_OnLoad(self)
    self:RegisterEvent("GAME_ERROR", GameParent_OnGameError);
    self:RegisterEvent("PLAYER_SPELL_CAST_FAILED", GameParent_OnSpellError);
    self:RegisterEvent("ATTACK_SWING_ERROR", GameParent_OnAttackSwingError);
    self:RegisterEvent("PLAYER_DEAD", GameParent_OnPlayerDead);
end

function GameParent_OnUpdate(self, elapsed)
    if (ErrorTimer <= 0.0) then
        return
    end

    ErrorTimer = ErrorTimer - elapsed

    if (ErrorTimer <= 0.0) then
        ErrorText:Hide();
    end
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

	if ( UnitHealth("player") <= 0 and (info.area ~= center) and (frame ~= SuggestFrame) ) then
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
	if ( UnitHealth("player") <= 0 ) then
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
