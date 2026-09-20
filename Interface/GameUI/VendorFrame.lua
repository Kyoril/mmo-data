VENDOR_ITEMS_PER_PAGE = 14;

function VendorFrame_UpdateVendorItems()
    local numItems = GetVendorNumItems();

    local pageCount = math.max(1, math.ceil(numItems / VENDOR_ITEMS_PER_PAGE));
    VendorFrame.page = math.max(1, math.min(VendorFrame.page, pageCount));
    VendorStockLabel:SetText(string.format(Localize("VENDOR_STOCK_COUNT"), numItems));

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

        if (index <= numItems) then
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
        self:GetChild(0):SetText(target:GetName());
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

    for i = 1, VENDOR_ITEMS_PER_PAGE, 1 do
        local button = _G["VendorButton" .. i];
        button:SetClickedHandler(VendorButton_OnClick);
        button:SetOnEnterHandler(VendorButton_OnEnter);
        button:SetOnLeaveHandler(VendorButton_OnLeave);
    end
end

function VendorFrame_OnShow(self)
end
