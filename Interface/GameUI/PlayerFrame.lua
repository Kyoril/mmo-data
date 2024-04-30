
function PlayerFrame_Update(self)
    local health = UnitHealth("player");
    local maxHealth = UnitHealthMax("player");
    PlayerHealthBar:SetProgress(health / maxHealth);
    PlayerHealthBar:SetText(health .. " / " .. maxHealth);

    local mana = UnitMana("player");
    local maxMana = UnitManaMax("player");
    PlayerManaBar:SetProgress(mana / maxMana);
    PlayerManaBar:SetText(mana .. " / " .. maxMana);
end

function PlayerFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTER_WORLD", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_HEALTH_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_POWER_CHANGED", PlayerFrame_Update);
    self:RegisterEvent("PLAYER_LEVEL_CHANGED", PlayerFrame_Update);
end
