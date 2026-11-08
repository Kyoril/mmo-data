-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Theme layout runs after all shared Glue frames have been loaded.
function CharSelect_UpdateActionLayout()
	if not GlueUITheme or not GlueUITheme.CompactCharacterActions then
		return;
	end
	for _, button in ipairs({ CharSelectQuitButton, ChangeRealmButton }) do
		button:ClearAnchors();
		button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, CharSelectChrome, 48);
		button:SetSize(300, 88);
		button:SetWidth(math.max(300, button:GetTextWidth() + 48));
	end
	CharSelectQuitButton:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, CharSelectChrome, 48);
	ChangeRealmButton:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, CharSelectQuitButton, 16);
	for _, button in ipairs({ CharCreateButton, CharDeleteButton }) do
		button:ClearAnchors();
		button:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, CharRosterPanel, -40);
		button:SetHeight(96);
		if CharRosterPanel:IsVisible() then
			button:Show();
		else
			button:Hide();
		end
		-- These remain siblings of the panel, rendered above its surface.
		button:SetFrameLevel(1);
	end
	CharCreateButton:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, CharRosterPanel, 72);
	CharCreateButton:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.H_CENTER, CharRosterPanel, -8);
	CharDeleteButton:SetAnchor(AnchorPoint.LEFT, AnchorPoint.H_CENTER, CharRosterPanel, 8);
	CharDeleteButton:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, CharRosterPanel, -72);
	CharRosterHint:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, CharRosterPanel, -156);
	CharRosterList:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, CharRosterPanel, -224);
	CharRosterRow10:Hide();
	CharSelectBottomBar:SetHeight(260);
	if not GlueUITheme.Wayfinder then
		for _, bar in ipairs({ VerticalScrollBar, CharRosterScrollBar, RealmListScrollBar }) do
			bar:GetChild(0):SetProperty("Icon", "Interface/Icons/IconGold_ArrowUp.htex");
			bar:GetChild(1):SetProperty("Icon", "Interface/Icons/IconGold_ArrowDown.htex");
		end
	end
end

CharSelect_UpdateActionLayout();

if GlueUITheme and GlueUITheme.Wayfinder then
	local A = AnchorPoint;
	for _, button in ipairs({ LoginButton, RealmListButton01, CharSelectEnterButton, CharCreatePage1NextButton, CharCreateSubmitButton }) do
		local sheen = WayfinderGluePrimarySheen:Clone();
		button:AddChild(sheen);
		sheen:SetOpacity(0);
		for _, edge in ipairs({ A.LEFT, A.RIGHT, A.TOP, A.BOTTOM }) do
			sheen:SetAnchor(edge, edge, button, 0);
		end
		button:SetOnEnterHandler(function(self)
			if self:IsEnabled(false) then
				sheen:PlayAnimation("HoverGlint");
			end
		end);
		button:SetOnLeaveHandler(function()
			sheen:StopAnimation("HoverGlint");
			sheen:SetOpacity(0);
		end);
	end

	LoginFormBackdrop:SetHeight(840);
	LoginFormBackdrop:SetAnchor(A.V_CENTER, A.V_CENTER, nil, -8);
	local loginTitle = GlueTextLarge:Clone();
	LoginFormBackdrop:AddChild(loginTitle);
	loginTitle:SetText(Localize("LOGIN"));
	loginTitle:SetAnchor(A.LEFT, A.LEFT, LoginFormBackdrop, 48);
	loginTitle:SetAnchor(A.RIGHT, A.RIGHT, LoginFormBackdrop, -48);
	loginTitle:SetAnchor(A.TOP, A.TOP, LoginFormBackdrop, 32);

	RealmListHeaderDivider:Hide();
	Wayfinder_AddTitleRule(LoginFormBackdrop, loginTitle, 48, 16);
	Wayfinder_AddTitleRule(RealmListBorder, RealmListHeaderDivider, 72, -6);
	Wayfinder_AddTitleRule(CharRosterPanel, CharCountLabel, 72, 16);
	Wayfinder_AddTitleRule(CharCreateSelectionPanel, CharCreateSelectionTitle, 72, 3);
	Wayfinder_AddTitleRule(CharCreatePropertiesFrame, CharCreatePropertiesLabel, 72, 5);
	Wayfinder_AddTitleRule(DeleteConfirmationFrame, DeleteConfirmationHeader, 72, 8);
end
