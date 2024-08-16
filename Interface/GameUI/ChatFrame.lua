
function ChatFrame_OnLoad(this)
    this:RegisterEvent("CHAT_MSG_SAY", function(this, character, message)
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_SAY, character, message), 1.0, 1.0, 1.0);
    end)
    this:RegisterEvent("CHAT_MSG_YELL", function(this, character, message)
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_YELL, character, message), 1.0, 0.0, 0.0);
    end)

    ChatFrame:AddMessage("Welcome to the game!", 1.0, 1.0, 0.0);
end

function ChatFrame_OpenChat(input)
    if (input) then
        ChatInput:SetText(input);
    end

    ChatInput:Show();
    ChatInput:CaptureInput();
end

function ChatFrame_SendMessage(this)
    ChatInput:Hide();

    if (string.len(ChatInput:GetText()) > 0) then
        RunConsoleCommand("sendchatmessage " .. ChatInput:GetText());
        ChatInput:SetText("");
    end

    ChatInput:ReleaseInput();
end

function ChatFrame_ScrollDown(this)
    ChatFrame:ScrollDown();
end

function ChatFrame_ScrollUp(this)
    ChatFrame:ScrollUp()
end

function ChatFrame_ScrollToBottom(this)
    ChatFrame:ScrollToBottom()
end
