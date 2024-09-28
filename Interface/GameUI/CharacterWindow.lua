
function CharacterWindow_Toggle()
    if (CharacterWindow:IsVisible()) then
        CharacterWindow:Hide();
    else
        CharacterWindow:Show();
        CharacterWindow_RefreshStats();
    end
end

function CharacterWindow_OnLoad(self)
    -- Register the character window in the menu bar as a button
	AddMenuBarButton("Interface/Icons/fg4_icons_menu_result.htex", CharacterWindow_Toggle);
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
end
