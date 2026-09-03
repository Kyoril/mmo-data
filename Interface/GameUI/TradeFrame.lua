-- TradeFrame.lua
-- Trade window UI implementation

TRADE_NUM_SLOTS = 6;

-- The money input fields on the player's side, in tab order.
TRADE_MONEY_FIELDS = { "TradeMoneyGoldField", "TradeMoneySilverField", "TradeMoneyCopperField" };

-- uint32 copper caps a trade at roughly 429k gold, so six digits is all that ever fits.
TRADE_MONEY_MAX_GOLD_DIGITS = 6;

-- Trade accept state tracking
local myAccepted = false;
local otherAccepted = false;

-- Store pending trade request
local pendingTradeRequest = nil;

-- Name of the other player in the current session
local tradePartnerName = nil;

-- Whether the inventory frame was already open when trade started
local inventoryWasOpenBeforeTrade = false;

-- The money amount (in copper) that was last sent to the server. Used so that re-sanitizing the
-- input fields does not produce a packet per keystroke when the resulting amount did not change.
local committedMoney = 0;

-- Guards TradeFrame_OnMoneyFieldChanged against re-entering itself: the handler writes the
-- sanitized text back into the fields, which triggers the very same text changed callback.
local sanitizingMoneyFields = false;

-- Maps trade slot index (0-5) to the inventory slot currently in it.
-- Used to detect duplicate offers and to clean up when a slot is cleared.
local myTradeToInv = {};

-- -------------------------------------------------------------------------
-- Slot tracking helpers (global so TradeFrame_AddFromInventory is callable
-- from InventoryButton.lua via right-click).
-- -------------------------------------------------------------------------

function TradeFrame_TradeSlotInfo_Set(tradeSlot, inventorySlot)
	myTradeToInv[tradeSlot] = inventorySlot;
end

function TradeFrame_TradeSlotInfo_Clear(tradeSlot)
	myTradeToInv[tradeSlot] = nil;
end

function TradeFrame_IsInventorySlotOffered(inventorySlot)
	for _, invSlot in pairs(myTradeToInv) do
		if invSlot == inventorySlot then return true; end
	end
	return false;
end

--- Returns the index (0-5) of the first empty trade slot, or -1 if all full.
function TradeFrame_FindFirstFreeSlot()
	for i = 0, TRADE_NUM_SLOTS - 1 do
		local entry = GetTradeItemEntry(i, true);
		if not entry or entry == 0 then
			return i;
		end
	end
	return -1;
end

--- Returns true if the inventory slot is tradeable (not equipment or bag-pack).
--- Bag_0 = 255 (0xFF); slots 0-22 are equipment and bag containers.
function IsTradeableSlot(inventorySlot)
	local bagByte  = math.floor(inventorySlot / 256);
	local slotByte = inventorySlot % 256;
	if bagByte == 255 and slotByte <= 22 then
		return false;
	end
	return true;
end

--- Called by InventoryButton right-click when a trade session is open.
--- Puts the item at inventorySlot into the next free trade slot.
function TradeFrame_AddFromInventory(inventorySlot)
	local item = GetInventorySlotItem("player", inventorySlot);
	if not item then return; end

	if not IsTradeableSlot(inventorySlot) then
		local info = ChatTypeInfo["SYSTEM"];
		ChatFrame:AddMessage(Localize("EQUIP_ERR_CANT_TRADE_EQUIP_BAGS"), info.r, info.g, info.b);
		return;
	end

	if item:IsBound() then
		UIErrorFrame_AddMessage(Localize("TRADE_ERR_SOULBOUND"), "FFFF1900");
		return;
	end

	if TradeFrame_IsInventorySlotOffered(inventorySlot) then
		local info = ChatTypeInfo["SYSTEM"];
		ChatFrame:AddMessage(Localize("TRADE_ITEM_ALREADY_OFFERED"), info.r, info.g, info.b);
		return;
	end

	local freeSlot = TradeFrame_FindFirstFreeSlot();
	if freeSlot == -1 then
		local info = ChatTypeInfo["SYSTEM"];
		ChatFrame:AddMessage(Localize("TRADE_SLOTS_FULL"), info.r, info.g, info.b);
		return;
	end

	TradeAddItem(freeSlot, inventorySlot);
	TradeFrame_TradeSlotInfo_Set(freeSlot, inventorySlot);
	TradeFrame_UpdateMySlotFromInventory(freeSlot, inventorySlot);
end

