-- Duel messages arrive only on the two participants' connections.
StaticDialogs["DUEL_REQUEST"] = {
    text = Localize("DUEL_INVITATION"),
    button1 = Localize("ACCEPT"),
    button2 = Localize("DECLINE"),
    OnAccept = function() AcceptDuel(); end,
    OnCancel = function() DeclineDuel(); end,
    timeout = 60,
    exclusive = true,
    whileDead = false
};

function DuelFrame_OnLoad(self)
    self:RegisterEvent("DUEL_UPDATE", function(_, state, detail, opponent)
        if state == DuelEvent.Invited then
            StaticDialog_Show("DUEL_REQUEST", opponent);
            StaticDialog:BringToFront();
        elseif state ~= DuelEvent.Pending and state ~= DuelEvent.Error then
            if StaticDialog.which == "DUEL_REQUEST" then StaticDialog:Hide(); end
        end

        local message = nil;
        if state == DuelEvent.Pending then
            message = string.format(Localize("DUEL_REQUEST_SENT"), opponent);
        elseif state == DuelEvent.Countdown then
            message = string.format(Localize("DUEL_COUNTDOWN"), detail);
        elseif state == DuelEvent.Active then
            message = Localize("DUEL_START");
        elseif state == DuelEvent.Finished then
            local resultKeys = { [DuelResult.Cancelled] = "DUEL_CANCELLED", [DuelResult.Won] = "DUEL_WON", [DuelResult.Lost] = "DUEL_LOST", [DuelResult.Declined] = "DUEL_DECLINED", [DuelResult.Expired] = "DUEL_EXPIRED" };
            message = string.format(Localize(resultKeys[detail] or "DUEL_CANCELLED"), opponent);
        elseif state == DuelEvent.Error then
            message = Localize("DUEL_UNAVAILABLE");
        end
        if message then
            ChatFrame:AddMessage(string.format(Localize("CHAT_FORMAT_DUEL"), message), 1.0, 0.8, 0.2);
        end
    end);
end
