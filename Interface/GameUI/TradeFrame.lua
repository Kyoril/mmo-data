-- TradeFrame.lua
-- Trade window UI implementation

TRADE_NUM_SLOTS = 6;

-- Trade accept state tracking
local myAccepted = false;
local otherAccepted = false;

-- Trade money values
local myMoney = 0;

-- Store pending trade request
local pendingTradeRequest = nil;

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

	-- Initialize slot buttons for other player's items
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local button = getglobal("TradeOtherSlot"..index);
		if button then
			button.id = index;
			button:SetOnEnterHandler(TradeSlot_OnEnter);
			button:SetOnLeaveHandler(TradeSlot_OnLeave);
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

	-- Close button handler
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
	-- Reset state
	myAccepted = false;
	otherAccepted = false;
	myMoney = 0;

	-- Update display
	TradeFrame_UpdateDisplay();
end

function TradeFrame_OnHide(self)
	-- Cancel trade when window is closed
	if IsTrading() then
		CancelTrade();
	end
end

function TradeFrame_OnClose(button)
	HideUIPanel(TradeFrame);
end

function TradeFrame_OnTradeRequest(self, requesterName)
	-- Store the pending request
	pendingTradeRequest = requesterName;
	
	-- Show confirmation dialog
	StaticDialogFrame_Show("TRADE_REQUEST", requesterName.." wants to trade with you.");
end

function TradeFrame_OnTradeRequestResult(self, result)
	if result == 0 then
		-- Success - window will open when session is established
		return;
	end

	-- Show error message based on result
	local errorMsg = "Trade failed.";
	if result == 1 then
		errorMsg = "That player is busy.";
	elseif result == 2 then
		errorMsg = "That player is too far away.";
	elseif result == 3 then
		errorMsg = "Player not found.";
	elseif result == 4 then
		errorMsg = "You cannot trade while dead.";
	elseif result == 5 then
		errorMsg = "Target is dead.";
	elseif result == 6 then
		errorMsg = "You are already trading.";
	elseif result == 7 then
		errorMsg = "Cannot trade with hostile players.";
	elseif result == 8 then
		errorMsg = "Target is logging out.";
	end

	-- Show error in chat or UI message
	ChatFrame:AddMessage(errorMsg, 1.0, 0.0, 0.0);
end

function TradeFrame_OnTradeSessionOpened(self, otherPlayerName)
	-- Update frame title
	TradeFrameTitle:SetText("Trade: "..otherPlayerName);
	
	-- Show the trade window
	ShowUIPanel(TradeFrame);
end

function TradeFrame_OnTradeSessionClosed(self, reason)
	HideUIPanel(TradeFrame);

	-- Show message based on close reason
	local msg = nil;
	if reason == 0 then
		msg = "Trade completed successfully.";
	elseif reason == 1 then
		msg = "Trade cancelled.";
	elseif reason == 2 then
		msg = "Trade cancelled: Too far away.";
	elseif reason == 3 then
		msg = "Trade cancelled: A player died.";
	elseif reason == 4 then
		msg = "Trade cancelled: Became hostile.";
	elseif reason == 5 then
		msg = "Trade cancelled: Player disconnected.";
	else
		msg = "Trade ended.";
	end

	if msg then
		ChatFrame:AddMessage(msg, 1.0, 1.0, 0.0);
	end
end

function TradeFrame_OnTradeUpdate(self)
	TradeFrame_UpdateDisplay();
end

function TradeFrame_OnTradeAcceptUpdate(self, meAccepted, theyAccepted)
	myAccepted = meAccepted;
	otherAccepted = theyAccepted;

	-- Update accept button appearance
	TradeFrame_UpdateAcceptStatus();
end

