-- Initialize these so that the first call sets the time correctly
lastMinimapTimeHour = -1;
lastMinimapTimeMinute = -1;

function Minimap_OnLoad(self)
    self:RegisterEvent("ZONE_CHANGED", Minimap_OnZoneChanged);

    Minimap_OnZoomChanged();
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
            MinimapDayNight:SetProperty("Icon", "Interface/Icons/MinimapNight.htex");
        elseif hour >= 5 and lastMinimapTimeHour < 5 then
            -- TODO: Play sunrise sound
            MinimapDayNight:SetProperty("Icon", "Interface/Icons/MinimapDay.htex");
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

-- Track whether the mouse is over the minimap
MinimapContent_mouseOver = false;

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

    -- DEBUG: log every second so we can see this fires and what coords look like
    if not Minimap_debugTimer then Minimap_debugTimer = 0; end
    Minimap_debugTimer = Minimap_debugTimer + elapsed;
    if Minimap_debugTimer >= 1.0 then
        Minimap_debugTimer = 0;
        print(string.format("MinimapUpdate: cursor=(%.0f,%.0f) frame=(%.0f,%.0f,%.0f,%.0f) uv=(%.2f,%.2f)",
            cursor.x, cursor.y, fx, fy, fw, fh, u, v));
    end

    if u < 0 or u > 1 or v < 0 or v > 1 then
        GameTooltip:Hide();
        return;
    end

    local objects = GetMinimapObjectsAt(u, v);
    print(string.format("MinimapObjectsAt(%.2f,%.2f) returned %d objects", u, v, objects ~= nil and #objects or -1));
    if objects == nil or #objects == 0 then
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

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.LEFT, MinimapContent, 0);
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, MinimapContent, 0);
    GameTooltip:Show();
end
