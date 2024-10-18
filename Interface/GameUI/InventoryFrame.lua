
function InventoryFrame_Load(self)

end

function InventoryFrame_Update(self, delta)

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
