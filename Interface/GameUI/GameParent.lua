
ErrorTimer = 0.0

function GameParent_OnSpellError(self, spellError)
    ErrorTimer = 4.0;
    ErrorText:SetText(Localize(spellError));
    ErrorText:Show();
end

function GameParent_OnAttackSwingError(self, attackSwingError)
    ErrorTimer = 1.0;
    ErrorText:SetText(Localize(attackSwingError));
    ErrorText:Show();
end

function GameParent_OnLoad(self)
    self:RegisterEvent("PLAYER_SPELL_CAST_FAILED", GameParent_OnSpellError);
    self:RegisterEvent("ATTACK_SWING_ERROR", GameParent_OnAttackSwingError);
end

function GameParent_OnUpdate(self, elapsed)
    if (ErrorTimer <= 0.0) then
        return
    end

    ErrorTimer = ErrorTimer - elapsed

    if (ErrorTimer <= 0.0) then
        ErrorText:Hide();
    end
end
