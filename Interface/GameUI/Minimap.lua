function Minimap_OnLoad(self)
    self:RegisterEvent("ZONE_CHANGED", Minimap_OnZoneChanged);

    Minimap_OnZoomChanged();
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
