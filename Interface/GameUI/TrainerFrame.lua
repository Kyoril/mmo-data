-- Trainer rows store source indices and spell IDs independently of visible slots.
local trainerOffset = 0;
local trainerHideLearned = true;
local trainerHideUnavailable = false;
local trainerUpdating = false;
local trainerRows = {};
local trainerVisibleRows = 5;

local function TrainerSpellState(index)
	local id, name, icon, cost, known = GetTrainerSpellInfo(index);
	local requiredLevel = GetTrainerSpellReqLevel(index) or 0;
	local player = GetUnit("player");
	local level = 0;
	if player then
		level = IsTrainerClassTrainer() and player:GetActiveClassLevel() or player:GetLevel();
	end
	local state = "TRAINER_STATE_AVAILABLE";
	if known then
		state = "TRAINER_STATE_LEARNED";
	elseif not player or level < requiredLevel then
		state = "TRAINER_STATE_LOCKED";
	elseif UnitMoney("player") < cost then
		state = "TRAINER_STATE_MONEY";
	end
	return { index = index, id = id, name = name, icon = icon, cost = cost,
		known = known, requiredLevel = requiredLevel, state = state,
		available = id > 0 and state == "TRAINER_STATE_AVAILABLE" };
end

function TrainerFrame_CanBuySpell(index)
	return index ~= nil and TrainerSpellState(index).available;
end

local function TrainerUpdatePreview(entry)
	TrainerBuyButton:Disable();
	TrainerSpellDescContent:Hide();
	TrainerSelectionHint:Show();
	TrainerFrame.selectedSpellIndex = nil;
	if not entry then
		TrainerFrame.selectedSpellId = nil;
		return;
	end
	TrainerFrame.selectedSpellId = entry.id;
	TrainerFrame.selectedSpellIndex = entry.index;
	TrainerSpellPreviewButton:SetProperty("Icon", entry.icon);
	TrainerSpellPreviewName:SetText(entry.name);
	TrainerSpellPreviewButton.userData = gameData.spells:GetById(entry.id);
	TrainerSpellDescriptionText:SetText(GetSpellDescription(TrainerSpellPreviewButton.userData));
	RefreshMoneyFrame("TrainerSpellCostMoney", entry.cost, false, false, true);
	TrainerPreviewState:SetText(Localize(entry.state));
	TrainerPreviewState:SetProperty("TextColor", entry.available and "FF86DE56" or (entry.known and "FFAAA396" or "FFFF8770"));
	TrainerSpellDescContent:Show();
	TrainerSelectionHint:Hide();
	TrainerBuyButton:SetEnabled(entry.available);
end

function TrainerSpellButton_OnClick(row)
	local entry = row.userData;
	if not entry then
		return;
	end
	TrainerFrame.selectedSpellId = entry.id;
	TrainerList_Update();
end

function TrainerBuyButton_OnClick(self)
	-- Resolve again at click time: network updates may have reordered the list.
	for index = 0, GetNumTrainerSpells() - 1 do
		local entry = TrainerSpellState(index);
		if entry.id == TrainerFrame.selectedSpellId and entry.available then
			BuyTrainerSpell(index);
			return;
		end
	end
end

