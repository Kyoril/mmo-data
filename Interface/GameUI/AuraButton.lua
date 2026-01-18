
function AuraButton_RefreshWithAura(self, aura, hasDuration)
	if not aura then
		self:Hide();
		return;
	end

	-- If aura has expired, hide it
	if aura:IsExpired() then
		self:Hide();
		return;
	end

	-- Store the aura reference for future updates
	_G[self:GetName()].aura = aura;

	-- We have a valid aura, show the button
	self:Show();

	local spell = aura:GetSpell();
	if spell then
		self:SetProperty("Icon", spell.icon);
	end

	_G[self:GetName()].spell = spell;

	if aura:CanExpire() and hasDuration then
		local durationSeconds = aura:GetDuration() / 1000.0;
		if durationSeconds < 60 then
			self:SetText(string.format("%.0fs", durationSeconds));
		else
			local durationMinutes = durationSeconds / 60.0;
			if durationMinutes < 60 then
				self:SetText(string.format("%.0fm", durationMinutes));
			else
				local durationHours = durationMinutes / 60.0;
				self:SetText(string.format("%.0fh", durationHours));
			end
		end
	else
		self:SetText("");
	end
end

function AuraButton_Refresh(self, hasDuration)
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

	_G[self:GetName()].spell = spell;

	if aura:CanExpire() and hasDuration then
		local durationSeconds = aura:GetDuration() / 1000.0;
		if durationSeconds < 60 then
			self:SetText(string.format("%.0fs", durationSeconds));
		else
			local durationMinutes = durationSeconds / 60.0;
			if durationMinutes < 60 then
				self:SetText(string.format("%.0fm", durationMinutes));
			else
				local durationHours = durationMinutes / 60.0;
				self:SetText(string.format("%.0fh", durationHours));
			end
		end
	else
		self:SetText("");
	end
end

function AuraButton_OnLoad(self)
	-- Initial state - hide until AuraBar assigns an aura
	self:Hide();

	self:SetOnEnterHandler(AuraButton_OnEnter);
	self:SetOnLeaveHandler(AuraButton_OnLeave);
end

function AuraButton_OnUpdate(self, elapsed)
	-- Update the stored aura's duration if it exists
	local aura = _G[self:GetName()].aura;
	if aura then
		AuraButton_RefreshWithAura(self, aura, true);
	end
end

function AuraButton_OnEnter(self)
	local spell = _G[self:GetName()].spell;
	if not spell then
		print("No spell on aura button");
		return;
	end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, self, 0);

    GameTooltip_SetAura(spell);
    GameTooltip:Show();
end

function AuraButton_OnLeave(self)
	GameTooltip:Hide();
end
