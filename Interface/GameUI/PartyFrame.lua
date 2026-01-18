
PARTY_COMMAND_RESULTS = {};
PARTY_COMMAND_RESULTS[1] = "CANT_INVITE_YOURSELF";
PARTY_COMMAND_RESULTS[2] = "CANT_FIND_TARGET";
PARTY_COMMAND_RESULTS[3] = "NOT_IN_YOUR_PARTY";
PARTY_COMMAND_RESULTS[4] = "NOT_IN_YOUR_INSTANCE";
PARTY_COMMAND_RESULTS[5] = "PARTY_FULL";
PARTY_COMMAND_RESULTS[6] = "ALREADY_IN_GROUP";
PARTY_COMMAND_RESULTS[7] = "YOU_NOT_IN_GROUP";
PARTY_COMMAND_RESULTS[8] = "YOU_NOT_LEADER";
PARTY_COMMAND_RESULTS[9] = "TARGET_UNFRIENDLY";
PARTY_COMMAND_RESULTS[10] = "TARGET_IGNORE_YOU";

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

function PartyMemberFrame_UpdateLeader(self)
    local leaderIndex = GetPartyLeaderIndex();
    local name = self:GetChild(0);

    if (leaderIndex and leaderIndex == self.id) then
        name:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 32);
        self:GetChild(3):Show();
    else
        name:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
        self:GetChild(3):Hide();
    end
end

function PartyMemberFrame_OnClick(self, button, x, y)
    local index = self:GetParent().id;
    local unit = "party"..index;

    if (button == "LEFT") then
        TargetUnit(unit);
    elseif (button == "RIGHT") then
        local pos = GetCursorPosition();
        ContextMenu_Show("PARTY_MEMBER", pos.x, pos.y, index);
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
    PartyMemberFrame_UpdateLeader(self);
end

function PartyMemberFrame_OnLeaderChanged(self)
    PartyMemberFrame_UpdateLeader(self);
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
    
    self:GetChild(4):SetClickedHandler(PartyMemberFrame_OnClick);

    PartyMemberFrame_UpdateMember(self);
    PartyMemberFrame_UpdateLeader(self);
end

function PartyFrame_OnDisbanded(self)
    ChatFrame:AddMessage(Localize("GROUP_DISBANDED"), 1.0, 1.0, 0.0);
end

function PartyFrame_OnMemberJoined(self, memberName)
    ChatFrame:AddMessage(string.format(Localize("PARTY_MEMBER_JOINED"), memberName), 1.0, 1.0, 0.0);
end

function PartyFrame_OnMemberLeft(self, memberName)
    ChatFrame:AddMessage(string.format(Localize("PARTY_MEMBER_LEFT"), memberName), 1.0, 1.0, 0.0);
end

function PartyFrame_OnInviteDeclined(self, memberName)
    ChatFrame:AddMessage(string.format(Localize("PARTY_INVITE_DECLINED"), memberName), 1.0, 1.0, 0.0);
end

function PartyFrame_OnCommandResult(self, result, memberName)
    local message = string.format(Localize(PARTY_COMMAND_RESULTS[result]), memberName);
    if (message) then
        ChatFrame:AddMessage(string.format(message, memberName), 1.0, 1.0, 0.0);
    end  
end

function PartyFrame_OnInviteSent(self, memberName)
    ChatFrame:AddMessage(string.format(Localize("PARTY_INVITE_SENT"), memberName), 1.0, 1.0, 0.0);
end

function PartyFrame_OnLeft(self)
    ChatFrame:AddMessage(Localize("PARTY_LEFT"), 1.0, 1.0, 0.0);
end

function PartyFrame_OnMembersChanged(self)
    local partySize = GetPartySize();
    if (not partySize or partySize == 0) then
        self:Hide();
        return;
    end

    self:SetHeight(20 + partySize * 128);
    self:Show();
end

function PartyFrame_OnLoad(self)
    self:RegisterEvent("PARTY_DISBANDED", PartyFrame_OnDisbanded);
    self:RegisterEvent("PARTY_MEMBER_JOINED", PartyFrame_OnMemberJoined);
    self:RegisterEvent("PARTY_MEMBER_LEFT", PartyFrame_OnMemberLeft);
    self:RegisterEvent("PARTY_INVITE_DECLINED", PartyFrame_OnInviteDeclined);
    self:RegisterEvent("PARTY_COMMAND_RESULT", PartyFrame_OnCommandResult);
    self:RegisterEvent("PARTY_INVITE_SENT", PartyFrame_OnInviteSent);
    self:RegisterEvent("PARTY_LEFT", PartyFrame_OnLeft);
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", PartyFrame_OnMembersChanged);
end
