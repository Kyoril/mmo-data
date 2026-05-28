-- TradeFrame.lua
-- Trade window UI implementation

TRADE_NUM_SLOTS = 6;

-- Trade accept state tracking
local myAccepted = false;
local otherAccepted = false;

-- Store pending trade request
local pendingTradeRequest = nil;

-- Name of the other player in the current session (set on TradeSessionOpened).
local tradePartnerName = nil;

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

	-- Initialize slot borders for other player's items.
	-- The inner buttons are disabled so they may not fire mouse events; attach
	-- hover handlers to the always-enabled border frames instead.
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local border = getglobal("TradeOtherSlot"..index.."Border");
		if border then
			border.id = index;
			border:SetOnEnterHandler(TradeOtherSlot_OnEnter);
			border:SetOnLeaveHandler(TradeSlot_OnLeave);
		end
	end

	-- Initialize the accept and cancel buttons
	local acceptButton = getglobal("TradeAcceptButton");
	if acceptButton then
		acceptButton:SetClickedHandler(TradeFrame_AcceptTrade);
	end

	local cancelButton = getglobal("TradeCancelButton");
	if cancelButton then
		cancelButton:SetClickedHandler(TradeFrame_CancelTrade);
	end

	-- Close button handler (first child of first child = title bar close button)
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
end

function TradeFrame_OnHide(self)
	if IsTrading() then
		CancelTrade();
	end
end

function TradeFrame_OnClose(button)
	HideUIPanel(TradeFrame);
end

-- -------------------------------------------------------------------------
-- Event handlers — all chat messages use Localize() for proper i18n
-- -------------------------------------------------------------------------

function TradeFrame_OnTradeRequest(self, requesterName)
	pendingTradeRequest = requesterName;

	-- Show a system chat message so the player can see the notification in chat too
	local info = ChatTypeInfo["SYSTEM"];
	ChatFrame:AddMessage(string.format(Localize("TRADE_REQUEST_INCOMING"), requesterName), info.r, info.g, info.b);

	-- Show the accept/decline dialog
	StaticDialog_Show("TRADE_REQUEST", requesterName);
end

function TradeFrame_OnTradeRequestResult(self, result)
	local info = ChatTypeInfo["SYSTEM"];

	if result == 0 then
		-- Success: the invite was sent
		ChatFrame:AddMessage(Localize("TRADE_REQUEST_SENT"), info.r, info.g, info.b);
		return;
	end

	local key;
	if result == 1 then
		key = "TRADE_ERR_TARGET_BUSY";
	elseif result == 2 then
		key = "TRADE_ERR_TOO_FAR_AWAY";
	elseif result == 3 then
		key = "TRADE_ERR_PLAYER_NOT_FOUND";
	elseif result == 4 then
		key = "TRADE_ERR_YOU_ARE_DEAD";
	elseif result == 5 then
		key = "TRADE_ERR_TARGET_IS_DEAD";
	elseif result == 6 then
		key = "TRADE_ERR_ALREADY_TRADING";
	elseif result == 7 then
		key = "TRADE_ERR_TARGET_ALREADY_TRADING";
	elseif result == 8 then
		key = "TRADE_ERR_HOSTILE";
	elseif result == 9 then
		key = "TRADE_ERR_TARGET_LOGGING_OUT";
	elseif result == 10 then
		key = "TRADE_ERR_YOU_IN_COMBAT";
	elseif result == 11 then
		key = "TRADE_ERR_TARGET_IN_COMBAT";
	elseif result == 12 then
		key = "TRADE_ERR_DECLINED";
	else
		key = "TRADE_ERR_FAILED";
	end

	ChatFrame:AddMessage(Localize(key), info.r, info.g, info.b);
end

function TradeFrame_OnTradeSessionOpened(self, otherPlayerName)
	tradePartnerName = otherPlayerName;

	-- Update the dynamic subtitle in the trade frame
	TradeFrameTitle:SetText(string.format(Localize("TRADE_FRAME_TITLE"), otherPlayerName));

	-- System chat notification
	local info = ChatTypeInfo["SYSTEM"];
	ChatFrame:AddMessage(string.format(Localize("TRADE_SESSION_STARTED"), otherPlayerName), info.r, info.g, info.b);

	ShowUIPanel(TradeFrame);
end

function TradeFrame_OnTradeSessionClosed(self, reason)
	HideUIPanel(TradeFrame);
	tradePartnerName = nil;

	local info = ChatTypeInfo["SYSTEM"];
	local key;
	if reason == 0 then
		key = "TRADE_CLOSED_COMPLETE";
	elseif reason == 1 then
		key = "TRADE_CLOSED_CANCELLED";
	elseif reason == 2 then
		key = "TRADE_CLOSED_TOO_FAR";
	elseif reason == 3 then
		key = "TRADE_CLOSED_DEATH";
	elseif reason == 4 then
		key = "TRADE_CLOSED_HOSTILE";
	elseif reason == 5 then
		key = "TRADE_CLOSED_DISCONNECT";
	else
		key = "TRADE_CLOSED_CANCELLED";
	end

	ChatFrame:AddMessage(Localize(key), info.r, info.g, info.b);
end

function TradeFrame_OnTradeUpdate(self)
	-- Pre-cache item info for all trade slots so tooltips are ready on hover
	for i = 0, TRADE_NUM_SLOTS - 1 do
		local entry = GetTradeItemEntry(i, false);
		if entry and entry > 0 then
			GetCachedItemInfo(entry);
		end
		local myEntry = GetTradeItemEntry(i, true);
		if myEntry and myEntry > 0 then
			GetCachedItemInfo(myEntry);
		end
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
		if icon and icon ~= "" then
			return icon;
		end
	end
	return "Interface/Icons/Spells/S_Attack.htex";
end

function TradeFrame_UpdateDisplay()
	-- My slots
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

	-- Other player's slots
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

function TradeMySlot_OnClick(button)
	local slotIndex = button.id - 1;

	if CursorHasItem() then
		local inventorySlot = GetCursorItemSlot();
		if inventorySlot then
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
-- My own slots: hover on the (enabled) button — fires TradeSlot_OnEnter.
-- Other player's slots: hover on the border frame — fires TradeOtherSlot_OnEnter.
-- -------------------------------------------------------------------------

function TradeSlot_OnEnter(button)
	local slotIndex = button.id - 1;
	local entry = GetTradeItemEntry(slotIndex, true); -- my offer
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
	local entry = GetTradeItemEntry(slotIndex, false); -- other player's offer
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
