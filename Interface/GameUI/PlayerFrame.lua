
ResourceBarColors = {}
ResourceBarColors[0] = "FF0000FF"; -- Mana
ResourceBarColors[1] = "FFFF0000"; -- Rage
ResourceBarColors[2] = "FFFFFF00"; -- Energy

function PlayerFrame_Update(self)
    local player = GetUnit("player");
    PlayerName:SetText(player:GetName());
    PlayerPortraitLevel:SetText(tostring(player:GetLevel()));

    local health = player:GetHealth();
    local maxHealth = player:GetMaxHealth();
    PlayerHealthBar:SetProgress(health / maxHealth);
    PlayerHealthBar:SetText(health .. " / " .. maxHealth);

    -- Get power type
    local powerType = player:GetPowerType();
    PlayerManaBar:SetProperty("ProgressColor", ResourceBarColors[powerType]);

    local power = player:GetPower(powerType);
    local maxPower = player:GetMaxPower(powerType);
    PlayerManaBar:SetProgress(power / maxPower);
    PlayerManaBar:SetText(power .. " / " .. maxPower);
end

function PlayerFrame_OnUnitNameUpdate(self, unit)
    if (unit == "player") then
        local player = GetUnit(unit);
        PlayerName:SetText(player:GetName());
    end
end

function PlayerFrame_UpdateLeader(self)
    if (IsPartyLeader()) then
        self:GetChild(4):Show();
    else
        self:GetChild(4):Hide();
    end
end

function PlayerFrame_OnEnterWorld(self)
    PlayerFrame_Update(self);
    PlayerPortraitModel:SetUnit("player");
end

function PlayerFrame_OnCombatModeChanged(self, inCombat)
    if (inCombat) then
        PlayerPortraitCombat:Show();
    else
        PlayerPortraitCombat:Hide();
    end

end

function PlayerFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTER_WORLD", PlayerFrame_OnEnterWorld);
    self:RegisterEvent("COMBAT_MODE_CHANGED", PlayerFrame_OnCombatModeChanged);
    self:RegisterEvent("PLAYER_HEALTH_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_POWER_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_LEVEL_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("UNIT_NAME_UPDATE", PlayerFrame_OnUnitNameUpdate);
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", PlayerFrame_UpdateLeader);
    self:RegisterEvent("PARTY_LEADER_CHANGED", PlayerFrame_UpdateLeader);
end

function PlayerFrame_OnClick(self)
    TargetUnit("player");
end
