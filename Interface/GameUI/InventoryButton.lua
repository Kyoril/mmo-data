
function InventoryItemButton_OnLoad(this)
    this:SetOnEnterHandler(InventoryItemButton_OnEnter);
    this:SetOnLeaveHandler(ActionButton_OnLeave);
    this:SetClickedHandler(InventoryItemButton_OnClick);    
end

function InventoryItemButton_OnDrag(this, button, position)
    SetCursorItem(this.id);
    PickupContainerItem(this.id);
end

function InventoryItemButton_OnDrop(this, button, position)
    -- Clear cursor tracking when successfully dropping on a valid slot
    ClearCursorItem();
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
    GameTooltip:Show();
end

function InventoryItemButton_OnClick(this, button)
    if (button == "LEFT") then
        if (IsShiftKeyDown()) then
            if (ChatInputFrame:IsVisible()) then
                local item = GetInventorySlotItem("player", this.id);
                if not item then
                    return;
                end

                local hyperlink = "|c" .. ItemQualityColors[item:GetQuality()] .. "|Hitem:" .. item:GetId() .. "|h[" .. item:GetName() .. "]|h|r";
                ChatInput:SetText(ChatInput:GetText() .. hyperlink);
                ChatInput:CaptureInput();
            end
        else
            -- Activate item swap action
            PickupContainerItem(this.id);
        end
    elseif (button == "RIGHT") then
        UseContainerItem(this.id);
        
        -- TODO: If is vendor item, sell it
        PlaySound("Sound/Interface/Coins_1.wav");
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
end
