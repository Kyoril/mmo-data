
function ChatFrame_OnLoad(this)
    this:RegisterEvent("CHAT_MSG_SAY", function(this, character, message)
        ChatFrame:AddMessage("[" .. string.format("%x", character) .. "] says: " .. message, 1.0, 1.0, 1.0)
    end)
    this:RegisterEvent("CHAT_MSG_YELL", function(this, character, message)
        ChatFrame:AddMessage("[" .. string.format("%x", character) .. "] yells: " .. message, 1.0, 0.0, 0.0)
    end)
end
