VENDOR_ITEMS_PER_PAGE = 14;

VENDOR_MODE_STOCK = 1;
VENDOR_MODE_BUYBACK = 2;

-- The vendor frame shows either the merchant's own stock or the items the player sold during
-- this session. Both lists use the same cards, so every lookup goes through these two helpers.
local function VendorFrame_GetNumItems()
    if (VendorFrame.mode == VENDOR_MODE_BUYBACK) then
        return GetVendorNumBuybackItems();
    end

    return GetVendorNumItems();
end

local function VendorFrame_GetItemInfo(index)
    if (VendorFrame.mode == VENDOR_MODE_BUYBACK) then
        return GetVendorBuybackItemInfo(index);
    end

    return GetVendorItemInfo(index);
end

function VendorFrame_UpdateVendorItems()
    local buyback = (VendorFrame.mode == VENDOR_MODE_BUYBACK);
    local numItems = VendorFrame_GetNumItems();

    local pageCount = math.max(1, math.ceil(numItems / VENDOR_ITEMS_PER_PAGE));
    VendorFrame.page = math.max(1, math.min(VendorFrame.page, pageCount));

    if (buyback) then
        VendorStockLabel:SetText(string.format(Localize("VENDOR_BUYBACK_COUNT"), numItems));
        VendorPurchaseHint:SetText(Localize("VENDOR_BUYBACK_HINT"));
    else
        VendorStockLabel:SetText(string.format(Localize("VENDOR_STOCK_COUNT"), numItems));
        VendorPurchaseHint:SetText(Localize("VENDOR_PURCHASE_HINT"));
    end

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

    for i = 1, VENDOR_ITEMS_PER_PAGE, 1 do
        local index = (((VendorFrame.page - 1) * VENDOR_ITEMS_PER_PAGE) + i);
        local border = _G["VendorButton" .. i .. "Border"];
        local itemText = _G["VendorText" .. i];
        local button = _G["VendorButton" .. i];

        local money = _G["VendorMoney" .. i];

        local item, texture, price, quantity = nil, nil, 0, 0;
        if (index <= numItems) then
            item, texture, price, quantity = VendorFrame_GetItemInfo(index - 1);
        end

        -- A buyback entry whose item data has not arrived yet renders as an empty card and fills
        -- in once the item query comes back.
        if (item) then
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

function VendorFrame_SetMode(mode)
    VendorFrame.mode = mode;
    VendorFrame.page = 1;

    VendorBuybackTabButton:SetChecked(mode == VENDOR_MODE_BUYBACK);
    VendorFrame_UpdateVendorItems();
end

function VendorFrame_ToggleBuyback()
    if (VendorFrame.mode == VENDOR_MODE_BUYBACK) then
        VendorFrame_SetMode(VENDOR_MODE_STOCK);
    else
        VendorFrame_SetMode(VENDOR_MODE_BUYBACK);
    end
end

function VendorFrame_NextPage()
    local numItems = VendorFrame_GetNumItems();

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

    ShowUIPanel(self);
    OpenInventory();

    VendorFrame_SetMode(VENDOR_MODE_STOCK);
end

function VendorFrame_BuybackUpdate(self)
    -- The buyback list also changes while the stock tab is up (every sale adds to it), so the
    -- frame only needs a refresh when it is actually on screen.
    if (self:IsVisible()) then
        VendorFrame_UpdateVendorItems();
    end
end

function VendorFrame_Close(self)
    HideUIPanel(VendorFrame);
end

function VendorButton_OnClick(self, button)
    if (button == "RIGHT") then
        if (VendorFrame.mode == VENDOR_MODE_BUYBACK) then
            BuybackVendorItem(self.id);
        else
            BuyVendorItem(self.id);
        end
    elseif(button == "LEFT") then
        print("TODO: Grab item from vendor");
    end
end

function VendorButton_OnEnter(this)
    local numItems = VendorFrame_GetNumItems();

    local index = this.id + 1;
    if (index <= numItems) then
        local item = VendorFrame_GetItemInfo(index - 1);
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

    self.mode = VENDOR_MODE_STOCK;
    self.page = 1;

    self:RegisterEvent("VENDOR_SHOW", VendorFrame_Show);
    self:RegisterEvent("VENDOR_CLOSED", VendorFrame_Close);
    self:RegisterEvent("VENDOR_BUYBACK_UPDATE", VendorFrame_BuybackUpdate);

    for i = 1, VENDOR_ITEMS_PER_PAGE, 1 do
        local button = _G["VendorButton" .. i];
        button:SetClickedHandler(VendorButton_OnClick);
        button:SetOnEnterHandler(VendorButton_OnEnter);
        button:SetOnLeaveHandler(VendorButton_OnLeave);
    end
end

function VendorFrame_OnShow(self)
end
