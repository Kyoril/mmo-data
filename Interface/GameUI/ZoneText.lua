
ZoneFadeInDuration = 500;
ZoneHoldDuration = 1000;
ZoneFadeOutDuration = 2000;

function OnZoneChanged(frame)
    local newText = GetZoneText() or "";
    local newSubText = GetSubZoneText() or "";

    ZoneText:SetText(newText);
    ZoneSubText:SetText(newSubText);
    FadingFrame_Show(ZoneText);
    FadingFrame_Show(ZoneSubText);
end

function ZoneText_OnLoad(frame)
    FadingFrame_OnLoad(frame);
    FadingFrame_SetFadeInTime(frame, ZoneFadeInDuration);
    FadingFrame_SetHoldTime(frame, ZoneHoldDuration);
    FadingFrame_SetFadeOutTime(frame, ZoneFadeOutDuration);
    frame:RegisterEvent("ZONE_CHANGED", OnZoneChanged);
end

function ZoneText_OnUpdate(frame, elapsed)
    FadingFrame_OnUpdate(frame);
end
