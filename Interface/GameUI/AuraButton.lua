
function AuraButton_OnLoad(self)
    local spell, duration = UnitAura("player", self.id);

	if ( spell == nil ) then
		self:Hide();
		return;
	else
		self:Show();
	end
end

function AuraButton_OnUpdate(self, elapsed)
    
end