-- -------------------------------------------------------------------------
-- Frame lifecycle
-- -------------------------------------------------------------------------

function TradeFrame_OnLoad(self)
	-- Initialize slot buttons for my items
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local button = getglobal("TradeMySlot"..index);
		if button then
			button.id = index;
			button:SetClickedHandler(TradeMySlot_OnClick);
			button:SetOnEnterHandler(TradeSlot_OnEnter);
			button:SetOnLeaveHandler(TradeSlot_OnLeave);
		end
	end

	-- Other player's slot borders (buttons are disabled and may not fire events)
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local border = getglobal("TradeOtherSlot"..index.."Border");
		if border then
			border.id = index;
			border:SetOnEnterHandler(TradeOtherSlot_OnEnter);
			border:SetOnLeaveHandler(TradeSlot_OnLeave);
		end
	end

	local acceptButton = getglobal("TradeAcceptButton");
	if acceptButton then
		acceptButton:SetClickedHandler(TradeFrame_AcceptTrade);
	end

	local cancelButton = getglobal("TradeCancelButton");
	if cancelButton then
		cancelButton:SetClickedHandler(TradeFrame_CancelTrade);
	end

	local closeButton = TradeFrame:GetChild(0):GetChild(0);
	if closeButton then
		closeButton:SetClickedHandler(TradeFrame_OnClose);
	end

	-- The three money fields commit the offer while the player types, so no extra confirmation
	-- step (and no popup dialog) is needed to put money on the table.
	for _, fieldName in ipairs(TRADE_MONEY_FIELDS) do
		local field = getglobal(fieldName);
		if field then
			field:SetOnTextChangedHandler(TradeFrame_OnMoneyFieldChanged);
		end
	end

	self:RegisterEvent("TRADE_REQUEST", TradeFrame_OnTradeRequest);
	self:RegisterEvent("TRADE_REQUEST_RESULT", TradeFrame_OnTradeRequestResult);
	self:RegisterEvent("TRADE_SESSION_OPENED", TradeFrame_OnTradeSessionOpened);
	self:RegisterEvent("TRADE_SESSION_CLOSED", TradeFrame_OnTradeSessionClosed);
	self:RegisterEvent("TRADE_UPDATE", TradeFrame_OnTradeUpdate);
	self:RegisterEvent("TRADE_ACCEPT_UPDATE", TradeFrame_OnTradeAcceptUpdate);
end

function TradeFrame_OnShow(self)
	myAccepted = false;
	otherAccepted = false;
	myTradeToInv = {};
	TradeFrame_ClearMoneyFields();
	TradeFrame_UpdateDisplay();
	TradeFrame_UpdateAcceptStatus();
end

function TradeFrame_OnHide(self)
	-- Never leave the keyboard captured by a money field of a window that is gone.
	TradeFrame_ReleaseMoneyFieldFocus();

	if IsTrading() then
		CancelTrade();
	end
end

function TradeFrame_OnClose(button)
	HideUIPanel(TradeFrame);
end

-- -------------------------------------------------------------------------
-- Network event handlers — all chat messages use Localize()
-- -------------------------------------------------------------------------

function TradeFrame_OnTradeRequest(self, requesterName)
	pendingTradeRequest = requesterName;

	local info = ChatTypeInfo["SYSTEM"];
	ChatFrame:AddMessage(string.format(Localize("TRADE_REQUEST_INCOMING"), requesterName), info.r, info.g, info.b);

	StaticDialog_Show("TRADE_REQUEST", requesterName);
end

function TradeFrame_OnTradeRequestResult(self, result)
	local info = ChatTypeInfo["SYSTEM"];

	if result == 0 then
		ChatFrame:AddMessage(Localize("TRADE_REQUEST_SENT"), info.r, info.g, info.b);
		return;
	end

	local keyMap = {
		[1]  = "TRADE_ERR_TARGET_BUSY",
		[2]  = "TRADE_ERR_TOO_FAR_AWAY",
		[3]  = "TRADE_ERR_PLAYER_NOT_FOUND",
		[4]  = "TRADE_ERR_YOU_ARE_DEAD",
		[5]  = "TRADE_ERR_TARGET_IS_DEAD",
		[6]  = "TRADE_ERR_ALREADY_TRADING",
		[7]  = "TRADE_ERR_TARGET_ALREADY_TRADING",
		[8]  = "TRADE_ERR_HOSTILE",
		[9]  = "TRADE_ERR_TARGET_LOGGING_OUT",
		[10] = "TRADE_ERR_YOU_IN_COMBAT",
		[11] = "TRADE_ERR_TARGET_IN_COMBAT",
		[12] = "TRADE_ERR_DECLINED",
	};
	local key = keyMap[result] or "TRADE_ERR_FAILED";
	ChatFrame:AddMessage(Localize(key), info.r, info.g, info.b);
