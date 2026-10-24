
-- Tint applied to an equipped item's icon when the active class can no longer use it (lost
-- weapon/armor proficiency or dual-wield after a class switch). Plain white means "usable".
INVENTORY_ICON_COLOR_NORMAL = "FFFFFFFF";
INVENTORY_ICON_COLOR_DISABLED = "FFFF4040";

-- White preserves the authored frame for ordinary inventory buttons.
INVENTORY_QUALITY_COLOR_NONE = "FFFFFFFF";
INVENTORY_QUALITY_COLOR_EMPTY = "FF505050";

-- Recolors the button frame to the item's quality color. Only slots whose "QualityBorder"
-- property is enabled participate; every other inventory button keeps its plain frame.
function InventoryItemButton_UpdateQualityBorder(this, item)
    if this:GetProperty("QualityBorder") ~= "true" then
        return;
    end

    local color = INVENTORY_QUALITY_COLOR_EMPTY;
    if item then
        color = ItemQualityColors[item:GetQuality()] or INVENTORY_QUALITY_COLOR_NONE;
    elseif this:GetProperty("BagSlot") == "true" then
        -- Preserve the authored bronze rim around the empty bag's red inset.
        color = INVENTORY_QUALITY_COLOR_NONE;
    end

    this:SetProperty("QualityColor", color);
    -- Keep the empty-slot silhouette subdued; hide it beneath equipped item artwork.
    this:SetProperty("BackgroundColor", item and "00FFFFFF" or "FF909090");
end

-- Turns quality-colored borders on for an inventory button, e.g. the paperdoll slots.
function InventoryItemButton_EnableQualityBorder(this)
    this:SetProperty("QualityBorder", "true");
end

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
    -- A drag that started on an empty slot carries nothing; releasing it must
    -- not pick up the item under the mouse.
    if not CursorHasItem() then
        ClearCursorItem();
        return;
    end
    PickupContainerItem(this.id);
end

function InventoryItemButton_OnEnter(this)
    local item = GetInventorySlotItem("player", this.id);
    if not item then
		if this:GetProperty("BagSlot") ~= "true" then
			return;
		end
		GameTooltip_Clear();
		GameTooltip_AddLine(Localize("BAG_SLOT"), TOOLTIP_LINE_LEFT, "FFFFD100");
	else
		-- Fill the tooltip first so its final height is known for anchoring below.
		GameTooltip_SetItem(item);

		-- Warn when the active class can't use this equipped item.
		if not item:IsUsable() then
			GameTooltip_AddLine(Localize("ITEM_DISABLED_WRONG_CLASS"), TOOLTIP_LINE_LEFT, "FFFF2020");
		end
    end

    GameTooltip:ClearAnchors();

    if (this:GetX() >= 300) then
        GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, this, 0);
    else
        GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 0);
    end

    -- Show the tooltip above the button if it fits on screen, below otherwise, and keep it
    -- inside the screen vertically. GetRect() reports screen pixels while the tooltip size and
    -- anchor offsets are UI units, so convert first (see GameTooltip_AnchorToFrame).
    local scale = GetUIScale();
    local parent = GameTooltip:GetParent();
    local parentHeight = parent:GetHeight() / scale.y;
    local rect = this:GetRect();
    local tooltipHeight = GameTooltip:GetHeight();
    local gap = 16.0;
    local margin = 8.0;

    local top = rect.top / scale.y - gap - tooltipHeight;
    if (top < margin) then
        top = rect.bottom / scale.y + gap;
    end

    local maxTop = parentHeight - tooltipHeight - margin;
    if (top > maxTop) then
        top = maxTop;
    end
    if (top < margin) then
        top = margin;
    end

    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, top);

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
        elseif (MailFrame_IsSendPanelVisible()) then
            -- Mail send panel is open: attach the item to the mail draft
            MailFrame_AttachItem(this.id);
        elseif (BankFrame:IsVisible()) then
            -- Bank window is open: move the item between inventory and bank
            BankFrame_OnItemRightClicked(this.id);
        elseif (VendorFrame:IsVisible()) then
            -- Vendor window is open: UseContainerItem sells the item, so the coin sound belongs here.
            UseContainerItem(this.id);
            PlaySound("Sound/Interface/Coins_1.wav");
        else
            -- No merchant involved: use or equip the item without the money sound.
            UseContainerItem(this.id);
        end
    end
end

function InventoryItemButton_OnLeave(this)
    GameTooltip:Hide();
end

function InventoryItemButton_OnUpdate(this, elapsed)
    local item = GetInventorySlotItem("player", this.id);
	if this:GetProperty("BagSlot") == "true" then
		local color = item and "00FFFFFF" or "FF801818";
		if this:GetProperty("EmptyBagColor") ~= color then
			this:SetProperty("EmptyBagColor", color);
			if this:IsHovered() then
				InventoryItemButton_OnEnter(this);
			end
		end
	end

    if not item then
        this:SetText("");
        this:SetProperty("Icon", "");
        InventoryItemButton_UpdateQualityBorder(this, nil);
        return;
    end

    InventoryItemButton_UpdateQualityBorder(this, item);

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
