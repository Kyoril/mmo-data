
function InventoryItemButton_OnLoad(this)
    this:SetOnEnterHandler(InventoryItemButton_OnEnter);
    this:SetOnLeaveHandler(ActionButton_OnLeave);
    this:SetClickedHandler(InventoryItemButton_OnClick);    
end

function InventoryItemButton_OnEnter(this)
    local item = GetInventorySlotItem("player", this.id);
    if not item then
        return;
    end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, this, -16);
    GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, this, 0);

    GameTooltip_SetItem(item);
    GameTooltip:Show();
end

function InventoryItemButton_OnClick(this)
    -- Activate item swap action
    PickupContainerItem(this.id);
end

function InventoryItemButton_OnLeave(this)
    GameTooltip:Hide();
end

function InventoryItemButton_OnUpdate(this, elapsed)
    local icon = GetInventorySlotIcon("player", this.id);
    if not icon then
        this:SetProperty("Icon", "");
        return;
    end

    local count = GetInventorySlotCount("player", this.id);
    if count > 1 then
        this:SetText(tostring(count));
    else
        this:SetText("");
    end

    this:SetProperty("Icon", icon);
end
