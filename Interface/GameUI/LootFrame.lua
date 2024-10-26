LOOTFRAME_NUMBUTTONS = 4;

function LootFrame_OnLootOpened(self)
    self.page = 1
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
    HideUIPanel(self);
end

function LootFrame_OnLoad(self)
    self:RegisterEvent("LOOT_OPENED", LootFrame_OnLootOpened);
    self:RegisterEvent("LOOT_SLOT_CLEARED", LootFrame_OnLootSlotCleared);
    self:RegisterEvent("LOOT_CLOSED", LootFrame_OnLootClosed);
end

function LootFrame_OnShow(self)
	self.numLootItems = GetNumLootItems();
	LootFrame_OnUpdate(self, 0);

	if ( self.numLootItems == 0 ) then
		-- TODO: Play sound of empty loot window opening
	else
		-- TODO: Play sound of loot window opening
	end
end

function LootFrame_OnHide()	
	CloseLoot();
	-- TODO: Play sound of loot window closing
end

function LootButton_OnClick(button)
	LootSlot(((LOOTFRAME_NUMBUTTONS - 1) * (LootFrame.page - 1)) + button.id, false);
end

function LootFrame_OnUpdate(self, elapsed)
	--[[
	local numLootItems = LootFrame.numLootItems;

    local numLootToShow = LOOTFRAME_NUMBUTTONS;
	if ( numLootItems > LOOTFRAME_NUMBUTTONS ) then
		numLootToShow = numLootToShow - 1;
	end

    for index = 1, LOOTFRAME_NUMBUTTONS, 1 do
		local button = getglobal("LootButton"..index);
		local slot = (numLootToShow * (LootFrame.page - 1)) + index;

		if ( slot <= numLootItems ) then	
			if ( (LootSlotIsItem(slot) or LootSlotIsCoin(slot)) and index <= numLootToShow ) then
				local texture;
				local item;
				local quantity;
				texture, item, quantity = GetLootSlotInfo(slot);
				getglobal("LootButton"..index.."IconTexture"):SetTexture(texture);
				getglobal("LootButton"..index.."Text"):SetText(item);

				local countString = getglobal("LootButton"..index.."Count");
				if ( quantity > 1 ) then
					countString:SetText(quantity);
					countString:Show();
				else
					countString:Hide();
				end
				button:Show();
			else
				button:Hide();
			end
		else
			button:Hide();
		end
	end
	]]
end