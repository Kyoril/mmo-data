
NUM_BACKPACK_SLOTS = 16
NUM_BAG_SLOTS = 4
INVENTORY_SLOTS_PER_ROW = 8

function InventoryFrame_Load(this)
    local buttonSize = InventoryItemButtonTemplate:GetWidth();

    -- Ensure backpack slots are created
    for i = 1, NUM_BACKPACK_SLOTS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot.id = GetBackpackSlot(i - 1);
        this:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, this, 64 + math.fmod((i - 1), INVENTORY_SLOTS_PER_ROW) * buttonSize);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, InventoryTitleBar, math.floor((i - 1) / INVENTORY_SLOTS_PER_ROW) * buttonSize);
    end

    this:SetWidth(128 + INVENTORY_SLOTS_PER_ROW * buttonSize);
    this:SetHeight(128 + math.ceil(NUM_BACKPACK_SLOTS / INVENTORY_SLOTS_PER_ROW) * buttonSize + PlayerMoney:GetHeight() + InventoryTitleBar:GetHeight());

    
	AddMenuBarButton("Interface/Icons/fg4_icons_backpack_result.htex", ToggleInventory)
end

function InventoryFrame_OnShow(this)
    
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
