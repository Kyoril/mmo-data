
StaticDialogs = {}

StaticDialogs["DEATH"] = {
	text = Localize("YOU_DIED"),
	button1 = Localize("DEATH_RELEASE"),
	button2 = nil,
	OnAccept = function()
		ReviveMe();
	end,
	timeout = 0,
	whileDead = true,
	interruptCinematic = true,
	notClosableByLogout = true
};

StaticDialogs["PARTY_INVITE"] = {
	text = Localize("INVITATION"),
	button1 = Localize("ACCEPT"),
	button2 = Localize("DECLINE"),
	OnAccept = function()
		AcceptGroup();
	end,
	OnCancel = function()
		DeclineGroup();
	end,
	timeout = 60,
	whileDead = true
};

StaticDialogs["GUILD_INVITE"] = {
	text = Localize("GUILD_INVITATION"),
	button1 = Localize("ACCEPT"),
	button2 = Localize("DECLINE"),
	OnAccept = function()
		AcceptGuild();
	end,
	OnCancel = function()
		DeclineGuild();
	end,
	timeout = 60,
	whileDead = true
};

StaticDialogs["FRIEND_INVITE"] = {
	text = Localize("FRIEND_INVITE_WHO"),
	button1 = Localize("ACCEPT"),
	button2 = Localize("CANCEL"),
	hasEditBox = true,
	OnAccept = function()
		local text = StaticDialog.editBox:GetText();
		if (text and text ~= "") then
			FriendInviteByName(text);
		end
	end,
	timeout = 0,
	exclusive = false
};

StaticDialogs["DELETE_ITEM"] = {
	text = Localize("DELETE_ITEM"),
	button1 = Localize("YES"),
	button2 = Localize("NO"),
	OnAccept = function()
		DeleteCursorItem();
	end,
	timeout = 0,
	exclusive = false
};

function StaticDialog_OnLoad(self)

end

function StaticDialog_Show(which, text_arg1, text_arg2)

	local info = StaticDialogs[which];
	if (not info) then
		return nil;
	end

	local player = GetUnit("player");
	if (not player:IsAlive() and not info.whileDead) then
		if (info.OnCancel) then
			info.OnCancel();
		end
		return nil;
	end

	if (info.exclusive) then
		local frame = StaticDialog;
		if (frame:IsVisible() and StaticDialogs[frame.which].exclusive) then
			frame:Hide();

			local OnCancel = StaticDialogs[frame.which].OnCancel;
			if (OnCancel) then
				OnCancel(frame.data, "override");
			end
		end
	end

	if (info.cancels) then
		local frame = StaticDialog;
		if (frame:IsVisible() and (frame.which == info.cancels)) then
			frame:Hide();

			local OnCancel = StaticDialogs[frame.which].OnCancel;
			if (OnCancel) then
				OnCancel(frame.data, "override");
			end
		end
	end

	if (which == "DEATH") then
		local frame = StaticDialog;
		if (frame:IsVisible() and not StaticDialogs[frame.which].whileDead) then
			frame:Hide();

			local OnCancel = StaticDialogs[frame.which].OnCancel;
			if (OnCancel) then
				OnCancel(frame.data, "override");
			end
		end
	end

	local dialog = StaticDialog;
	if (dialog:IsVisible() and dialog.which == which) then
		dialog:Hide();

		local OnCancel = StaticDialogs[dialog.which].OnCancel;
		if (OnCancel) then
			OnCancel(dialog.data, "override");
		end
	end

	dialog = StaticDialog;
	if (not dialog) then
		info.OnCancel();
		return nil;
	end

	local text = _G[dialog:GetName().."Label"];
	text:SetText(string.format(StaticDialogs[which].text, text_arg1, text_arg2));

	-- Handle edit box if needed
	local editBox = _G[dialog:GetName().."EditBox"];
	if (StaticDialogs[which].hasEditBox) then
		editBox:SetText("");
		editBox:Show();
		dialog.editBox = editBox;
	else
		editBox:Hide();
		dialog.editBox = nil;
	end

	-- Set the buttons of the dialog
	local button1 = _G[dialog:GetName().."Button1"];
	local button2 = _G[dialog:GetName().."Button2"];
	
	local lastElement = StaticDialogs[which].hasEditBox and editBox or text;
	print("lastElement: " .. lastElement:GetName());

	if ( StaticDialogs[which].button2 and
	   ( not StaticDialogs[which].DisplayButton2 or StaticDialogs[which].DisplayButton2() ) ) then
		button1:ClearAnchors();
		button2:ClearAnchors();
		button1:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, lastElement, 8);
		button1:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.H_CENTER, lastElement, -6);
		button2:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, button1, 0);
		button2:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, button1, 16);
		button2:SetText(StaticDialogs[which].button2);
		local width = button2:GetTextWidth();
		if ( width > 180 ) then
			button2:SetWidth(width + 40);
		else
			button2:SetWidth(180);
		end
		button2:Show();
	else
		button1:ClearAnchors();
		button1:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, lastElement, 8);
		button1:SetAnchor(AnchorPoint.H_CENTER, AnchorPoint.H_CENTER, lastElement, 0);
		button2:Hide();
	end

	if ( StaticDialogs[which].button1 ) then
		button1:SetText(StaticDialogs[which].button1);
		local width = button1:GetTextWidth();
		if ( width > 180 ) then
			button1:SetWidth(width + 40);
		else
			button1:SetWidth(180);
		end
		button1:Show();
	else
		button1:Hide();
	end

	-- Set the miscellaneous variables for the dialog
	dialog.which = which;
	dialog.timeleft = StaticDialogs[which].timeout;
	-- Clear out data
	dialog.data = nil;

	if ( StaticDialogs[which].StartDelay ) then
		dialog.startDelay = StaticDialogs[which].StartDelay();
		button1:Disable();
	else
		dialog.startDelay = nil;
		button1:Enable();
	end

	-- Calculate dialog height based on contents
	local dialogHeight = 32 + text:GetTextHeight() + 8;
	if (dialog.editBox) then
		dialogHeight = dialogHeight + dialog.editBox:GetHeight() + 16;
	end
	dialogHeight = dialogHeight + 8 + button1:GetHeight() + 32;
	dialog:SetHeight(dialogHeight);

	-- Show the glue dialog
	StaticDialog:Show();

	return dialog;
end

function StaticDialog_Hide()
	StaticDialog_Button2Clicked()
end

function StaticDialog_Button1Clicked()
	StaticDialog:Hide();
	
	if (StaticDialogs[StaticDialog.which].OnAccept) then
		StaticDialogs[StaticDialog.which].OnAccept()
	end
end

function StaticDialog_Button2Clicked()
	StaticDialog:Hide();
	
	if (StaticDialogs[StaticDialog.which].OnCancel) then
		StaticDialogs[StaticDialog.which].OnCancel()
	end
end
