-- Initialize these so that the first call sets the time correctly
lastMinimapTimeHour = -1;
lastMinimapTimeMinute = -1;

function Minimap_OnLoad(self)
    self:RegisterEvent("ZONE_CHANGED", Minimap_OnZoneChanged);
    self:RegisterEvent("PARTY_PING", Minimap_OnPartyPing);
    self:RegisterEvent("PARTY_PING_UNIT", Minimap_OnPartyPing);

    Minimap_OnZoomChanged();

    -- Set the correct day/night icon immediately on load
    local hour, _ = GetGameTime();
    Minimap_UpdateDayNightIcon(hour);
end

function Minimap_OnPartyPing()
    -- Play ping sound when a ping is placed (add sound file to Interface/Sounds/Ping.ogg to enable)
    -- PlaySound("Interface/Sounds/Ping.ogg");
end

function Minimap_UpdateDayNightIcon(hour)
    if hour >= 21 or hour < 5 then
        MinimapDayNight:SetProperty("Icon", "Interface/Icons/MinimapNight.htex");
    else
        MinimapDayNight:SetProperty("Icon", "Interface/Icons/MinimapDay.htex");
    end
end

function Minimap_UpdateTime()
    local hour, minute = GetGameTime();
    TIME_TWENTYFOURHOURS = "%02d:%02d"; -- %d = hour, %d = minute

    -- Only update text if time changed to not stress the UI
    if hour ~= lastMinimapTimeHour or minute ~= lastMinimapTimeMinute then
        -- If hour just passed 5, it's sunrise
        if hour >= 21 and lastMinimapTimeHour < 21 then
            -- If hour just passed 21, it's sunset
            -- TODO: Play night sound
            Minimap_UpdateDayNightIcon(hour);
        elseif hour >= 5 and lastMinimapTimeHour < 5 then
            -- TODO: Play sunrise sound
            Minimap_UpdateDayNightIcon(hour);
        end

        lastMinimapTimeHour = hour;
        lastMinimapTimeMinute = minute;
        MinimapTime:SetText(string.format(TIME_TWENTYFOURHOURS, hour, minute));
    end
end

function Minimap_OnZoomChanged()
    if (GetMinimapZoomLevel() <= GetMinimapMinZoomLevel()) then
        MinimapZoomOut:Disable();
    else
        MinimapZoomOut:Enable();
    end
    if (GetMinimapZoomLevel() >= GetMinimapMaxZoomLevel()) then
        MinimapZoomIn:Disable();
    else
        MinimapZoomIn:Enable();
    end
end

function Minimap_OnZoneChanged(self)
    local zoneText = GetSubZoneText() or "";
    if zoneText == "" then
        zoneText = GetZoneText() or "";
    end

    MinimapTitleBar:SetText(zoneText);
end

function Minimap_Toggle(self)
    if MinimapContent:IsVisible() then
        MinimapContent:Hide();
    else
        MinimapContent:Show();
    end
end

function Minimap_OnShow(self)
    
end

function Minimap_OnHide(self)
    
end


-- Called from MinimapBorder's OnUpdate.
-- Hides the tooltip only when hovering over empty minimap space (so moving off a dot hides it),
-- but never hides it when the cursor is outside the minimap (that would clobber other tooltips).
function Minimap_OnUpdate(self, elapsed)
    local cursor = GetCursorPosition();
    local scale = GetUIScale();
    local fx = MinimapContent:GetX() / scale.x;
    local fy = MinimapContent:GetY() / scale.y;
    local fw = MinimapContent:GetWidth();
    local fh = MinimapContent:GetHeight();

    -- Normalised UV within the minimap frame [0,1]
    local u = (cursor.x - fx) / fw;
    local v = (cursor.y - fy) / fh;

    -- Cursor is outside the minimap — don't touch the tooltip.
    if u < 0 or u > 1 or v < 0 or v > 1 then
        return;
    end

    local objects = GetMinimapObjectsAt(u, v);
    if objects == nil or #objects == 0 then
        -- Hovering over empty minimap space: hide any minimap tooltip we may have shown.
        GameTooltip:Hide();
        return;
    end

    GameTooltip_Clear();

    for i, obj in ipairs(objects) do
        if obj.type == "party" then
            GameTooltip_AddLine(obj.name, TOOLTIP_LINE_LEFT, "FF00CCFF");
        elseif obj.type == "questgiver" then
            GameTooltip_AddLine(obj.name, TOOLTIP_LINE_LEFT, "FFFFFF00");
        end
    end

    -- Position tooltip at cursor with a small offset, flipping sides if it would
    -- overflow the right or bottom edge of the 4K logical screen (3840×2160).
    local TIP_OFFSET = 20;
    local SCREEN_W   = 3840;
    local SCREEN_H   = 2160;

    local tipW = GameTooltip:GetWidth();
    local tipH = GameTooltip:GetHeight();

    local anchorH, anchorV;   -- horizontal / vertical anchor points on the tooltip
    local offsetX, offsetY;

    -- Flip left if tooltip would overflow the right edge
    if cursor.x + TIP_OFFSET + tipW > SCREEN_W then
        anchorH  = AnchorPoint.RIGHT;
        offsetX  = cursor.x - TIP_OFFSET;
    else
        anchorH  = AnchorPoint.LEFT;
        offsetX  = cursor.x + TIP_OFFSET;
    end

    -- Flip up if tooltip would overflow the bottom edge
    if cursor.y + TIP_OFFSET + tipH > SCREEN_H then
        anchorV  = AnchorPoint.BOTTOM;
        offsetY  = cursor.y - TIP_OFFSET;
    else
        anchorV  = AnchorPoint.TOP;
        offsetY  = cursor.y + TIP_OFFSET;
    end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(anchorH, AnchorPoint.LEFT, nil, offsetX);
    GameTooltip:SetAnchor(anchorV, AnchorPoint.TOP,  nil, offsetY);
    GameTooltip:Show();
end
