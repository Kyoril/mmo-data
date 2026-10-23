
NUM_BACKPACK_SLOTS = 16
NUM_BAG_SLOTS = 4
INVENTORY_SLOTS_PER_ROW = 8

local inventoryDragOffset = nil;
local INVENTORY_SCALE = 0.8;

function InventoryFrame_OnTitleMouseDown(self, button)
    if CursorHasItem() then
        HandleInvalidItemDrop();
        return true;
    end

    if button == 1 then
        local cursor = GetCursorPosition();
        local scale = GetUIScale();
        local rect = InventoryFrame:GetRect();
        inventoryDragOffset = {
            x = cursor.x - rect.left / scale.x,
            y = cursor.y - rect.top / scale.y
        };
        InventoryFrame:BringToFront();
    end

    return true;
end

function InventoryFrame_OnTitleMouseMove(self)
    if not inventoryDragOffset or not InventoryFrame:IsVisible() then
        return;
    end

    local cursor = GetCursorPosition();
    local scale = GetUIScale();
    local parent = InventoryFrame:GetParent();
    local parentRect = parent:GetRect();
    local rect = InventoryFrame:GetRect();
    -- Mouse coordinates and anchors use UI units; frame rectangles use screen pixels.
    local parentWidth = (parentRect.right - parentRect.left) / scale.x;
    local parentHeight = (parentRect.bottom - parentRect.top) / scale.y;
    local width = (rect.right - rect.left) / scale.x;
    local height = (rect.bottom - rect.top) / scale.y;
    local maxLeft = math.max(0, parentWidth - width);
    local maxTop = math.max(0, parentHeight - height);
    local left = math.max(0, math.min(maxLeft, cursor.x - inventoryDragOffset.x - parentRect.left / scale.x));
    local top = math.max(0, math.min(maxTop, cursor.y - inventoryDragOffset.y - parentRect.top / scale.y));

    InventoryFrame:ClearAnchors();
    InventoryFrame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, left);
    InventoryFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, top);
end

function InventoryFrame_StopMoving(self, button)
    if button == nil or button == 1 then
        inventoryDragOffset = nil;
    end
end

function InventoryFrame_UpdateSlots(this)
    local buttonSize = InventoryItemButtonTemplate:GetWidth() * INVENTORY_SCALE;
    local numSlots = NUM_BACKPACK_SLOTS;
    local slotsAdded = 0;

    ItemSlotContainer:RemoveAllChildren();

    -- Ensure backpack slots are created
    for i = 1, NUM_BACKPACK_SLOTS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot:SetSize(buttonSize, buttonSize);
        slot:SetProperty("Font", "InventoryCountFont");
        InventoryItemButton_EnableQualityBorder(slot);
        slot.id = GetBackpackSlot(i - 1);
        ItemSlotContainer:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 40 * INVENTORY_SCALE + buttonSize + math.fmod((i - 1), INVENTORY_SLOTS_PER_ROW) * buttonSize);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, math.floor((i - 1) / INVENTORY_SLOTS_PER_ROW) * buttonSize);
        slotsAdded = slotsAdded + 1;
    end

    for i = 1, NUM_BAG_SLOTS do
        local bagSlots = GetContainerNumSlots(i - 1);
        numSlots = numSlots + bagSlots;

        for j = 1, bagSlots do
            local slot = InventoryItemButtonTemplate:Clone();
            slot:SetSize(buttonSize, buttonSize);
            slot:SetProperty("Font", "InventoryCountFont");
        InventoryItemButton_EnableQualityBorder(slot);
            slot.id = ((i - 1 + 19) * 256) + (j - 1);    -- pack bag slot
            ItemSlotContainer:AddChild(slot);

            slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 40 * INVENTORY_SCALE + buttonSize + math.fmod(slotsAdded, INVENTORY_SLOTS_PER_ROW) * buttonSize);
            slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, math.floor(slotsAdded / INVENTORY_SLOTS_PER_ROW) * buttonSize);

            slotsAdded = slotsAdded + 1;
        end
    end
    
    local minRowCount = math.max(math.ceil(numSlots / INVENTORY_SLOTS_PER_ROW), 4);

    this:SetWidth(64 * INVENTORY_SCALE + (INVENTORY_SLOTS_PER_ROW + 1) * buttonSize);
    this:SetHeight(48 * INVENTORY_SCALE + minRowCount * buttonSize + PlayerMoney:GetHeight() + InventoryTitleBar:GetHeight());
end

function InventoryFrame_Load(this)
    local buttonSize = InventoryItemButtonTemplate:GetWidth() * INVENTORY_SCALE;

    InventoryTitleBar:SetOnMouseDownHandler(InventoryFrame_OnTitleMouseDown);
    InventoryTitleBar:SetOnMouseMoveHandler(InventoryFrame_OnTitleMouseMove);
    InventoryTitleBar:SetOnMouseUpHandler(InventoryFrame_StopMoving);

    local closeButton = InventoryTitleBar:GetChild(0);
    closeButton:SetWidth(64 * INVENTORY_SCALE);
    closeButton:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, InventoryTitleBar, 8 * INVENTORY_SCALE);
    closeButton:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, InventoryTitleBar, -18 * INVENTORY_SCALE);

    for _, denomination in ipairs({"Gold", "Silver", "Copper"}) do
        _G["PlayerMoneyFrame_" .. denomination .. "Button"]:SetProperty("Font", "InventoryCountFont");
    end

    for i = 1, NUM_BAG_SLOTS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot:SetSize(buttonSize, buttonSize);
        slot:SetProperty("Font", "InventoryCountFont");
        InventoryItemButton_EnableQualityBorder(slot);
        slot.id = 65299 + i - 1;

        BagContainer:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 24 * INVENTORY_SCALE);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, (i - 1) * buttonSize);
        slot:SetProperty("Background", "Interface/Icons/ItemSlots/icons_01_bag.htex");
    end

    InventoryFrame_UpdateSlots(this);

    this:RegisterEvent("EQUIPMENT_CHANGED", InventoryFrame_UpdateSlots);

	InventoryFrame:GetChild(0):GetChild(0):SetClickedHandler(ToggleInventory);
	AddMenuBarButton("Interface/GameUI/Alestia/MenuIcons/Inventory.htex", ToggleInventory, "MENUBAR_TOOLTIP_INVENTORY", "TOGGLEINVENTORY");

    this:RegisterEvent("MONEY_CHANGED", InventoryFrame_UpdateMoney);
end

function InventoryFrame_OnShow(this)
    for i = 1, NUM_BAG_SLOTS do
        local slotCount = GetContainerNumSlots(i - 1);
    end
end

function InventoryFrame_Update(this, delta)
end

function InventoryFrame_UpdateMoney(self)
    local money = UnitMoney("player");
    RefreshMoneyFrame("PlayerMoneyFrame", money, false, false, true, INVENTORY_SCALE);
end

function OpenInventory()
    if ( not CanOpenPanels() ) then
        return;
    end    
    InventoryFrame:Show();
end

function ToggleInventory()
    if (InventoryFrame:IsVisible()) then    
        InventoryFrame:Hide();
    else
        OpenInventory();
    end
end
