-- Inspect displays public equipment templates, never interactive inventory slots.
local inspectedUnit = nil;
local slots = {};
local refreshElapsed = 0;
local stopMoving = nil;

function InspectWindow_Open(unitToken)
    local unit = GetUnit(unitToken);
    if not unit or unit:GetType() ~= "PLAYER" or unit == GetUnit("player") or not CanInteractWithPlayer(unitToken) then return; end

    inspectedUnit = unitToken;
    GameTooltip:Hide();
    InspectWindowTitle:SetText(unit:GetName());
    InspectLevelLabel:SetText(string.format(Localize("LEVEL_FORMAT"), unit:GetLevel()));
    InspectModel:SetUnit(unitToken);
    InspectWindow_Refresh();
    ShowUIPanel(InspectWindow);
    InspectWindow:BringToFront();
end

function InspectWindow_SlotOnEnter(slot)
    if not inspectedUnit then return; end
    local item = GetEquipmentSlotItem(inspectedUnit, slot.id);
    if not item then GameTooltip:Hide(); return; end
    GameTooltip_SetItemTemplate(item);
    GameTooltip_AnchorToFrame(slot);
    GameTooltip:Show();
end

function InspectWindow_Refresh()
    local unit = inspectedUnit and GetUnit(inspectedUnit);
    if not unit or not CanInteractWithPlayer(inspectedUnit) then
        InspectWindow:Hide();
        return;
    end
    InspectWindowTitle:SetText(unit:GetName());
    InspectLevelLabel:SetText(string.format(Localize("LEVEL_FORMAT"), unit:GetLevel()));
    for _, slot in ipairs(slots) do
        local item = GetEquipmentSlotItem(inspectedUnit, slot.id);
        slot:SetProperty("Icon", item and item:GetIcon() or "");
        slot:SetProperty("QualityColor", item and ItemQualityColors[item.quality] or INVENTORY_QUALITY_COLOR_EMPTY);
        slot:SetProperty("BackgroundColor", item and "00FFFFFF" or "FF909090");
        if slot:IsHovered() then InspectWindow_SlotOnEnter(slot); end
    end
end

function InspectWindow_OnLoad(self)
    stopMoving = EnableWindowDragging(InspectWindow, InspectWindowTitle);
    InspectWindowCloseButton:SetClickedHandler(function() HideUIPanel(InspectWindow); end);
    for i = 0, 18 do
        local slot = _G["InspectSlot" .. i];
        slot:SetOnEnterHandler(InspectWindow_SlotOnEnter);
        slot:SetOnLeaveHandler(function() GameTooltip:Hide(); end);
        -- Inspect slots consume clicks, but cannot pick up, equip, trade or use items.
        slot:SetClickedHandler(function() end);
        table.insert(slots, slot);
    end
    self:RegisterEvent("PLAYER_ENTER_WORLD", function() InspectWindow:Hide(); end);
end

function InspectWindow_OnUpdate(self, elapsed)
    if not self:IsVisible() or not inspectedUnit then return; end
    -- Public fields and item-cache answers can arrive separately; retry only while visible.
    refreshElapsed = refreshElapsed + elapsed;
    if refreshElapsed >= 0.25 then
        refreshElapsed = 0;
        InspectWindow_Refresh();
    end
end

function InspectWindow_OnHide()
    if stopMoving then stopMoving(); end
    inspectedUnit = nil;
    InspectModel:SetUnit("");
    GameTooltip:Hide();
end
