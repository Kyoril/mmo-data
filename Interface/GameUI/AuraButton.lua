
function AuraButton_Refresh(self)
	local unit = GetUnit("player");
	if not unit then
		return;
	end

	local auraCount = unit:GetAuraCount();
	if self.id > auraCount then
		self:Hide();
		return;
	end

	local aura = unit:GetAura(self.id - 1);
	if not aura then
		self:Hide();
		return;
	end

	self:Show();

	local spell = aura:GetSpell();
	if spell then
		self:SetProperty("Icon", spell.icon);
	end
end

function AuraButton_OnLoad(self)
	AuraButton_Refresh(self);
end

function AuraButton_OnUpdate(self, elapsed)
end
