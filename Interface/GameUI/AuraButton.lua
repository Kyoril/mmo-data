
function AuraButton_OnLoad(self)
    local buffIndex = GetPlayerAura(self.id);
	self.buffIndex = buffIndex;

	if ( buffIndex < 0 ) then
		self:Hide();
		return;
	else
		self:Show();
	end
end

function AuraButton_OnUpdate(self, elapsed)
    
end
