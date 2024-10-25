
function CharacterWindow_Toggle()
    if (CharacterWindow:IsVisible()) then
        HideUIPanel(CharacterWindow);
    else
        CharacterWindowTitle:SetText(UnitName("player"));
        CharacterFrameModel:SetProperty("ModelFile", "Models/Character/Human/Male/HumanMale.hmsh");
        CharacterFrameModel:SetHeight(CharacterFrameModel:GetHeight() + 1);
        ShowUIPanel(CharacterWindow);
        CharacterWindow_RefreshStats();
    end
end

function CharacterWindow_OnLoad(self)
    -- Register the character window in the menu bar as a button
	AddMenuBarButton("Interface/Icons/fg4_icons_helmet_result.htex", CharacterWindow_Toggle);
end

function CharacterWindow_RefreshStats()
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
