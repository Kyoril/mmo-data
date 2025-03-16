
function CharacterWindow_Toggle()
    if (CharacterWindow:IsVisible()) then
        HideUIPanel(CharacterWindow);
    else
        local player = GetUnit("player");
        if player then
            CharacterWindowTitle:SetText(player:GetName());
            CharacterFrameModel:SetProperty("ModelFile", "Models/Character/Human/Male/HumanMale.hmsh");
        end

        CharacterFrameModel:SetHeight(CharacterFrameModel:GetHeight() + 1);
        ShowUIPanel(CharacterWindow);
    end
end

function CharacterWindow_OnLoad(self)
	-- Subscribe for title bar close handler (HACKY! Order of items is important which sucks)
	CharacterWindow:GetChild(0):GetChild(0):SetClickedHandler(CharacterWindow_Toggle);

    self:RegisterEvent("PLAYER_ATTRIBUTES_CHANGED", CharacterWindow_RefreshStats);
    self:RegisterEvent("PLAYER_ENTER_WORLD", CharacterWindow_OnEnterWorld);
    self:RegisterEvent("PLAYER_MODEL_CHANGED", CharacterWindow_OnPlayerModelChanged);

    -- Register the character window in the menu bar as a button
	AddMenuBarButton("Interface/Icons/fg4_icons_helmet_result.htex", CharacterWindow_Toggle);

    CharacterArmorStat:SetOnEnterHandler(CharacterWindow_ArmorLabel_OnEnter);
    CharacterArmorStat:SetOnLeaveHandler(CharacterWindow_HideTooltip);
end

function CharacterWindow_ArmorLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(Localize("ARMOR"), TOOLTIP_LINE_LEFT, "FFFFD100");
    GameTooltip_AddLine(string.format(Localize("ARMOR_DESCRIPTION"), unit:GetArmorReductionFactor() * 100.0), TOOLTIP_LINE_LEFT, "FFFFD100");

    GameTooltip:Show();
end

function CharacterWindow_HideTooltip()
    GameTooltip:Hide();
end

function CharacterWindow_OnShow(this)
    CharacterWindow_RefreshStats();
    CharacterFrameModel:SetUnit("player");

    local player = GetUnit("player");
    if player then
        CharacterLevelLabel:SetText(string.format(Localize("LEVEL_FORMAT"), player:GetLevel()));
    end
end

function CharacterWindow_AddAttributeClicked(this)
    AddAttributePoint(this.id);
end

function CharacterWindow_OnEnterWorld(this)
    CharacterFrameModel:SetUnit("player");
end

function CharacterWindow_OnPlayerModelChanged(self)
    CharacterFrameModel:SetUnit("player");
end

function CharacterWindow_RefreshStats()
    local player = GetUnit("player");
    local attributePointsAvailable = player:GetAvailableAttributePoints();

    for attribute = 0, 4 do
        local attributeCost = UnitAttributeCost("player", attribute);
        if (attributeCost > attributePointsAvailable) then
            _G["CharacterStatAdd" .. attribute]:Disable();
        else
            _G["CharacterStatAdd" .. attribute]:Enable();
        end
    end

    CharacterWindowAttributePointsLabel:SetText(tostring(attributePointsAvailable));

    for i = 0, 4 do
        local base, modifier = UnitStat("player", i);

        local statName = "CharacterStat" .. i;
        local statValue = _G[statName];
        if (statValue ~= nil) then
            statValue:SetText(tostring(base + modifier));

            if (modifier > 0) then
                statValue:SetProperty("Color", "FF20FF20")
            elseif (modifier < 0) then
                statValue:SetProperty("Color", "FFFF2020")
            else
                statValue:SetProperty("Color", "FFFFFFFF")
            end
        end
    end

    local attackTimeSeconds = player:GetAttackTime() / 1000.0;
    CharacterAttackTimeStat:SetText(string.format("%.2f", attackTimeSeconds));
    CharacterAttackPowerStat:SetText(string.format("%.0f", player:GetAttackPower()));

    local minDamage = player:GetMinDamage();
    local maxDamage = player:GetMaxDamage();
    if minDamage == maxDamage then
        CharacterDamageStat:SetText(string.format("%.0f", minDamage));
    else
        CharacterDamageStat:SetText(string.format("%.0f - %.0f", minDamage, maxDamage));
    end
    

    local baseArmor, modifierArmor = UnitArmor("player");
    CharacterArmorStat:SetText(tostring(baseArmor + modifierArmor));
    if (modifierArmor > 0) then
        CharacterArmorStat:SetProperty("Color", "FF20FF20")
    elseif (modifierArmor < 0) then
        CharacterArmorStat:SetProperty("Color", "FFFF2020")
    else
        CharacterArmorStat:SetProperty("Color", "FFFFFFFF")
    end

end
