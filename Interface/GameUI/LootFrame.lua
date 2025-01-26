LOOTFRAME_NUMBUTTONS = 4;

function LootFrame_OnLootOpened(self)
    LootFrame.page = 1;
    ShowUIPanel(self);

    if not self:IsVisible() then
        CloseLoot();
    end
end

function LootFrame_OnLootSlotCleared(self, absoluteSlot)
    local numLootToShow = LOOTFRAME_NUMBUTTONS;
    if self.numLootItems > LOOTFRAME_NUMBUTTONS then
        numLootToShow = numLootToShow - 1;
    end

    local slot = absoluteSlot - ((self.page - 1) * numLootToShow);
    if (slot > 0) and (slot < (nummLootToShow + 1)) then
        local button = getglobal["LootButton"..slot];
        if button then
            button:Hide();
        end
    end
end

function LootFrame_OnLootClosed(self)
    HideUIPanel(LootFrame);
end

function LootButton_OnEnter(this)
	local slot = (LOOTFRAME_NUMBUTTONS * (LootFrame.page - 1)) + this.id;

	if LootSlotIsItem(slot) then
		local entry = GetLootSlotItem(slot);
		if not entry then
			return;
		end

		GameTooltip:ClearAnchors();
		GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, this, 16);
		GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, this, -16);
		GameTooltip_SetItemTemplate(entry);
		GameTooltip:Show();
	else
		return;
	end
end

function LootButton_OnLeave(this)
	GameTooltip:Hide();
end

function LootFrame_OnLoad(self)
	for index = 1, LOOTFRAME_NUMBUTTONS, 1 do
		local button = getglobal("LootButton"..index);
		if button then
			button:SetClickedHandler(LootButton_OnClick);
			button:SetOnEnterHandler(LootButton_OnEnter);
			button:SetOnLeaveHandler(LootButton_OnLeave);
		end
	end

	-- Subscribe for title bar close handler (HACKY! Order of items is important which sucks)
	LootFrame:GetChild(0):GetChild(0):SetClickedHandler(LootFrame_OnLootClosed);

    self:RegisterEvent("LOOT_OPENED", LootFrame_OnLootOpened);
    self:RegisterEvent("LOOT_SLOT_CLEARED", LootFrame_OnLootSlotCleared);
    self:RegisterEvent("LOOT_CLOSED", LootFrame_OnLootClosed);
end

function LootFrame_OnShow(self)
	LootFrame.numLootItems = GetNumLootItems();
	LootFrame_OnUpdate(LootFrame, 0);

	if ( LootFrame.numLootItems == 0 ) then
		-- TODO: Play sound of empty loot window opening
	else
		-- TODO: Play sound of loot window opening
	end
end

function LootFrame_OnHide()	
	CloseLoot();
end

function LootButton_OnClick(button)
	LootSlot(((LOOTFRAME_NUMBUTTONS - 1) * (LootFrame.page - 1)) + button.id, false);
end

function LootFrame_OnUpdate(self, elapsed)
	local numLootItems = LootFrame.numLootItems;
    local numLootToShow = LOOTFRAME_NUMBUTTONS;
	
	if ( numLootItems > LOOTFRAME_NUMBUTTONS ) then
		numLootToShow = numLootToShow - 1;
	end

    for index = 1, LOOTFRAME_NUMBUTTONS, 1 do
		local button = getglobal("LootButton"..index);
		local text = getglobal("LootText"..index);
		local border = getglobal("LootButton"..index.."Border");
		local slot = (numLootToShow * (LootFrame.page - 1)) + index;

		if ( slot <= numLootItems ) then	
			if ( (LootSlotIsItem(slot) or LootSlotIsCoin(slot)) and index <= numLootToShow ) then
				local texture;
				local item;
				local quantity = 1;
				texture, item, quantity = GetLootSlotInfo(slot);
				button:SetProperty("Icon", texture);
				text:SetText(item);

				if LootSlotIsItem(slot) then
					local entry = GetLootSlotItem(slot);
					text:SetProperty("Color", ItemQualityColors[entry.quality]);
				else
					text:SetProperty("Color", "FFFFFFFF");
				end

				if ( quantity > 1 ) then
					button:SetText(tostring(quantity));
				else
					button:SetText("");
				end
				border:Show();
			else
				border:Hide();
			end
		else
			border:Hide();
		end
	end
end