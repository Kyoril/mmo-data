MERCHANT_ITEMS_PER_PAGE = 14;

function MerchantFrame_Show(self)
    self:GetChild(0):SetText(UnitName("target"));
    ShowUIPanel(self);
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
