
function AuraButton_Refresh(self)
	local unit = GetUnit("player");
	if not unit then
		self:Hide();
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

	-- TODO: If aura has expired, remove it from the list
	if aura:IsExpired() then
		self:Hide();
		return;
	end

	-- We have an aura in the given slot, show the button
	self:Show();

	local spell = aura:GetSpell();
	if spell then
		self:SetProperty("Icon", spell.icon);
	end

	if aura:CanExpire() then
		self:SetText(string.format("%.0f min", aura:GetDuration() / 60000.0));
	else
		self:SetText("");
	end
end

function AuraButton_OnLoad(self)
	AuraButton_Refresh(self);
end

function AuraButton_OnUpdate(self, elapsed)
	AuraButton_Refresh(self);
end
