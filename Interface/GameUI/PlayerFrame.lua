
ResourceBarColors = {}
ResourceBarColors[0] = "FF0000FF"; -- Mana
ResourceBarColors[1] = "FFFF0000"; -- Rage
ResourceBarColors[2] = "FFFFFF00"; -- Energy

function PlayerFrame_Update(self)
    PlayerName:SetText(UnitName("player"));

    local health = UnitHealth("player");
    local maxHealth = UnitHealthMax("player");
    PlayerHealthBar:SetProgress(health / maxHealth);
    PlayerHealthBar:SetText(health .. " / " .. maxHealth);

    -- Get power type
    local powerType = UnitPowerType("player");
    PlayerManaBar:SetProperty("ProgressColor", ResourceBarColors[powerType]);

    local power = UnitPower("player", powerType);
    local maxPower = UnitPowerMax("player", powerType);
    PlayerManaBar:SetProgress(power / maxPower);
    PlayerManaBar:SetText(power .. " / " .. maxPower);
end

function PlayerFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTER_WORLD", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_HEALTH_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_POWER_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_LEVEL_CHANGED", PlayerFrame_Update);
end

function PlayerFrame_OnClick(self)
    print("Player frame clicked!");
    TargetUnit("player");
end
