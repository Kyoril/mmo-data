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
        if state == 1 then
            StaticDialog_Show("DUEL_REQUEST", opponent);
            StaticDialog:BringToFront();
        elseif state ~= 0 and state ~= 5 then
            if StaticDialog.which == "DUEL_REQUEST" then StaticDialog:Hide(); end
        end

        local message = nil;
        if state == 0 then
            message = string.format(Localize("DUEL_REQUEST_SENT"), opponent);
        elseif state == 2 then
            message = string.format(Localize("DUEL_COUNTDOWN"), detail);
        elseif state == 3 then
            message = Localize("DUEL_START");
        elseif state == 4 then
            local resultKeys = { [0] = "DUEL_CANCELLED", [1] = "DUEL_WON", [2] = "DUEL_LOST", [3] = "DUEL_DECLINED", [4] = "DUEL_EXPIRED" };
            message = string.format(Localize(resultKeys[detail] or "DUEL_CANCELLED"), opponent);
        elseif state == 5 then
            message = Localize("DUEL_UNAVAILABLE");
        end
        if message then
            ChatFrame:AddMessage(string.format(Localize("CHAT_FORMAT_DUEL"), message), 1.0, 0.8, 0.2);
        end
    end);
end
