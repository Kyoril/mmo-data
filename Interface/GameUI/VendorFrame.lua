VENDOR_ITEMS_PER_PAGE = 14;

function VendorFrame_UpdateVendorItems()
    local numItems = GetVendorNumItems();

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

    VendorPageLabel:SetText(string.format(Localize("SPELL_BOOK_PAGE_FORMAT"), VendorFrame.page));

    for i = 1, VENDOR_ITEMS_PER_PAGE, 1 do
        local index = (((VendorFrame.page - 1) * VENDOR_ITEMS_PER_PAGE) + i);
        local border = _G["VendorButton" .. i .. "Border"];
        local itemText = _G["VendorText" .. i];
        local button = _G["VendorButton" .. i];

        local money = _G["VendorMoney" .. i];

        if (index <= numItems) then
            local name, texture, price, quantity, numAvailable, isUsable = GetVendorItemInfo(index - 1);
            itemText:SetText(name);
            button:SetProperty("Icon", texture);
            button.id = index - 1;
            if (quantity > 0) then
                button:SetText(quantity);
            else
                button:SetText("");
            end

            RefreshMoneyFrame("VendorMoney" .. i, price, false, false, true);
            money:Show();

            border:Enable();
        else
            money:Hide();
            itemText:SetText("");
            button:SetProperty("Icon", "");
            border:Disable();
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
    self:GetChild(0):SetText(UnitName("target"));
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
        printf("TODO: Grab item from vendor");
    end
end

function VendorFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);

    self:RegisterEvent("VENDOR_SHOW", VendorFrame_Show);
    self:RegisterEvent("VENDOR_CLOSED", VendorFrame_Close);

    for i = 1, VENDOR_ITEMS_PER_PAGE, 1 do
        local button = _G["VendorButton" .. i];
        button:SetClickedHandler(VendorButton_OnClick);
    end
end

function VendorFrame_OnShow(self)
end