function TradeFrame_UpdateDisplay()
	-- Update my slots
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local button = getglobal("TradeMySlot"..index);
		local border = getglobal("TradeMySlot"..index.."Border");
		
		if button then
			local entry, name, icon, count = GetTradeItemInfo(index - 1, true);
			if entry and entry > 0 then
				button:SetProperty("Icon", icon);
				if count and count > 1 then
					button:SetText(tostring(count));
				else
					button:SetText("");
				end
				button:Show();
				if border then
					border:Show();
				end
			else
				button:SetProperty("Icon", "");
				button:SetText("");
				button:Show();
				if border then
					border:Show();
				end
			end
		end
	end

	-- Update other player's slots
	for index = 1, TRADE_NUM_SLOTS, 1 do
		local button = getglobal("TradeOtherSlot"..index);
		local border = getglobal("TradeOtherSlot"..index.."Border");
		
		if button then
			local entry, name, icon, count = GetTradeItemInfo(index - 1, false);
			if entry and entry > 0 then
				button:SetProperty("Icon", icon);
				if count and count > 1 then
					button:SetText(tostring(count));
				else
					button:SetText("");
				end
				button:Show();
				if border then
					border:Show();
				end
			else
				button:SetProperty("Icon", "");
				button:SetText("");
				button:Show();
				if border then
					border:Show();
				end
			end
		end
	end

	-- Update money display
	TradeFrame_UpdateMoneyDisplay();
end

function TradeFrame_UpdateMoneyDisplay()
	local myTradeMoney = GetTradeMoney(true);
	local otherTradeMoney = GetTradeMoney(false);

	-- Update my money frame (if it exists)
	local myMoneyFrame = getglobal("TradeMyMoneyFrame");
	if myMoneyFrame then
		RefreshMoneyFrame("TradeMyMoneyFrame", myTradeMoney, 1, 0, nil);
	end

	-- Update other's money frame
	local otherMoneyFrame = getglobal("TradeOtherMoneyFrame");
	if otherMoneyFrame then
		RefreshMoneyFrame("TradeOtherMoneyFrame", otherTradeMoney, 1, 0, nil);
	end
end

function TradeFrame_UpdateAcceptStatus()
	-- Update visual indicators for acceptance
	local myCheckMark = getglobal("TradeMyAcceptCheck");
	local otherCheckMark = getglobal("TradeOtherAcceptCheck");

	if myCheckMark then
		if myAccepted then
			myCheckMark:Show();
		else
			myCheckMark:Hide();
		end
	end

	if otherCheckMark then
		if otherAccepted then
			otherCheckMark:Show();
		else
			otherCheckMark:Hide();
		end
	end

	-- Update accept button text
	local acceptButton = getglobal("TradeAcceptButton");
	if acceptButton then
		if myAccepted then
			acceptButton:SetText("Accepted");
			acceptButton:Disable();
		else
			acceptButton:SetText("Accept");
			acceptButton:Enable();
		end
	end
end

function TradeMySlot_OnClick(button)
	local slotIndex = button.id - 1;
	
	-- If there's an item in this slot, clear it
	local entry, name, icon, count = GetTradeItemInfo(slotIndex, true);
	if entry and entry > 0 then
		ClearTradeItem(slotIndex);
	else
		-- Check if we have a picked up item on cursor
		-- TODO: Implement cursor item placement
	end
end

function TradeSlot_OnEnter(button)
	local isMine = string.find(button:GetName(), "TradeMySlot");
	local slotIndex = button.id - 1;
	
	local entry, name, icon, count = GetTradeItemInfo(slotIndex, isMine ~= nil);
	if entry and entry > 0 then
		GameTooltip:ClearAnchors();
		GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, button, 16);
		GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, button, -16);
		-- TODO: Set tooltip with item info
		GameTooltip:Show();
	end
end

function TradeSlot_OnLeave(button)
	GameTooltip:Hide();
end

function TradeFrame_AcceptTrade(button)
	if not myAccepted then
		AcceptTrade();
	end
end

function TradeFrame_CancelTrade(button)
	CancelTrade();
end

-- Function to set money in trade
function TradeFrame_SetMoney(amount)
	SetTradeMoney(amount);
end

-- Static dialog configuration for trade requests
StaticDialogConfig = StaticDialogConfig or {};
StaticDialogConfig["TRADE_REQUEST"] = {
	text = "",
	button1 = "Accept",
	button2 = "Decline",
	OnAccept = function()
		-- Accept the trade request
		if pendingTradeRequest then
			-- The accept is handled by responding to the trade request
			-- which should already be done server-side
		end
		pendingTradeRequest = nil;
	end,
	OnCancel = function()
		-- Decline - close the dialog, the server will timeout
		pendingTradeRequest = nil;
	end,
	timeout = 60,
	exclusive = 1,
	showAlert = 1,
};