end

function TradeFrame_OnTradeSessionOpened(self, otherPlayerName)
	tradePartnerName = otherPlayerName;
	myTradeToInv = {};

	-- The partner name lives in the title bar, so no second headline is needed.
	TradeTitleBar:SetText(string.format(Localize("TRADE_FRAME_TITLE"), otherPlayerName));
	TradeFrame_ClearMoneyFields();

	local info = ChatTypeInfo["SYSTEM"];
	ChatFrame:AddMessage(string.format(Localize("TRADE_SESSION_STARTED"), otherPlayerName), info.r, info.g, info.b);

	inventoryWasOpenBeforeTrade = InventoryFrame:IsVisible();
	if not inventoryWasOpenBeforeTrade then
		ShowUIPanel(InventoryFrame);
	end

	ShowUIPanel(TradeFrame);
end

function TradeFrame_OnTradeSessionClosed(self, reason)
	HideUIPanel(TradeFrame);
	TradeTitleBar:SetText(Localize("TRADE_TITLE"));
	tradePartnerName = nil;
	myTradeToInv = {};

	if not inventoryWasOpenBeforeTrade then
		HideUIPanel(InventoryFrame);
	end
	inventoryWasOpenBeforeTrade = false;

	local info = ChatTypeInfo["SYSTEM"];
	local keyMap = {
		[0] = "TRADE_CLOSED_COMPLETE",
		[1] = "TRADE_CLOSED_CANCELLED",
		[2] = "TRADE_CLOSED_TOO_FAR",
		[3] = "TRADE_CLOSED_DEATH",
		[4] = "TRADE_CLOSED_HOSTILE",
		[5] = "TRADE_CLOSED_DISCONNECT",
	};
	local key = keyMap[reason] or "TRADE_CLOSED_CANCELLED";
	ChatFrame:AddMessage(Localize(key), info.r, info.g, info.b);
end

function TradeFrame_OnTradeUpdate(self)
	for i = 0, TRADE_NUM_SLOTS - 1 do
		local entry = GetTradeItemEntry(i, false);
		if entry and entry > 0 then GetCachedItemInfo(entry); end
		local myEntry = GetTradeItemEntry(i, true);
		if myEntry and myEntry > 0 then GetCachedItemInfo(myEntry); end
	end
	TradeFrame_UpdateDisplay();
end

function TradeFrame_OnTradeAcceptUpdate(self, meAccepted, theyAccepted)
	myAccepted = meAccepted;
	otherAccepted = theyAccepted;
	TradeFrame_UpdateAcceptStatus();
end

-- -------------------------------------------------------------------------
-- Display helpers
-- -------------------------------------------------------------------------

function TradeFrame_GetSlotIcon(entry)
	if not entry or entry == 0 then return ""; end
	local itemInfo = GetCachedItemInfo(entry);
	if itemInfo then
		local icon = itemInfo:GetIcon();
		if icon and icon ~= "" then return icon; end
	end
	return "Interface/Icons/Spells/S_Attack.htex";
end

function TradeFrame_UpdateDisplay()
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local button = getglobal("TradeMySlot"..index);
		if button then
			local entry = GetTradeItemEntry(index - 1, true);
			local count = GetTradeItemCount(index - 1, true);
			if entry and entry > 0 then
				button:SetProperty("Icon", TradeFrame_GetSlotIcon(entry));
				button:SetText((count and count > 1) and tostring(count) or "");
			else
				button:SetProperty("Icon", "");
				button:SetText("");
			end
			button:Show();
		end
	end

	for index = 1, TRADE_NUM_SLOTS, 1 do
		local button = getglobal("TradeOtherSlot"..index);
		if button then
			local entry = GetTradeItemEntry(index - 1, false);
			local count = GetTradeItemCount(index - 1, false);
			if entry and entry > 0 then
				button:SetProperty("Icon", TradeFrame_GetSlotIcon(entry));
				button:SetText((count and count > 1) and tostring(count) or "");
			else
				button:SetProperty("Icon", "");
				button:SetText("");
			end
			button:Show();
		end
	end

	TradeFrame_UpdateMoneyDisplay();
