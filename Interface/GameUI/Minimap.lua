function Minimap_OnLoad(self)
    self:RegisterEvent("ZONE_CHANGED", Minimap_OnZoneChanged);
end

function Minimap_OnZoneChanged(self)
    local zoneText = GetSubZoneText() or "";
    if zoneText == "" then
        zoneText = GetZoneText() or "";
    end

    MinimapTitleBar:SetText(zoneText);
end

function Minimap_Toggle(self)
    if MinimapBorder:IsVisible() then
        MinimapBorder:Hide();
    else
        MinimapBorder:Show();
    end
end

function Minimap_OnShow(self)
    
end

function Minimap_OnHide(self)
    
end

function Minimap_OnUpdate(self, elapsed)
    
end
