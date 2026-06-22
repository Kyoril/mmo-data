
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
    TargetFrame:RegisterEvent("UNIT_AURA_UPDATED", TargetFrame_OnAuraUpdate);
end

-- Number of debuff slots available on the target frame (TargetAuraButton1..N).
TARGET_DEBUFF_SLOTS = 5;

function TargetFrame_OnUnitUpdate(self, unit)
    if (unit ~= "target") then
        return;
    end

    TargetFrame_Update();
end

-- Lightweight handler for aura-only changes: refresh just the debuff icons instead
-- of rebuilding the whole frame (and re-setting the portrait model).
function TargetFrame_OnAuraUpdate(self, unit)
    if (unit ~= "target") then
        return;
    end

    TargetFrame_UpdateAuras();
end

-- Clears the stored aura/spell state of a debuff slot and hides it. Without
-- explicitly clearing the stored aura, AuraButton_OnUpdate would keep refreshing a
-- stale aura, leaving old debuff icons visible after switching targets.
function TargetFrame_ClearAuraButton(button)
    local frameTable = _G[button:GetName()];
    if frameTable then
        frameTable.aura = nil;
        frameTable.spell = nil;
    end
    button:Hide();
end

function TargetFrame_UpdateAuras()
    local unit = GetUnit("target");
    if not unit then
        for i = 1, TARGET_DEBUFF_SLOTS do
            local button = _G["TargetAuraButton" .. i];
            if button then
                TargetFrame_ClearAuraButton(button);
            end
        end
        return;
    end

    local playerGuid = nil;
    local player = GetUnit("player");
    if player then
        playerGuid = player:GetGuid();
    end

    -- Collect the target's debuffs (negative auras), keeping the ones we applied
    -- ourselves separate so we can prioritize them.
    local mine = {};
    local others = {};

    local auraCount = unit:GetAuraCount();
    for i = 0, auraCount - 1 do
        local aura = unit:GetAura(i);
        if aura and not aura:IsExpired() and aura:IsNegative() then
            if playerGuid and aura:GetCasterId() == playerGuid then
                table.insert(mine, aura);
            else
                table.insert(others, aura);
            end
        end
    end

    -- Player-applied debuffs first, then everything else.
    local debuffs = {};
    for _, aura in ipairs(mine) do
        table.insert(debuffs, aura);
    end
    for _, aura in ipairs(others) do
        table.insert(debuffs, aura);
    end

    for i = 1, TARGET_DEBUFF_SLOTS do
        local button = _G["TargetAuraButton" .. i];
        if button then
            if i <= #debuffs then
                AuraButton_RefreshWithAura(button, debuffs[i], true);
            else
                TargetFrame_ClearAuraButton(button);
            end
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
