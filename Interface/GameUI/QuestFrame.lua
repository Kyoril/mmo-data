
function QuestFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("QUESTS"));
end

function QuestFrame_OnShow(self)
    
end

function QuestFrame_Toggle()
    if (QuestFrame:IsVisible()) then
        HideUIPanel(QuestFrame);
    else
        ShowUIPanel(QuestFrame);
    end
end
