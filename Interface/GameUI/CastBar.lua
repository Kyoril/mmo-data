
CastBarSpell = nil;
CastBarProgress = 0.0;
CastBarEndTime = 1.0;

function CastBar_OnCastStart(self, spell, castTime)
    CastBarSpell = spell;
    CastBarProgress = 0.0;

    if (spell == nil) then
        return
    end

    if (castTime == nil) then
        castTime = spell.casttime
    end

    CastBarEndTime = castTime / 1000.0;
    PlayerCastBar:SetProperty("Progress", "0.0");
    PlayerCastBar:SetText(CastBarSpell.name);

    PlayerCastBar:Show();
end

function CastBar_OnCastEnd(self, success)
    PlayerCastBar:Hide();
end

function CastBar_OnUpdate(self, elapsed)
    if (CastBarSpell == nil) then
        return
    end

    CastBarProgress = CastBarProgress + elapsed;

    -- Update progress value
    PlayerCastBar:SetProperty("Progress", string.format("%.2f", CastBarProgress / CastBarEndTime));
end

function CastBar_OnLoad(self)
    self:RegisterEvent("PLAYER_SPELL_CAST_START", CastBar_OnCastStart)
    self:RegisterEvent("PLAYER_SPELL_CAST_FINISH", CastBar_OnCastEnd)
end

