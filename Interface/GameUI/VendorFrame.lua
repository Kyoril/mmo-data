VENDOR_ITEMS_PER_PAGE = 14;

local function VendorTextHeight(frame)
	return frame:GetTextHeight() * GetUIScale().y / frame:GetLayoutUIScale().y;
end

local function VendorFrame_LayoutItems(numItems)
	VendorStockLabel:SetHeight(math.max(32, VendorTextHeight(VendorStockLabel)));
	VendorPurchaseHint:SetHeight(math.max(28, VendorTextHeight(VendorPurchaseHint)));
	VendorPageLabel:SetHeight(math.max(39, VendorTextHeight(VendorPageLabel)));
	VendorPageLabel:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, VendorPurchaseHint, -8);
	local footerHeight = math.max(112, 32 + VendorPurchaseHint:GetHeight() + 8 + VendorPageLabel:GetHeight());
	VendorFooter:SetHeight(footerHeight);
	VendorStockSurface:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, VendorStockLabel, 12);
	VendorStockSurface:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, -footerHeight - 32);

	-- Measure names at the actual column width. Keep every row large enough for
	-- its name and price, then paginate the rows that fit inside the stock surface.
	local nameHeight = 58;
	for i = 0, numItems - 1 do
		local item = GetVendorItemInfo(i);
		if item then
			VendorText1:SetText(item.name);
			nameHeight = math.max(nameHeight, VendorTextHeight(VendorText1));
		end
	end
	local priceHeight = math.max(44, VendorTextHeight(VendorMoney1_CopperButton));
	local rowHeight = math.max(128, 12 + nameHeight + 4 + priceHeight + 8);
	local availableHeight = VendorStockSurface:GetHeight() / VendorStockSurface:GetLayoutUIScale().y - 24;
	local rows = math.max(1, math.min(7, math.floor((availableHeight + 8) / (rowHeight + 8))));
	local perPage = rows * 2;
	if perPage ~= VENDOR_ITEMS_PER_PAGE then
		local firstItem = ((VendorFrame.page or 1) - 1) * VENDOR_ITEMS_PER_PAGE;
		VendorFrame.page = math.floor(firstItem / perPage) + 1;
		VENDOR_ITEMS_PER_PAGE = perPage;
	end
	for i = 1, 14 do
		local border = _G["VendorButton" .. i .. "Border"];
		border:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, VendorStockSurface,
			12 + math.floor((i - 1) / 2) * (rowHeight + 8));
		border:SetHeight(rowHeight);
		_G["VendorText" .. i]:SetHeight(nameHeight);
	end
end

local vendorLayoutKey = nil;
function VendorFrame_UpdateLayout()
	if not VendorFrame:IsVisible() then return; end
	local scale, rect = GetUIScale(), VendorFrame:GetRect();
	local key = table.concat({scale.x, scale.y, VendorFrame:GetLayoutScale(),
		rect.right - rect.left, rect.bottom - rect.top}, ":");
	if key ~= vendorLayoutKey then
		vendorLayoutKey = key;
		VendorFrame_UpdateVendorItems();
	end
end

function VendorFrame_UpdateVendorItems()
    local numItems = GetVendorNumItems();
    VendorStockLabel:SetText(string.format(Localize("VENDOR_STOCK_COUNT"), numItems));
    VendorFrame_LayoutItems(numItems);

    local pageCount = math.max(1, math.ceil(numItems / VENDOR_ITEMS_PER_PAGE));
    VendorFrame.page = math.max(1, math.min(VendorFrame.page, pageCount));

    if VendorFrame.page * VENDOR_ITEMS_PER_PAGE < numItems then
        VendorNextPageButton:Enable();
    else
        VendorNextPageButton:Disable();
    end

    if (VendorFrame.page == 1) then
        VendorPrevPageButton:Disable();
    else
        VendorPrevPageButton:Enable();
    end

    VendorPageLabel:SetText(string.format(Localize("VENDOR_PAGE_FORMAT"), VendorFrame.page, pageCount));

    for i = 1, 14, 1 do
        local index = (((VendorFrame.page - 1) * VENDOR_ITEMS_PER_PAGE) + i);
        local border = _G["VendorButton" .. i .. "Border"];
        local itemText = _G["VendorText" .. i];
        local button = _G["VendorButton" .. i];

        local money = _G["VendorMoney" .. i];

        if (i <= VENDOR_ITEMS_PER_PAGE and index <= numItems) then
            local item, texture, price, quantity, numAvailable, isUsable = GetVendorItemInfo(index - 1);
    
            itemText:SetText(item.name);
            button:SetProperty("Icon", texture);
            button.id = index - 1;
            if (quantity > 1) then
                button:SetText(string.format("%d", quantity));
            else
                quantity = 1;
                button:SetText("");
            end

            RefreshMoneyFrame("VendorMoney" .. i, price * quantity, false, false, true);
            money:Show();

            button:SetProperty("QualityColor", item.quality > 1 and ItemQualityColors[item.quality] or "FFFFFFFF");
            border:Enable();
            border:Show();
        else
            money:Hide();
            itemText:SetText("");
            button:SetProperty("Icon", "");
            button:SetText("");
            border:Disable();
            border:Hide();
        end
    end
end

function VendorFrame_NextPage()
    local numItems = GetVendorNumItems();

    if (VendorFrame.page * VENDOR_ITEMS_PER_PAGE >= numItems) then
        return;
    end

    VendorFrame.page = VendorFrame.page + 1;
    VendorFrame_UpdateVendorItems();
end

function VendorFrame_PrevPage()
    if (VendorFrame.page == 1) then
        return;
    end

    VendorFrame.page = VendorFrame.page - 1;
    VendorFrame_UpdateVendorItems();
end

function VendorFrame_Show(self)
    local target = GetUnit("target");
    if target then
        SidePanel_SetUnitTitle(self, target);
    end

    VendorFrame.page = 1;

    ShowUIPanel(self);
    OpenInventory();

    VendorFrame_UpdateVendorItems();
end

function VendorFrame_Close(self)
    HideUIPanel(VendorFrame);
end

function VendorButton_OnClick(self, button)
    if (button == "RIGHT") then
        BuyVendorItem(self.id);
    elseif(button == "LEFT") then
        print("TODO: Grab item from vendor");
    end
end

function VendorButton_OnEnter(this)
    local numItems = GetVendorNumItems();

    local index = this.id + 1;
    if (index <= numItems) then
        local item = GetVendorItemInfo(index - 1);
        if item then
            GameTooltip:ClearAnchors();
            GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, this, 16);
            GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, this, 0);
            GameTooltip_SetItemTemplate(item);
            GameTooltip:Show();
        else
            print("Item was nil for index " .. index);
        end
    else
        print("Index " .. index .. " was out of bounds (" .. numItems .. ")");
	end
end

function VendorButton_OnLeave(this)
	GameTooltip:Hide();
end

function VendorFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);

    self:RegisterEvent("VENDOR_SHOW", VendorFrame_Show);
    self:RegisterEvent("VENDOR_CLOSED", VendorFrame_Close);

    for i = 1, 14, 1 do
        local button = _G["VendorButton" .. i];
        button:SetClickedHandler(VendorButton_OnClick);
        button:SetOnEnterHandler(VendorButton_OnEnter);
        button:SetOnLeaveHandler(VendorButton_OnLeave);
    end
end

function VendorFrame_OnShow(self)
end
