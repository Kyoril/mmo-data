-- TradeFrame.lua
-- Trade window UI implementation

TRADE_NUM_SLOTS = 6;

-- Trade accept state tracking
local myAccepted = false;
local otherAccepted = false;

-- Store pending trade request
local pendingTradeRequest = nil;

-- Name of the other player in the current session
local tradePartnerName = nil;

-- Whether the inventory frame was already open when trade started
local inventoryWasOpenBeforeTrade = false;

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

	-- Initialize hover on the border frames for other player's slots.
	-- The inner buttons are disabled and may not fire mouse events, so
	-- attach to the always-enabled border frames instead.
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local border = getglobal("TradeOtherSlot"..index.."Border");
		if border then
			border.id = index;
			border:SetOnEnterHandler(TradeOtherSlot_OnEnter);
			border:SetOnLeaveHandler(TradeSlot_OnLeave);
		end
	end

	-- Accept / cancel buttons
	local acceptButton = getglobal("TradeAcceptButton");
	if acceptButton then
		acceptButton:SetClickedHandler(TradeFrame_AcceptTrade);
	end

	local cancelButton = getglobal("TradeCancelButton");
	if cancelButton then
		cancelButton:SetClickedHandler(TradeFrame_CancelTrade);
	end

	-- Close button (first child of the title bar)
	local closeButton = TradeFrame:GetChild(0):GetChild(0);
	if closeButton then
		closeButton:SetClickedHandler(TradeFrame_OnClose);
	end

	-- Register events
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
	TradeFrame_UpdateDisplay();
	TradeFrame_UpdateAcceptStatus(); -- reset green "Accepted" labels from previous session
end

function TradeFrame_OnHide(self)
	-- Dismiss the money input dialog if it is still open on top
	if StaticDialog:IsVisible() and StaticDialog.which == "TRADE_SET_MONEY" then
		StaticDialog:Hide();
	end

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

	TradeFrameTitle:SetText(string.format(Localize("TRADE_FRAME_TITLE"), otherPlayerName));

	local info = ChatTypeInfo["SYSTEM"];
	ChatFrame:AddMessage(string.format(Localize("TRADE_SESSION_STARTED"), otherPlayerName), info.r, info.g, info.b);

	-- Open inventory automatically; remember whether we opened it so we can close it on trade end
	inventoryWasOpenBeforeTrade = InventoryFrame:IsVisible();
	if not inventoryWasOpenBeforeTrade then
		ShowUIPanel(InventoryFrame);
	end

	ShowUIPanel(TradeFrame);
end

function TradeFrame_OnTradeSessionClosed(self, reason)
	-- Dismiss the money input dialog if it was open
	if StaticDialog:IsVisible() and StaticDialog.which == "TRADE_SET_MONEY" then
		StaticDialog:Hide();
	end

	HideUIPanel(TradeFrame);
	tradePartnerName = nil;

	-- Close inventory if we opened it at trade start
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
	-- Pre-cache item info for all slots so tooltips are ready on hover
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

function TradeFrame_UpdateMoneyDisplay()
	local myMoneyFrame = getglobal("TradeMyMoneyFrame");
	if myMoneyFrame then
		RefreshMoneyFrame("TradeMyMoneyFrame", GetTradeMoney(true), 1, 0, nil);
	end

	local otherMoneyFrame = getglobal("TradeOtherMoneyFrame");
	if otherMoneyFrame then
		RefreshMoneyFrame("TradeOtherMoneyFrame", GetTradeMoney(false), 1, 0, nil);
	end
end

function TradeFrame_UpdateAcceptStatus()
	local myCheckMark = getglobal("TradeMyAcceptCheck");
	if myCheckMark then
		if myAccepted then myCheckMark:Show(); else myCheckMark:Hide(); end
	end

	local otherCheckMark = getglobal("TradeOtherAcceptCheck");
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
-- Slot interaction
-- -------------------------------------------------------------------------

-- Returns true if the given absolute inventory slot is from a tradeable location.
-- Blocks: equipment (Bag_0 slots 0-18) and bag-pack slots (Bag_0 slots 19-22).
local function IsTradeableSlot(inventorySlot)
	-- Absolute encoding: upper byte = bag index, lower byte = slot within bag.
	-- Bag_0 (player_inventory_slots::Bag_0) = 255 = 0xFF
	local bagByte  = math.floor(inventorySlot / 256);
	local slotByte = inventorySlot % 256;

	if bagByte == 255 then
		-- Bag_0: slots 0-22 are equipment and bag-pack containers — not tradeable
		if slotByte <= 22 then
			return false;
		end
	end

	return true;
end

function TradeMySlot_OnClick(button)
	local slotIndex = button.id - 1;

	if CursorHasItem() then
		local inventorySlot = GetCursorItemSlot();
		if inventorySlot then
			-- Client-side guard: block equipment and equipped-bag slots immediately
			if not IsTradeableSlot(inventorySlot) then
				local info = ChatTypeInfo["SYSTEM"];
				ChatFrame:AddMessage(Localize("EQUIP_ERR_CANT_TRADE_EQUIP_BAGS"), info.r, info.g, info.b);
				return;
			end

			TradeAddItem(slotIndex, inventorySlot);
			ClearCursorItem();
			TradeFrame_UpdateMySlotFromInventory(slotIndex, inventorySlot);
		end
	else
		local entry = GetTradeItemEntry(slotIndex, true);
		if entry and entry > 0 then
			ClearTradeItem(slotIndex);
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

function TradeSlot_OnEnter(button)
	local slotIndex = button.id - 1;
	local entry = GetTradeItemEntry(slotIndex, true);
	if entry and entry > 0 then
		local itemInfo = GetCachedItemInfo(entry);
		if itemInfo then
			GameTooltip:ClearAnchors();
			GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, button, 16);
			GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, button, 0);
			GameTooltip_SetItemTemplate(itemInfo);
			GameTooltip:Show();
		end
	end
end

function TradeOtherSlot_OnEnter(border)
	local slotIndex = border.id - 1;
	local entry = GetTradeItemEntry(slotIndex, false);
	if entry and entry > 0 then
		local itemInfo = GetCachedItemInfo(entry);
		if itemInfo then
			GameTooltip:ClearAnchors();
			GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.LEFT, border, -16);
			GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, border, 0);
			GameTooltip_SetItemTemplate(itemInfo);
			GameTooltip:Show();
		end
	end
end

function TradeSlot_OnLeave(button)
	GameTooltip:Hide();
end

-- -------------------------------------------------------------------------
-- Button actions
-- -------------------------------------------------------------------------

function TradeFrame_AcceptTrade(button)
	if not myAccepted then
		AcceptTrade();
	end
end

function TradeFrame_CancelTrade(button)
	CancelTrade();
end

function TradeFrame_ShowMoneyInput()
	StaticDialog_Show("TRADE_SET_MONEY");
end
