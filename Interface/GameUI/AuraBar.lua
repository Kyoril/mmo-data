
function AuraBar_OnLoad(self)
    self:RegisterEvent("PLAYER_AURA_UPDATE", AuraBar_OnUpdate);
end

function AuraBar_OnUpdate(self)
    local unit = GetUnit("player");
    if not unit then
        -- Hide all buttons if player unit doesn't exist
        for i = 1, 8 do
            local buffButton = _G["BuffButton"..i];
            local debuffButton = _G["DebuffButton"..i];
            if buffButton then
                buffButton:Hide();
            end
            if debuffButton then
                debuffButton:Hide();
            end
        end
        return;
    end

    local auraCount = unit:GetAuraCount();
    
    -- Separate auras into buffs and debuffs
    local buffs = {};
    local debuffs = {};
    
    for i = 0, auraCount - 1 do
        local aura = unit:GetAura(i);
        if aura and not aura:IsExpired() then
            if aura:IsNegative() then
                table.insert(debuffs, aura);
            else
                table.insert(buffs, aura);
            end
        end
    end
    
    -- Debug output
    print("Total auras: " .. auraCount .. ", Buffs: " .. #buffs .. ", Debuffs: " .. #debuffs);
    
    -- Update buff buttons
    for i = 1, 8 do
        local button = _G["BuffButton"..i];
        if button then
            if i <= #buffs then
                AuraButton_RefreshWithAura(button, buffs[i], true);
            else
                button:Hide();
            end
        end
    end
    
    -- Update debuff buttons
    for i = 1, 8 do
        local button = _G["DebuffButton"..i];
        if button then
            if i <= #debuffs then
                AuraButton_RefreshWithAura(button, debuffs[i], true);
            else
                button:Hide();
            end
        end
    end
end
