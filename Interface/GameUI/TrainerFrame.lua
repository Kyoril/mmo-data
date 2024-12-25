
function TrainerFrame_OnTrainerShow(self)
    ShowUIPanel(self);
end

function TrainerFrame_OnTrainerUpdate(self)
    
end

function TrainerFrame_OnTrainerClosed(self)
    HideUIPanel(self);
end

function TrainerFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);

    -- Register for trainer events
    self:RegisterEvent("TRAINER_SHOW", TrainerFrame_OnTrainerShow);
    self:RegisterEvent("TRAINER_UPDATE", TrainerFrame_OnTrainerUpdate);
    self:RegisterEvent("TRAINER_CLOSED", TrainerFrame_OnTrainerClosed);
end

function TrainerFrame_OnShow(self)
    local target = GetUnit("target");
    if target then
        self:GetChild(0):SetText(target:GetName());
    end
end

function TrainerFrame_Toggle()
    if TrainerFrame:IsVisible() then
        HideUIPanel(TrainerFrame);
    else
        ShowUIPanel(TrainerFrame);
    end
end
