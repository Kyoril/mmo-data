
NUM_BACKPACK_SLOTS = 16
NUM_BAG_SLOTS = 4
INVENTORY_SLOTS_PER_ROW = 8

function InventoryFrame_UpdateSlots(this)
    local buttonSize = InventoryItemButtonTemplate:GetWidth();
    local numSlots = NUM_BACKPACK_SLOTS;
    local slotsAdded = 0;

    ItemSlotContainer:RemoveAllChildren();

    -- Ensure backpack slots are created
    for i = 1, NUM_BACKPACK_SLOTS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot.id = GetBackpackSlot(i - 1);
        ItemSlotContainer:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 24 + buttonSize + 16 + math.fmod((i - 1), INVENTORY_SLOTS_PER_ROW) * buttonSize);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, math.floor((i - 1) / INVENTORY_SLOTS_PER_ROW) * buttonSize);
        slotsAdded = slotsAdded + 1;
    end

    for i = 1, NUM_BAG_SLOTS do
        local bagSlots = GetContainerNumSlots(i - 1);
        numSlots = numSlots + bagSlots;

        for j = 1, bagSlots do
            local slot = InventoryItemButtonTemplate:Clone();
            slot.id = ((i - 1 + 19) * 256) + (j - 1);    -- pack bag slot
            ItemSlotContainer:AddChild(slot);

            slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 24 + buttonSize + 16 + math.fmod(slotsAdded, INVENTORY_SLOTS_PER_ROW) * buttonSize);
            slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, math.floor(slotsAdded / INVENTORY_SLOTS_PER_ROW) * buttonSize);

            slotsAdded = slotsAdded + 1;
        end
    end
    
    local minRowCount = math.max(math.ceil(numSlots / INVENTORY_SLOTS_PER_ROW), 4);

    this:SetWidth(48 + INVENTORY_SLOTS_PER_ROW * buttonSize + 16 + buttonSize);
    this:SetHeight(48 + minRowCount * buttonSize + PlayerMoney:GetHeight() + InventoryTitleBar:GetHeight());
end

function InventoryFrame_Load(this)
    local buttonSize = InventoryItemButtonTemplate:GetWidth();

    for i = 1, NUM_BAG_SLOTS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot.id = 65299 + i - 1;

        BagContainer:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 24);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, (i - 1) * buttonSize);
        slot:SetProperty("Background", "Interface/Icons/ItemSlots/icons_01_bag.htex");
    end

    InventoryFrame_UpdateSlots(this);

    this:RegisterEvent("EQUIPMENT_CHANGED", InventoryFrame_UpdateSlots);

	InventoryFrame:GetChild(0):GetChild(0):SetClickedHandler(ToggleInventory);
	AddMenuBarButton("Interface/Icons/fg4_icons_backpack_result.htex", ToggleInventory)
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

    local gold = math.floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
    local silver = math.floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = math.fmod(money, COPPER_PER_SILVER);

    CopperText:SetText(tostring(copper));

    if silver > 0 then
        SilverText:SetText(tostring(silver));
        SilverText:Show();
    else
        SilverText:Hide();
    end

    if gold > 0 then
        GoldText:SetText(tostring(gold));
        GoldText:Show();
    else
        GoldText:Hide();
    end
end

function ToggleInventory()
    if (InventoryFrame:IsVisible()) then    
        InventoryFrame:Hide();
    else
        if ( not CanOpenPanels() ) then
            return;
        end    
        InventoryFrame:Show();
    end
end
