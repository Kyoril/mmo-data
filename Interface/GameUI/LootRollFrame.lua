LOOT_ROLL_MAX_ITEMS = 4;

LootRoll_ActiveRolls = {};
LootRoll_RollOrder = {};

function LootRollFrame_GetItemFrame(index)
	return getglobal("LootRollItem" .. index);
end

function LootRollFrame_GetItemWidgets(frame)
	if not frame then
		return nil, nil, nil, nil, nil;
	end

	return frame:GetChild(0), frame:GetChild(1), frame:GetChild(2), frame:GetChild(3), frame:GetChild(4);
end

function LootRollFrame_OnLoad(self)
	self:RegisterEvent("START_LOOT_ROLL", LootRollFrame_OnStartRoll);
	self:RegisterEvent("LOOT_ROLL_WON", LootRollFrame_OnRollWon);
	self:RegisterEvent("LOOT_ROLL_ALL_PASSED", LootRollFrame_OnAllPassed);

	for i = 1, LOOT_ROLL_MAX_ITEMS, 1 do
		local frame = LootRollFrame_GetItemFrame(i);
		if frame then
			local _, _, needButton, greedButton, passButton = LootRollFrame_GetItemWidgets(frame);

			if needButton then
				needButton:SetClickedHandler(LootRollNeedButton_OnClick);
			end

			if greedButton then
				greedButton:SetClickedHandler(LootRollGreedButton_OnClick);
			end

			if passButton then
				passButton:SetClickedHandler(LootRollPassButton_OnClick);
			end

			frame:Hide();
		end
	end

	self:Hide();
end

function LootRollFrame_OnStartRoll(self, lootGuid, slot, itemId, rollTime, itemName, quality)
	local key = tostring(lootGuid) .. "_" .. tostring(slot);
	LootRoll_ActiveRolls[key] = {
		lootGuid = lootGuid,
		slot = slot,
		itemId = itemId,
		itemName = itemName or "Unknown Item",
		quality = quality or 1,
		timeLeft = (rollTime or 60000) / 1000,
		voted = false,
	};

	local exists = false;
	for _, currentKey in ipairs(LootRoll_RollOrder) do
		if currentKey == key then
			exists = true;
			break;
		end
	end

	if not exists then
		table.insert(LootRoll_RollOrder, key);
	end

	LootRollFrame_Update(self);
	self:Show();
end

function LootRollFrame_OnRollWon(self, lootGuid, slot, itemId, winnerGuid, winningRoll, winningVote, itemName, quality)
	local key = tostring(lootGuid) .. "_" .. tostring(slot);
	LootRoll_ActiveRolls[key] = nil;
	LootRollFrame_RemoveKey(key);
	LootRollFrame_Update(self);

	if #LootRoll_RollOrder == 0 then
		self:Hide();
	end
end

function LootRollFrame_OnAllPassed(self, lootGuid, slot, itemId)
	local key = tostring(lootGuid) .. "_" .. tostring(slot);
	LootRoll_ActiveRolls[key] = nil;
	LootRollFrame_RemoveKey(key);
	LootRollFrame_Update(self);

	if #LootRoll_RollOrder == 0 then
		self:Hide();
	end
end

function LootRollFrame_SetChoiceButtonsVisible(frame, visible)
	local _, _, needButton, greedButton, passButton = LootRollFrame_GetItemWidgets(frame);

	if needButton then
		if visible then
			needButton:Show();
		else
			needButton:Hide();
		end
	end

	if greedButton then
		if visible then
			greedButton:Show();
		else
			greedButton:Hide();
		end
	end

	if passButton then
		if visible then
			passButton:Show();
		else
			passButton:Hide();
		end
	end
end

function LootRollFrame_RemoveKey(key)
	for index, currentKey in ipairs(LootRoll_RollOrder) do
		if currentKey == key then
			table.remove(LootRoll_RollOrder, index);
			break;
		end
	end
end

function LootRollFrame_OnUpdate(self, elapsed)
	local active = false;
	local expired = {};

	for key, rollInfo in pairs(LootRoll_ActiveRolls) do
		rollInfo.timeLeft = rollInfo.timeLeft - elapsed;
		if rollInfo.timeLeft <= 0 then
			if not rollInfo.voted then
				ConfirmLootRoll(rollInfo.lootGuid, rollInfo.slot, 0);
			end
			table.insert(expired, key);
		else
			active = true;
		end
	end

	for _, key in ipairs(expired) do
		LootRoll_ActiveRolls[key] = nil;
		LootRollFrame_RemoveKey(key);
	end

	LootRollFrame_Update(self);

	if not active then
		self:Hide();
	end
end

function LootRollFrame_Update(self)
	local visibleIndex = 1;
	for _, key in ipairs(LootRoll_RollOrder) do
		local rollInfo = LootRoll_ActiveRolls[key];
		if rollInfo and visibleIndex <= LOOT_ROLL_MAX_ITEMS then
			local frame = LootRollFrame_GetItemFrame(visibleIndex);
			local nameText, timerText = LootRollFrame_GetItemWidgets(frame);

			if nameText then
				local color = ItemQualityColors[rollInfo.quality] or "FFFFFFFF";
				nameText:SetText("|c" .. color .. rollInfo.itemName .. "|r");
			end

			if timerText then
				timerText:SetText(string.format("%ds", math.ceil(rollInfo.timeLeft)));
			end

			frame.rollInfo = rollInfo;
			LootRollFrame_SetChoiceButtonsVisible(frame, not rollInfo.voted);

			frame:Show();
			visibleIndex = visibleIndex + 1;
		end
	end

	for index = visibleIndex, LOOT_ROLL_MAX_ITEMS, 1 do
		local frame = LootRollFrame_GetItemFrame(index);
		if frame then
			frame.rollInfo = nil;
			LootRollFrame_SetChoiceButtonsVisible(frame, true);
			frame:Hide();
		end
	end
end

function LootRollNeedButton_OnClick(self)
	local parent = self:GetParent();
	if parent and parent.rollInfo and not parent.rollInfo.voted then
		ConfirmLootRoll(parent.rollInfo.lootGuid, parent.rollInfo.slot, 1);
		parent.rollInfo.voted = true;
		LootRollFrame_Update(LootRollFrame);
	end
end

function LootRollGreedButton_OnClick(self)
	local parent = self:GetParent();
	if parent and parent.rollInfo and not parent.rollInfo.voted then
		ConfirmLootRoll(parent.rollInfo.lootGuid, parent.rollInfo.slot, 2);
		parent.rollInfo.voted = true;
		LootRollFrame_Update(LootRollFrame);
	end
end

function LootRollPassButton_OnClick(self)
	local parent = self:GetParent();
	if parent and parent.rollInfo and not parent.rollInfo.voted then
		ConfirmLootRoll(parent.rollInfo.lootGuid, parent.rollInfo.slot, 0);
		parent.rollInfo.voted = true;
		LootRollFrame_Update(LootRollFrame);
	end
end