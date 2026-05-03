LOOT_ROLL_MAX_ITEMS = 4;

LootRoll_ActiveRolls = {};
LootRoll_RollOrder = {};
LootRoll_FrameRollInfo = {};  -- [frameIndex] -> rollInfo

function LootRollFrame_GetItemFrame(index)
	return getglobal("LootRollItem" .. index);
end

function LootRollFrame_GetItemWidgets(frame)
	if not frame then
		return nil, nil, nil, nil, nil, nil;
	end

	return frame:GetChild(0), frame:GetChild(1), frame:GetChild(2), frame:GetChild(3), frame:GetChild(4), frame:GetChild(5);
end

function LootRollFrame_OnLoad(self)
	self:RegisterEvent("START_LOOT_ROLL", LootRollFrame_OnStartRoll);
	self:RegisterEvent("LOOT_ROLL_WON", LootRollFrame_OnRollWon);
	self:RegisterEvent("LOOT_ROLL_ALL_PASSED", LootRollFrame_OnAllPassed);

	for i = 1, LOOT_ROLL_MAX_ITEMS, 1 do
		local frame = LootRollFrame_GetItemFrame(i);
		if frame then
			local _, _, _, needButton, greedButton, passButton = LootRollFrame_GetItemWidgets(frame);

			if needButton then
				local idx = i;
				needButton:SetClickedHandler(function(btn)
					LootRollButton_OnClick(idx, 1);
				end);
			end

			if greedButton then
				local idx = i;
				greedButton:SetClickedHandler(function(btn)
					LootRollButton_OnClick(idx, 2);
				end);
			end

			if passButton then
				local idx = i;
				passButton:SetClickedHandler(function(btn)
					LootRollButton_OnClick(idx, 0);
				end);
			end

			local idx = i;
			frame:SetOnEnterHandler(function(f)
				LootRollItem_OnEnter(idx, f);
			end);
			frame:SetOnLeaveHandler(function(f)
				LootRollItem_OnLeave(idx);
			end);

			frame:Hide();
		end
	end

	self:Hide();
end

function LootRollFrame_OnStartRoll(self, lootGuid, slot, itemId, rollTime, itemName, quality, displayId)
	local key = tostring(lootGuid) .. "_" .. tostring(slot);
	local icon = "";
	if displayId and displayId > 0 then
		icon = GetItemDisplayIcon(displayId);
	end

	LootRoll_ActiveRolls[key] = {
		lootGuid = lootGuid,
		slot = slot,
		itemId = itemId,
		itemName = itemName or "Unknown Item",
		quality = quality or 1,
		icon = icon or "",
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
	local _, _, _, needButton, greedButton, passButton = LootRollFrame_GetItemWidgets(frame);

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
			local iconFrame, nameText, timerText = LootRollFrame_GetItemWidgets(frame);

			if iconFrame and rollInfo.icon and rollInfo.icon ~= "" then
				iconFrame:SetProperty("Icon", rollInfo.icon);
			end

			if nameText then
				local color = ItemQualityColors[rollInfo.quality] or "FFFFFFFF";
				nameText:SetText("|c" .. color .. rollInfo.itemName .. "|r");
			end

			if timerText then
				timerText:SetText(string.format("%ds", math.ceil(rollInfo.timeLeft)));
			end

			LootRoll_FrameRollInfo[visibleIndex] = rollInfo;
			LootRollFrame_SetChoiceButtonsVisible(frame, not rollInfo.voted);

			frame:Show();
			visibleIndex = visibleIndex + 1;
		end
	end

	for index = visibleIndex, LOOT_ROLL_MAX_ITEMS, 1 do
		local frame = LootRollFrame_GetItemFrame(index);
		if frame then
			LootRoll_FrameRollInfo[index] = nil;
			LootRollFrame_SetChoiceButtonsVisible(frame, true);
			frame:Hide();
		end
	end
end

function LootRollButton_OnClick(frameIndex, vote)
	local rollInfo = LootRoll_FrameRollInfo[frameIndex];
	if rollInfo and not rollInfo.voted then
		ConfirmLootRoll(rollInfo.lootGuid, rollInfo.slot, vote);
		rollInfo.voted = true;
		LootRollFrame_Update(LootRollFrame);
	end
end

function LootRollItem_OnEnter(frameIndex, frame)
	local rollInfo = LootRoll_FrameRollInfo[frameIndex];
	if rollInfo and rollInfo.itemId then
		local item = GetCachedItemInfo(rollInfo.itemId);
		if item then
			GameTooltip:ClearAnchors();
			GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, frame, 8);
			GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, frame, 0);
			GameTooltip_SetItemTemplate(item);
			GameTooltip:Show();
		end
	end
end

function LootRollItem_OnLeave(frameIndex)
	GameTooltip:Hide();
end