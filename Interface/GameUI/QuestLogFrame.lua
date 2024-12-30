
function QuestLogFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("QUESTS"));

    AddMenuBarButton("Interface/Icons/fg4_icons_questlog_result.htex", QuestLogFrame_Toggle);
end

function QuestLogFrame_Toggle()
    if QuestLogFrame:IsVisible() then
        HideUIPanel(QuestLogFrame);
    else
        ShowUIPanel(QuestLogFrame);
    end
end

function QuestLogFrame_OnShow(self)

end