
ZoneFadeInDuration = 500;
ZoneHoldDuration = 1000;
ZoneFadeOutDuration = 2000;

function ZoneText_OnZoneChanged(this)
    local text = ZoneText:GetText();
    local newText = GetZoneText();

    if(text ~= newText) then
        ZoneText:SetText(newText);
        FadingFrame_Show(ZoneText);
    end
end

function ZoneText_OnLoad(this)
    FadingFrame_OnLoad(ZoneText);
    FadingFrame_SetFadeInTime(ZoneText, ZoneFadeInDuration);
    FadingFrame_SetHoldTime(ZoneText, ZoneHoldDuration);
    FadingFrame_SetFadeOutTime(ZoneText, ZoneFadeOutDuration);
    
    ZoneText:RegisterEvent("ZONE_CHANGED", ZoneText_OnZoneChanged);
end

function ZoneText_OnUpdate(this, elapsed)
    FadingFrame_OnUpdate(ZoneText);
end
