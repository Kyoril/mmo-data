
-- Tint applied to an equipped item's icon when the active class can no longer use it (lost
-- weapon/armor proficiency or dual-wield after a class switch). Plain white means "usable".
INVENTORY_ICON_COLOR_NORMAL = "FFFFFFFF";
INVENTORY_ICON_COLOR_DISABLED = "FFFF4040";

function InventoryItemButton_OnLoad(this)
    this:SetOnEnterHandler(InventoryItemButton_OnEnter);
    this:SetOnLeaveHandler(ActionButton_OnLeave);
    this:SetClickedHandler(InventoryItemButton_OnClick);
    this:SetProperty("IconColor", INVENTORY_ICON_COLOR_NORMAL);
end

function InventoryItemButton_OnDrag(this, button, position)
    PickupContainerItem(this.id);
end

function InventoryItemButton_OnDrop(this, button, position)
    PickupContainerItem(this.id);
end

function InventoryItemButton_OnEnter(this)
    local item = GetInventorySlotItem("player", this.id);
    if not item then
        return;
    end

    GameTooltip:ClearAnchors();

    if (this:GetX() >= 300) then
        GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, this, 0);
    else
        GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 0);
    end
    GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, this, -16);

    GameTooltip_SetItem(item);

    -- Warn when the active class can't use this equipped item (revoked proficiency / dual-wield).
    if not item:IsUsable() then
        GameTooltip_AddLine(Localize("ITEM_DISABLED_WRONG_CLASS"), TOOLTIP_LINE_LEFT, "FFFF2020");
    end

    GameTooltip:Show();
end

function InventoryItemButton_OnClick(this, button)
    if (button == "LEFT") then        
        if (IsShiftKeyDown()) then
            if (ChatInputFrame:IsVisible()) then
                local hyperlink = "|c" .. ItemQualityColors[item:GetQuality()] .. "|Hitem:" .. item:GetId() .. "|h[" .. item:GetName() .. "]|h|r";
                ChatInput:SetText(ChatInput:GetText() .. hyperlink);
                ChatInput:CaptureInput();
            end
        else
            -- Activate item swap action
            PickupContainerItem(this.id);
        end
    elseif (button == "RIGHT") then
        if IsTrading() then
            -- Trade window is open: put the item into the next free trade slot
            TradeFrame_AddFromInventory(this.id);
        else
            UseContainerItem(this.id);
            -- TODO: If is vendor item, sell it
            PlaySound("Sound/Interface/Coins_1.wav");
        end
    end
end

function InventoryItemButton_OnLeave(this)
    GameTooltip:Hide();
end

function InventoryItemButton_OnUpdate(this, elapsed)
    local item = GetInventorySlotItem("player", this.id);
    if not item then
        this:SetText("");
        this:SetProperty("Icon", "");
        return;
    end
    
    local icon = item:GetIcon();
    if not icon then
        this:SetText("");
        this:SetProperty("Icon", "");
        return;
    end

    local count = item:GetStackCount();
    if count > 1 then
        this:SetText(tostring(count));
    else
        this:SetText("");
    end

    this:SetProperty("Icon", icon);

    -- Tint the icon red when the item is equipped but the active class can no longer use it.
    if item:IsUsable() then
        this:SetProperty("IconColor", INVENTORY_ICON_COLOR_NORMAL);
    else
        this:SetProperty("IconColor", INVENTORY_ICON_COLOR_DISABLED);
    end
end
