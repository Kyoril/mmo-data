VENDOR_ITEMS_PER_PAGE = 12;

function VendorFrame_UpdateVendorItems()
    local numItems = GetVendorNumItems();

    if numItems >= VENDOR_ITEMS_PER_PAGE then
        VendorNextPageButton:Enable();
    else
        VendorNextPageButton:Disable();
    end

    if (VendorFrame.page == 1) then
        VendorPrevPageButton:Disable();
    else
        VendorPrevPageButton:Enable();
    end

    VendorPageLabel:SetText("Page " .. tostring(VendorFrame.page));

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
    HideUIPanel(self);
end

function VendorFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);

    self:RegisterEvent("VENDOR_SHOW", VendorFrame_Show);
    self:RegisterEvent("VENDOR_CLOSED", VendorFrame_Close);
end

function VendorFrame_OnShow(self)
end
