
function AuraBar_OnLoad(self)
    self:RegisterEvent("PLAYER_AURA_UPDATE", AuraBar_OnUpdate);
end

function AuraBar_OnUpdate(self)
    for i = 1, 8 do
        local button = _G["AuraButton"..i];
        if button then
            AuraButton_Refresh(button);
        end
    end
end
