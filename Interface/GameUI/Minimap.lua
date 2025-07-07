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

function Minimap_OnUpdate(self, elapsed)
    
end
