NUM_BANK_SLOTS = 28;
NUM_BANK_BAG_SLOTS = 7;
BANK_SLOTS_PER_ROW = 7;
BANK_VISIBLE_ROWS = 6;

-- Bank item slots start at absolute slot (255 * 256) + 39.
BANK_FIRST_ITEM_SLOT = 65319;
-- Bank bag slots start at absolute slot (255 * 256) + 67.
BANK_FIRST_BAG_SLOT = 65347;
-- Bank bag content slot ids use the bank bag slot index (67-73) as bag id.
BANK_FIRST_BAG_ID = 67;

-- Linear list of all reachable bank slot ids (28 bank slots followed by the
-- contents of every bag placed in a bank bag slot). The visible button grid is a
-- fixed-size window into this list, moved by the scrollbar (virtual scrolling).
local bankSlotList = {};
local bankScrollOffset = 0;
local bankSlotButtons = {};
local bankBagButtons = {};

function BankFrame_IsBankSlot(slotId)
    if (slotId >= BANK_FIRST_ITEM_SLOT) and (slotId < BANK_FIRST_BAG_SLOT + NUM_BANK_BAG_SLOTS) then
        return true;
    end

    -- Slots inside bags placed in bank bag slots
    local bagId = math.floor(slotId / 256);
    return (bagId >= BANK_FIRST_BAG_ID) and (bagId < BANK_FIRST_BAG_ID + NUM_BANK_BAG_SLOTS);
end

function BankFrame_RebuildSlotList()
    bankSlotList = {};

    for i = 0, NUM_BANK_SLOTS - 1 do
        table.insert(bankSlotList, BANK_FIRST_ITEM_SLOT + i);
    end

    for bag = 0, NUM_BANK_BAG_SLOTS - 1 do
        local numSlots = GetBankBagNumSlots(bag);
        for slot = 0, numSlots - 1 do
            table.insert(bankSlotList, ((BANK_FIRST_BAG_ID + bag) * 256) + slot);
        end
    end
end

