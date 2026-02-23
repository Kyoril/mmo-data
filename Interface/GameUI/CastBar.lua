
CastBarSpell = nil;
CastBarProgress = 0.0;
CastBarEndTime = 1.0;
CastBarIsChanneling = false;

function CastBar_OnCastStart(self, spell, castTime)
    CastBarSpell = spell;
    CastBarProgress = 0.0;
    CastBarIsChanneling = false;

    if (spell == nil) then
        return
    end

    if (castTime == nil) then
        castTime = spell.casttime
    end

    -- If no cast time, don't show the cast bar
    if (castTime <= 0) then
        return
    end

    CastBarEndTime = castTime / 1000.0;
    PlayerCastBar:SetProperty("Progress", "0.0");
    PlayerCastBar:SetText(CastBarSpell.name);

    PlayerCastBar:Show();
end

function CastBar_OnCastEnd(self, success)
    PlayerCastBar:Hide();
    CastBarIsChanneling = false;
end

function CastBar_OnChannelStart(self, spell, duration)
    CastBarSpell = spell;
    CastBarProgress = 0.0;
    CastBarIsChanneling = true;

    if (spell == nil) then
        return
    end

    if (duration == nil or duration <= 0) then
        return
    end

    CastBarEndTime = duration / 1000.0;
    PlayerCastBar:SetProperty("Progress", "1.0");
    PlayerCastBar:SetText(CastBarSpell.name);

    PlayerCastBar:Show();
end

function CastBar_OnChannelStop(self)
    PlayerCastBar:Hide();
    CastBarIsChanneling = false;
    CastBarSpell = nil;
end

function CastBar_OnUpdate(self, elapsed)
    if (CastBarSpell == nil) then
        return
    end

    CastBarProgress = CastBarProgress + elapsed;

    if (CastBarIsChanneling) then
        -- Channel: progress goes from 1.0 down to 0.0
        local remaining = 1.0 - (CastBarProgress / CastBarEndTime);
        if (remaining < 0.0) then
            remaining = 0.0;
        end
        PlayerCastBar:SetProperty("Progress", string.format("%.2f", remaining));
    else
        -- Normal cast: progress goes from 0.0 up to 1.0
        PlayerCastBar:SetProperty("Progress", string.format("%.2f", CastBarProgress / CastBarEndTime));
    end
end

function CastBar_OnLoad(self)
    self:RegisterEvent("PLAYER_SPELL_CAST_START", CastBar_OnCastStart)
    self:RegisterEvent("PLAYER_SPELL_CAST_FINISH", CastBar_OnCastEnd)
    self:RegisterEvent("PLAYER_CHANNEL_START", CastBar_OnChannelStart)
    self:RegisterEvent("PLAYER_CHANNEL_STOP", CastBar_OnChannelStop)
end
