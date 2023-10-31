
function ChatFrame_OnLoad(this)
    this:RegisterEvent("CHAT_MSG_SAY", function(this, character, message)
        ChatFrame:AddMessage("[" .. string.format("%x", character) .. "] says: " .. message, 1.0, 1.0, 1.0)
    end)
    this:RegisterEvent("CHAT_MSG_YELL", function(this, character, message)
        ChatFrame:AddMessage("[" .. string.format("%x", character) .. "] yells: " .. message, 1.0, 0.0, 0.0)
    end)

    ChatFrame:AddMessage("Welcome to the game!", 1.0, 1.0, 0.0);
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
