
ResourceBarColors = {}
ResourceBarColors[0] = "FF0000FF"; -- Mana
ResourceBarColors[1] = "FFFF0000"; -- Rage
ResourceBarColors[2] = "FFFFFF00"; -- Energy

function TargetFrame_OnLoad()
    TargetFrame_Update();

    TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED", TargetFrame_Update);
    TargetFrame:RegisterEvent("UNIT_HEALTH_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_POWER_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_LEVEL_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_NAME_UPDATED", TargetFrame_OnUnitUpdate);
end

function TargetFrame_OnUnitUpdate(self, unit)
    if (unit ~= "target") then
        return;
    end

    TargetFrame_Update();
end

function TargetFrame_UpdateAuras()
    local unit = GetUnit("target");
    for i = 1, 5 do
        local button = _G["TargetAuraButton" .. i];
        
        if not unit then
            button:Hide();
            return;
        end

        local auraCount = unit:GetAuraCount();
        if button.id > auraCount then
            button:Hide();
            return;
        end

        local aura = unit:GetAura(button.id - 1);
        if not aura then
            button:Hide();
            return;
        end

        -- TODO: If aura has expired, remove it from the list
        if aura:IsExpired() then
            button:Hide();
            return;
        end

        -- We have an aura in the given slot, show the button
        button:Show();

        local spell = aura:GetSpell();
        if spell then
            button:SetProperty("Icon", spell.icon);
        end
    end
end

function TargetFrame_Update()
    local target = GetUnit("target");

    if target then
        TargetName:SetText(target:GetName());
        TargetPortraitLevel:SetText(tostring(target:GetLevel()));
        TargetPortraitModel:SetUnit("target");

        if (target:IsFriendly()) then
            TargetName:SetProperty("TextColor", "FF00FF00");
        elseif (target:IsHostile()) then
            TargetName:SetProperty("TextColor", "FFFF0000");
        else
            TargetName:SetProperty("TextColor", "FFFFFF00");
        end

        -- Update progress bars
        health = target:GetHealth();
        maxHealth = target:GetMaxHealth();
        if (maxHealth == 0) then
            health = 0;
            maxHealth = 1;
        end

        healthPct = health / maxHealth;
        TargetHealthBar:SetProgress(healthPct);
        TargetHealthBar:SetText(math.floor(healthPct * 100) .. "%");

        -- Get power type
        local powerType = target:GetPowerType();
        TargetManaBar:SetProperty("ProgressColor", ResourceBarColors[powerType]);

        local power = target:GetPower(powerType);
        local maxPower = target:GetMaxPower(powerType);
        if (maxPower == 0) then
            power = 0;
            maxPower = 1;
        end
        
        local powerPct = power / maxPower;
        TargetManaBar:SetProgress(powerPct);
        TargetManaBar:SetText(math.floor(powerPct * 100) .. "%");

        TargetFrame:Show();

        TargetFrame_UpdateAuras();
    else
        TargetFrame:Hide();
    end
end

function TargetFrame_OnClick(self, button, x, y)
    if button == "RIGHT" then
        ContextMenu_Show("TARGET", x, y, nil)
    end
end
