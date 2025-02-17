
function PartyMemberFrame_UpdateMember(self)
    if (HasPartyMember(self.id)) then
        local unitName = "party"..self.id;
        local name = self:GetChild(0);
        local healthbar = self:GetChild(1);
        local manabar = self:GetChild(2);
        local unit = GetUnit(unitName);
        if (unit) then
            name:SetText(unit:GetName());
            healthbar:SetProgress(unit:GetHealth() / unit:GetMaxHealth());

            -- Get power type
            local powerType = unit:GetPowerType();
            manabar:SetProperty("ProgressColor", ResourceBarColors[powerType]);
    
            local power = unit:GetPower(powerType);
            local maxPower = unit:GetMaxPower(powerType);
            manabar:SetProgress(power / maxPower);
        end

        self:Show();
    else
        self:Hide();
    end    
end

function PartyMemberFrame_OnClick(self, button)
    local index = self:GetParent().id;
    local unit = "party"..index;

    if (button == "LEFT") then
        TargetUnit(unit);
    elseif (button == "RIGHT") then
        -- TODO: Show party member context menu here!
        print("TODO: Implement other button");
    end
end

function PartyMemberFrame_OnUnitUpdate(self, unit)
    if (unit ~= "party"..self.id) then
        return;
    end

    PartyMemberFrame_UpdateMember(self);
end

function PartyMemberFrame_OnUnitNameUpdate(self, unit)
    -- Is this our unit?
    if (unit ~= "party"..self.id) then
        return;
    end

    -- Adjust unit name display
    local partyMemberUnit = GetUnit(unit);
    if (partyMemberUnit) then
        local name = self:GetChild(0);
        name:SetText(partyMemberUnit:GetName());
    end
end

function PartyMemberFrame_OnMembersChanged(self)
    PartyMemberFrame_UpdateMember(self);
end

function PartyMemberFrame_OnLeaderChanged(self)

end

function PartyMemberFrame_OnMemberEnable(self)

end

function PartyMemberFrame_OnMemberDisable(self)

end

function PartyMemberFrame_OnLootMethodChanged(self)

end

function PartyMemberFrame_OnLoad(self)
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", PartyMemberFrame_OnMembersChanged);
	self:RegisterEvent("PARTY_LEADER_CHANGED", PartyMemberFrame_OnLeaderChanged);
	self:RegisterEvent("PARTY_MEMBER_ENABLE", PartyMemberFrame_OnMemberEnable);
	self:RegisterEvent("PARTY_MEMBER_DISABLE", PartyMemberFrame_OnMemberDisable);
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", PartyMemberFrame_OnLootMethodChanged);
    self:RegisterEvent("UNIT_NAME_UPDATE", PartyMemberFrame_OnUnitNameUpdate);
    self:RegisterEvent("UNIT_HEALTH_UPDATED", PartyMemberFrame_OnUnitUpdate);
    self:RegisterEvent("UNIT_POWER_UPDATED", PartyMemberFrame_OnUnitUpdate);
    self:RegisterEvent("UNIT_LEVEL_UPDATED", PartyMemberFrame_OnUnitUpdate);
    
    self:GetChild(3):SetClickedHandler(PartyMemberFrame_OnClick);

    PartyMemberFrame_UpdateMember(self);
end

function PartyFrame_OnLoad(self)

end