end

--- Refreshes the read-only money displays. The player's own offer is deliberately not written
--- back into the input fields: those are the source of that value, and rewriting them would fight
--- the caret while the player is still typing.
function TradeFrame_UpdateMoneyDisplay()
	local otherMoneyFrame = getglobal("TradeOtherMoneyFrame");
	if otherMoneyFrame then
		RefreshMoneyFrame("TradeOtherMoneyFrame", GetTradeMoney(false), false, false, true);
	end

	local purseFrame = getglobal("TradeMyPurseFrame");
	if purseFrame then
		RefreshMoneyFrame("TradeMyPurseFrame", UnitMoney("player"), false, false, true);
	end
end

function TradeFrame_UpdateAcceptStatus()
	local myCheckMark = getglobal("TradeMyAcceptStatus");
	if myCheckMark then
		if myAccepted then myCheckMark:Show(); else myCheckMark:Hide(); end
	end
	local otherCheckMark = getglobal("TradeOtherAcceptStatus");
	if otherCheckMark then
		if otherAccepted then otherCheckMark:Show(); else otherCheckMark:Hide(); end
	end
	local acceptButton = getglobal("TradeAcceptButton");
	if acceptButton then
		if myAccepted then
			acceptButton:SetText(Localize("TRADE_ACCEPTED"));
			acceptButton:Disable();
		else
			acceptButton:SetText(Localize("TRADE_ACCEPT"));
			acceptButton:Enable();
		end
	end
end

-- -------------------------------------------------------------------------
-- Trade slot interaction (drag-and-drop from inventory onto trade slots)
-- -------------------------------------------------------------------------

function TradeMySlot_OnClick(button)
	local slotIndex = button.id - 1;

	if CursorHasItem() then
		local inventorySlot = GetCursorItemSlot();
		if inventorySlot then
			if not IsTradeableSlot(inventorySlot) then
				local info = ChatTypeInfo["SYSTEM"];
				ChatFrame:AddMessage(Localize("EQUIP_ERR_CANT_TRADE_EQUIP_BAGS"), info.r, info.g, info.b);
				return;
			end

			local cursorItem = GetInventorySlotItem("player", inventorySlot);
			if cursorItem and cursorItem:IsBound() then
				UIErrorFrame_AddMessage(Localize("TRADE_ERR_SOULBOUND"), "FFFF1900");
				return;
			end

			if TradeFrame_IsInventorySlotOffered(inventorySlot) then
				local info = ChatTypeInfo["SYSTEM"];
				ChatFrame:AddMessage(Localize("TRADE_ITEM_ALREADY_OFFERED"), info.r, info.g, info.b);
				return;
			end

			TradeAddItem(slotIndex, inventorySlot);
			TradeFrame_TradeSlotInfo_Set(slotIndex, inventorySlot);
			ClearCursorItem();
			TradeFrame_UpdateMySlotFromInventory(slotIndex, inventorySlot);
		end
	else
		local entry = GetTradeItemEntry(slotIndex, true);
		if entry and entry > 0 then
			ClearTradeItem(slotIndex);
			TradeFrame_TradeSlotInfo_Clear(slotIndex);
			TradeFrame_UpdateDisplay();
		end
	end
end

-- Optimistic local update before server echo arrives
function TradeFrame_UpdateMySlotFromInventory(slotIndex, inventorySlot)
	local button = getglobal("TradeMySlot"..(slotIndex + 1));
	if not button then return; end

	local item = GetInventorySlotItem("player", inventorySlot);
	if item then
		button:SetProperty("Icon", item:GetIcon());
		local count = item:GetStackCount();
		button:SetText((count and count > 1) and tostring(count) or "");
	end
end

-- -------------------------------------------------------------------------
-- Tooltips
-- -------------------------------------------------------------------------

--- Shows the item tooltip for a trade slot. The trade window sits at the left screen edge, so the
--- tooltip is placed with GameTooltip_AnchorToFrame, which puts it on whichever side of the slot
--- has room instead of running off screen.
local function TradeSlot_ShowTooltip(frame, slotIndex, isMine)
	local entry = GetTradeItemEntry(slotIndex, isMine);
	if not entry or entry == 0 then
		return;
	end

	local itemInfo = GetCachedItemInfo(entry);
	if not itemInfo then
		return;
	end

	-- Fill the tooltip first: the side it is anchored to depends on its final size.
	GameTooltip_SetItemTemplate(itemInfo);
	GameTooltip_AnchorToFrame(frame, "RIGHT", 16);
	GameTooltip:Show();