function BankFrame_Refresh()
    local totalRows = math.ceil(#bankSlotList / BANK_SLOTS_PER_ROW);
    local maxScroll = math.max(0, totalRows - BANK_VISIBLE_ROWS);

    if (bankScrollOffset > maxScroll) then
        bankScrollOffset = maxScroll;
    end

    BankScrollBar:SetMaximum(maxScroll);
    if (maxScroll > 0) then
        BankScrollBar:Enable();
    else
        BankScrollBar:Disable();
    end

    -- Remap the fixed button grid onto the visible window of the virtual slot list
    for i = 1, BANK_SLOTS_PER_ROW * BANK_VISIBLE_ROWS do
        local button = bankSlotButtons[i];
        local slotId = bankSlotList[(bankScrollOffset * BANK_SLOTS_PER_ROW) + i];
        if (slotId) then
            button.id = slotId;
            button:Show();
        else
            button.id = -1;
            button:Hide();
        end
    end

    -- Only purchased bank bag slots can hold bags
    local purchasedSlots = GetNumBankBagSlots();
    for i = 1, NUM_BANK_BAG_SLOTS do
        if (i <= purchasedSlots) then
            bankBagButtons[i]:Show();
        else
            bankBagButtons[i]:Hide();
        end
    end

    BankFrame_UpdateBuySlotPanel();
end

function BankFrame_UpdateSlots(this)
    BankFrame_RebuildSlotList();
    BankFrame_Refresh();
end

function BankFrame_UpdateBuySlotPanel()
    local price = GetNextBankBagSlotPrice();
    if (price > 0) then
        BankBuySlotButton:Show();
        BankSlotPriceFrame:Show();
        RefreshMoneyFrame("BankSlotPriceFrame", price, false, false, true);
    else
        BankBuySlotButton:Hide();
        BankSlotPriceFrame:Hide();
    end
end

-- Finds the first free purchased bank bag slot, or nil if none is available.
function BankFrame_FindFreeBankBagSlot()
    local purchasedSlots = GetNumBankBagSlots();
    for i = 0, purchasedSlots - 1 do
        local slotId = BANK_FIRST_BAG_SLOT + i;
        if (not GetInventorySlotItem("player", slotId)) then
            return slotId;
        end
    end

    return nil;
end

-- Finds the first free bank slot (including bank bag contents), or nil if the bank is full.
function BankFrame_FindFreeBankSlot()
    for i = 1, #bankSlotList do
        if (not GetInventorySlotItem("player", bankSlotList[i])) then
            return bankSlotList[i];
        end
    end

    return nil;
end

-- Finds the first free backpack or bag slot, or nil if the inventory is full.
function BankFrame_FindFreeInventorySlot()
    for i = 0, NUM_BACKPACK_SLOTS - 1 do
        local slotId = GetBackpackSlot(i);
        if (not GetInventorySlotItem("player", slotId)) then
            return slotId;
        end
    end

    for bag = 0, NUM_BAG_SLOTS - 1 do
        local numSlots = GetContainerNumSlots(bag);
        for slot = 0, numSlots - 1 do
            local slotId = ((bag + 19) * 256) + slot;
            if (not GetInventorySlotItem("player", slotId)) then
                return slotId;
            end
        end
    end

    return nil;
end

-- Right click while the bank is open: move the item between inventory and bank.
function BankFrame_OnItemRightClicked(slotId)
    local targetSlot;
    if (BankFrame_IsBankSlot(slotId)) then
        targetSlot = BankFrame_FindFreeInventorySlot();
    else
        -- Bags prefer a free bank bag slot before being stored like a regular item
        local item = GetInventorySlotItem("player", slotId);
        if (item and item:GetBagSlots() > 0) then
            targetSlot = BankFrame_FindFreeBankBagSlot();
        end

        if (not targetSlot) then
            targetSlot = BankFrame_FindFreeBankSlot();
        end
    end

    if (not targetSlot) then
        return;
    end

    PickupContainerItem(slotId);
    PickupContainerItem(targetSlot);
end

function BankFrame_OnBankShow(this)
    bankScrollOffset = 0;
    BankScrollBar:SetValue(0);

    BankFrame_UpdateSlots(this);

    ShowUIPanel(BankFrame);
    OpenInventory();
end

function BankFrame_OnBankClosed(this)
    HideUIPanel(BankFrame);
end

function BankFrame_OnUpdate(this, elapsed)
    -- Placing or removing a bag in a bank bag slot changes the reachable slot
    -- count without a dedicated event, so detect layout changes cheaply here.
    local total = NUM_BANK_SLOTS;
    for bag = 0, NUM_BANK_BAG_SLOTS - 1 do
        total = total + GetBankBagNumSlots(bag);
    end

    if (total ~= #bankSlotList) then
        BankFrame_UpdateSlots(this);
    end
end

function BankFrame_Load(this)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(this);

    this:GetChild(0):SetText(Localize("BANK"));

    local buttonSize = InventoryItemButtonTemplate:GetWidth();

    -- Create the fixed button grid once; scrolling only remaps button ids
    for i = 1, BANK_SLOTS_PER_ROW * BANK_VISIBLE_ROWS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot.id = -1;
        BankSlotContainer:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, BankSlotContainer, math.fmod((i - 1), BANK_SLOTS_PER_ROW) * buttonSize);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, BankSlotContainer, math.floor((i - 1) / BANK_SLOTS_PER_ROW) * buttonSize);
        bankSlotButtons[i] = slot;
    end

    for i = 1, NUM_BANK_BAG_SLOTS do
        local slot = InventoryItemButtonTemplate:Clone();
        slot.id = BANK_FIRST_BAG_SLOT + i - 1;
        BankBagContainer:AddChild(slot);
        slot:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, BankBagContainer, (i - 1) * buttonSize);
        slot:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, BankBagContainer, 0);
        slot:SetProperty("Background", "Interface/Icons/ItemSlots/icons_01_bag.htex");
        slot:Hide();
        bankBagButtons[i] = slot;
    end

    BankScrollBar:SetMinimum(0);
    BankScrollBar:SetMaximum(0);
    BankScrollBar:SetValue(0);
    BankScrollBar:SetStep(1);
    BankScrollBar:SetOnValueChangedHandler(function(self, value)
        bankScrollOffset = math.floor(value + 0.5);
        BankFrame_Refresh();
    end);

    BankFrame:SetWidth(48 + BANK_SLOTS_PER_ROW * buttonSize + 96 + 8);
    BankFrame:SetHeight(48 + BANK_VISIBLE_ROWS * buttonSize + BankBagContainer:GetHeight() + BankBuySlotPanel:GetHeight() + BankFrame_SidePanelTitleBar:GetHeight());

    this:RegisterEvent("BANK_SHOW", BankFrame_OnBankShow);
    this:RegisterEvent("BANK_CLOSED", BankFrame_OnBankClosed);
    this:RegisterEvent("BANK_SLOTS_CHANGED", BankFrame_UpdateSlots);
    this:RegisterEvent("EQUIPMENT_CHANGED", BankFrame_UpdateSlots);
end
