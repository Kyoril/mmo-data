MERCHANT_ITEMS_PER_PAGE = 12;

function MerchantFrame_UpdateMerchantItems()
    local numItems = GetVendorNumItems();
    for i = 1, MERCHANT_ITEMS_PER_PAGE, 1 do
        local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i);
        local border = _G["MerchantButton" .. i .. "Border"];
        local itemText = _G["MerchantText" .. i];
        local button = _G["MerchantButton" .. i];

        if (index <= numItems) then
            local name, texture, price, quantity, numAvailable, isUsable = GetVendorItemInfo(index - 1);
            itemText:SetText(name);
            button:SetProperty("Icon", texture);
            if (quantity > 0) then
                button:SetText(quantity);
            else
                button:SetText("");
            end
            border:Enable();
        else
            itemText:SetText("");
            button:SetProperty("Icon", "");
            border:Disable();
        end
    end
end

function MerchantFrame_Show(self)
    self:GetChild(0):SetText(UnitName("target"));
    MerchantFrame.page = 1;

    ShowUIPanel(self);
    OpenInventory();

    MerchantFrame_UpdateMerchantItems();
end

function MerchantFrame_Close(self)
    HideUIPanel(self);
end

function MerchantFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);

    self:RegisterEvent("VENDOR_SHOW", MerchantFrame_Show);
    self:RegisterEvent("VENDOR_CLOSED", MerchantFrame_Close);
end

function MerchantFrame_OnShow(self)
end