function TrainerList_Update(self)
	if trainerUpdating then
		return;
	end
	trainerUpdating = true;
	trainerRows = {};
	for index = 0, GetNumTrainerSpells() - 1 do
		local entry = TrainerSpellState(index);
		if entry.id > 0 and not (trainerHideLearned and entry.known)
			and not (trainerHideUnavailable and not entry.known and not entry.available) then
			table.insert(trainerRows, entry);
		end
	end
	local maximum = math.max(0, #trainerRows - trainerVisibleRows);
	trainerOffset = math.max(0, math.min(trainerOffset, maximum));
	TrainerSpellListScrollBar:SetMaximum(maximum);
	TrainerSpellListScrollBar:SetValue(trainerOffset);
	TrainerSpellListScrollBar:SetEnabled(maximum > 0);
	if maximum > 0 then
		TrainerSpellListScrollBar:Show();
	else
		TrainerSpellListScrollBar:Hide();
	end
	TrainerSpellListContent:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, TrainerSpellList, maximum > 0 and -96 or -12);
	TrainerListSummary:SetText(string.format(Localize("TRAINER_FILTER_COUNT"), #trainerRows, GetNumTrainerSpells()));
	if #trainerRows == 0 then
		TrainerEmptyLabel:Show();
	else
		TrainerEmptyLabel:Hide();
	end
	local selected;
	for _, entry in ipairs(trainerRows) do
		if entry.id == TrainerFrame.selectedSpellId then
			selected = entry;
			break;
		end
	end
	-- Never silently substitute a different spell after a purchase or filter change.
	TrainerUpdatePreview(selected);
	for slot = 1, trainerVisibleRows do
		local row = _G["TrainerSpellButton" .. slot];
		local entry = trainerRows[trainerOffset + slot];
		row.userData = entry;
		row:SetChecked(entry ~= nil and entry.id == TrainerFrame.selectedSpellId);
		if entry then
			local color = entry.available and "FFF3CF50" or (entry.known and "FFAAA396" or "FFD5C5B6");
			_G["TrainerRowIcon" .. slot]:SetProperty("Icon", entry.icon);
			_G["TrainerRowIcon" .. slot]:SetProperty("IconTint", entry.available and "FFFFFFFF" or "FF888888");
			_G["TrainerRowName" .. slot]:SetText(entry.name);
			_G["TrainerRowName" .. slot]:SetProperty("TextColor", color);
			_G["TrainerRowLevel" .. slot]:SetText(string.format(Localize(IsTrainerClassTrainer() and "TRAINER_CLASS_LEVEL" or "TRAINER_REQUIRED_LEVEL"), entry.requiredLevel));
			_G["TrainerRowState" .. slot]:SetText(Localize(entry.state));
			_G["TrainerRowState" .. slot]:SetProperty("TextColor", entry.available and "FF86DE56" or (entry.known and "FFAAA396" or "FFFF8770"));
			RefreshMoneyFrame("TrainerRowMoney" .. slot, entry.cost, false, false, true);
			_G["TrainerRowState" .. slot]:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.LEFT, _G["TrainerRowMoney" .. slot], -12);
			row:Show();
		else
			row:Hide();
		end
	end
	RefreshMoneyFrame("TrainerPlayerMoneyFrame", UnitMoney("player"), false, false, true);
	trainerUpdating = false;
end

function TrainerFilters_Changed()
	trainerHideLearned = TrainerHideLearned:IsChecked();
	trainerHideUnavailable = TrainerHideUnavailable:IsChecked();
	trainerOffset = 0;
	TrainerList_Update();
end

function TrainerFrame_OnTrainerShow(self)
	trainerOffset = 0;
	TrainerFrame.selectedSpellId = nil;
	local target = GetUnit("target");
	local title = GetTrainerTitle();
	self:GetChild(0):SetText(target and target:GetName() or title);
	ShowUIPanel(self);
	TrainerList_Update();
end

function TrainerFrame_OnTrainerUpdate(self)
	TrainerList_Update();
end

local TRAINER_BUY_ERROR_MESSAGES = {
	[0] = "TRAINER_ERROR_LEVEL_TOO_LOW",
	[1] = "TRAINER_ERROR_NOT_ENOUGH_MONEY",
	[2] = "TRAINER_ERROR_WRONG_CLASS"
};
function TrainerFrame_OnTrainerBuyError(self, code)
	if TRAINER_BUY_ERROR_MESSAGES[code] then
		UIErrorFrame_OnErrorMessage(ErrorFrame, Localize(TRAINER_BUY_ERROR_MESSAGES[code]));
	end
end
function TrainerFrame_OnTrainerClosed(self)
	TrainerFrame.selectedSpellId = nil;
	TrainerFrame.selectedSpellIndex = nil;
	HideUIPanel(self);
end

function TrainerFrame_OnLoad(self)
	SidePanel_OnLoad(self);
	TrainerSpellCostLabel:SetWidth(TrainerSpellCostLabel:GetTextWidth() + 8);
	TrainerHideLearned:SetChecked(true);
	TrainerHideUnavailable:SetChecked(false);
	TrainerHideLearned:SetClickedHandler(TrainerFilters_Changed);
	TrainerHideUnavailable:SetClickedHandler(TrainerFilters_Changed);
	local scroll = TrainerSpellListScrollBar;
	scroll:SetMinimum(0);
	scroll:SetMaximum(0);
	scroll:SetStep(1);
	scroll:SetValue(0);
	scroll:SetOnValueChangedHandler(function(self, value)
		if not trainerUpdating then
			trainerOffset = math.floor(value + 0.5);
			TrainerList_Update();
		end
	end);
	TrainerSpellList:SetOnMouseWheelHandler(function(self, delta)
		if scroll:IsEnabled(true) then
			scroll:SetValue(scroll:GetValue() - delta);
		end
	end);
	TrainerSpellPreviewButton:SetOnEnterHandler(function(button)
		if button.userData then
			GameTooltip:ClearAnchors();
			GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, button, 0);
			GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, button, 16);
			GameTooltip_SetSpell(button.userData);
			GameTooltip:Show();
		end
	end);
	TrainerSpellPreviewButton:SetOnLeaveHandler(function() GameTooltip:Hide(); end);
	-- Forward child clicks and hover to the selectable row, including price coins.
	local function WireRowChild(child, row)
		child:SetProperty("Clickable", "false");
		child:SetOnEnterHandler(function() row:SetButtonState(ButtonState.HOVERED); end);
		child:SetOnLeaveHandler(function() row:SetButtonState(ButtonState.NORMAL); end);
		for i = 0, child:GetChildCount() - 1 do
			WireRowChild(child:GetChild(i), row);
		end
	end
	for slot = 1, trainerVisibleRows do
		local row = _G["TrainerSpellButton" .. slot];
		row:SetClickedHandler(TrainerSpellButton_OnClick);
		for i = 0, row:GetChildCount() - 1 do
			WireRowChild(row:GetChild(i), row);
		end
	end
	self:RegisterEvent("TRAINER_SHOW", TrainerFrame_OnTrainerShow);
	self:RegisterEvent("TRAINER_UPDATE", TrainerFrame_OnTrainerUpdate);
	self:RegisterEvent("TRAINER_CLOSED", TrainerFrame_OnTrainerClosed);
	self:RegisterEvent("TRAINER_BUY_ERROR", TrainerFrame_OnTrainerBuyError);
	for _, event in ipairs({"MONEY_CHANGED", "SPELL_LEARNED", "PLAYER_LEVEL_CHANGED", "PLAYER_KNOWN_CLASSES_CHANGED"}) do
		self:RegisterEvent(event, TrainerList_Update);
	end
end
function TrainerFrame_OnShow(self)
	TrainerList_Update();
end
function TrainerFrame_Toggle()
	if TrainerFrame:IsVisible() then
		HideUIPanel(TrainerFrame);
	else
		ShowUIPanel(TrainerFrame);
	end
end
