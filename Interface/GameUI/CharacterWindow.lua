
function CharacterWindow_Toggle()
    if (CharacterWindow:IsVisible()) then
        HideUIPanel(CharacterWindow);
    else
        CharacterWindowTitle:SetText(UnitName("player"));
        CharacterFrameModel:SetProperty("ModelFile", "Models/Character/Human/Male/HumanMale.hmsh");
        CharacterFrameModel:SetHeight(CharacterFrameModel:GetHeight() + 1);
        ShowUIPanel(CharacterWindow);
    end
end

function CharacterWindow_OnLoad(self)
	-- Subscribe for title bar close handler (HACKY! Order of items is important which sucks)
	CharacterWindow:GetChild(0):GetChild(0):SetClickedHandler(CharacterWindow_Toggle);

    self:RegisterEvent("PLAYER_ATTRIBUTES_CHANGED", CharacterWindow_RefreshStats);

    -- Register the character window in the menu bar as a button
	AddMenuBarButton("Interface/Icons/fg4_icons_helmet_result.htex", CharacterWindow_Toggle);
end

function CharacterWindow_OnShow(this)
    CharacterWindow_RefreshStats();
    
    local displayId = UnitDisplayId("player");
    if (displayId and displayId >= 0) then
        local model = gameData.models:GetById(displayId);
        if (model) then
            CharacterFrameModel:SetProperty("ModelFile", model.filename);
            CharacterFrameModel:Show();
        else
            CharacterFrameModel:Hide();
        end
    else
        CharacterFrameModel:Hide();
    end
end

function CharacterWindow_AddAttributeClicked(this)
    AddAttributePoint(this.id);
end

function CharacterWindow_RefreshStats()
    local attributePointsAvailable = UnitNumAttributePoints("player");

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