end

function TradeSlot_OnEnter(button)
	TradeSlot_ShowTooltip(button, button.id - 1, true);
end

function TradeOtherSlot_OnEnter(border)
	TradeSlot_ShowTooltip(border, border.id - 1, false);
end

function TradeSlot_OnLeave(button)
	GameTooltip:Hide();
end

-- -------------------------------------------------------------------------
-- Button actions
-- -------------------------------------------------------------------------

function TradeFrame_AcceptTrade(button)
	if not myAccepted then AcceptTrade(); end
end

function TradeFrame_CancelTrade(button)
	CancelTrade();
end

-- -------------------------------------------------------------------------
-- Money input (gold / silver / copper fields on the player's side)
-- -------------------------------------------------------------------------

--- Keeps only digits, drops leading zeros and enforces a digit limit plus an optional maximum
--- value. Returns the cleaned text and its numeric value.
local function TradeFrame_SanitizeAmount(text, maxDigits, maxValue)
	local digits = string.gsub(text or "", "%D", "");
	digits = string.gsub(digits, "^0+(%d)", "%1");

	if string.len(digits) > maxDigits then
		digits = string.sub(digits, 1, maxDigits);
	end

	local value = tonumber(digits) or 0;
	if maxValue and value > maxValue then
		value = maxValue;
		digits = tostring(value);
	end

	return digits, value;
end

local function TradeFrame_SetFieldText(field, text)
	-- Only write when the text really differs: SetText moves the caret to the end of the field.
	if field and field:GetText() ~= text then
		field:SetText(text);
	end
end

--- Reads the three money fields, clamps the amount to what the player owns and offers it. Runs on
--- every keystroke, so the offer always matches what is on screen.
function TradeFrame_OnMoneyFieldChanged(field)
	if sanitizingMoneyFields then
		return;
	end

	sanitizingMoneyFields = true;

	local goldText, gold = TradeFrame_SanitizeAmount(TradeMoneyGoldField:GetText(), TRADE_MONEY_MAX_GOLD_DIGITS, nil);
	local silverText, silver = TradeFrame_SanitizeAmount(TradeMoneySilverField:GetText(), 2, SILVER_PER_GOLD - 1);
	local copperText, copper = TradeFrame_SanitizeAmount(TradeMoneyCopperField:GetText(), 2, COPPER_PER_SILVER - 1);

	local amount = gold * COPPER_PER_GOLD + silver * COPPER_PER_SILVER + copper;

	-- The server rejects an offer above the player's purse, so clamp here and show the clamped
	-- amount rather than silently keeping a number that would never be traded.
	local playerMoney = UnitMoney("player");
	if amount > playerMoney then
		amount = playerMoney;
		gold = math.floor(amount / COPPER_PER_GOLD);
		silver = math.floor(math.fmod(amount, COPPER_PER_GOLD) / COPPER_PER_SILVER);
		copper = math.fmod(amount, COPPER_PER_SILVER);
		goldText = tostring(gold);
		silverText = tostring(silver);
		copperText = tostring(copper);

		UIErrorFrame_AddMessage(Localize("EQUIP_ERR_NOT_ENOUGH_MONEY"), "FFFF1900");
	end

	TradeFrame_SetFieldText(TradeMoneyGoldField, goldText);
	TradeFrame_SetFieldText(TradeMoneySilverField, silverText);
	TradeFrame_SetFieldText(TradeMoneyCopperField, copperText);

	sanitizingMoneyFields = false;

	if amount ~= committedMoney then
		committedMoney = amount;
		SetTradeMoney(amount);
	end
end

--- Empties the money fields without sending an offer update (used when a session starts or ends).
function TradeFrame_ClearMoneyFields()
	sanitizingMoneyFields = true;
	for _, fieldName in ipairs(TRADE_MONEY_FIELDS) do
		local field = getglobal(fieldName);
		if field then
			field:SetText("");
		end
	end
	sanitizingMoneyFields = false;

	committedMoney = 0;
end

--- Gives the keyboard back to the game if one of the money fields still holds it.
function TradeFrame_ReleaseMoneyFieldFocus()
	for _, fieldName in ipairs(TRADE_MONEY_FIELDS) do
		local field = getglobal(fieldName);
		if field and field:HasInputCaptured() then
			field:ReleaseInput();
		end
	end
end
