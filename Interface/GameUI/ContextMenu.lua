-- ContextMenu.lua
-- Generic context menu system for the MMO client

-- Configuration
CONTEXT_MENU_BUTTON_HEIGHT = 48
CONTEXT_MENU_BUTTON_PADDING = 4
CONTEXT_MENU_PADDING = 16
CONTEXT_MENU_MIN_WIDTH = 480

-- Registered context menu types
ContextMenus = {}

-- Current context menu state
local currentMenuType = nil
local currentMenuData = nil
local menuButtons = {}

-- Register a context menu definition
-- Each menu definition is a table with:
--   items = function(data) that returns array of { text, callback, enabled (optional), tooltip (optional) }
function RegisterContextMenu(menuType, definition)
    ContextMenus[menuType] = definition
end

-- Initialize the context menu frame
function ContextMenu_OnLoad(self)
    self.buttonContainer = ContextMenuButtonContainer
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        if currentMenuType == "TARGET" or currentMenuType == "PARTY_MEMBER" then ContextMenu_Hide(); end
    end)
end

-- Clear all existing menu buttons
local function ClearMenuButtons()
    for i, button in ipairs(menuButtons) do
        button:Hide()
    end
    menuButtons = {}
    ContextMenuButtonContainer:RemoveAllChildren()
end

-- Create a menu button
local function CreateMenuButton(index, text, callback, enabled)
    local button = ContextMenuButtonTemplate:Clone()
    button:SetText(text)
    
    if enabled == false then
        button:Disable()
    else
        button:Enable()
    end
    
    button:SetClickedHandler(function()
        if callback then
            callback(currentMenuData)
        end
        ContextMenu_Hide()
    end)
    
    ContextMenuButtonContainer:AddChild(button)
    
    -- Position the button
    local offsetY = (index - 1) * (CONTEXT_MENU_BUTTON_HEIGHT + CONTEXT_MENU_BUTTON_PADDING)
    button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, offsetY)
    button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0)
    button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0)
    
    button:Show()
    
    return button
end

-- Show context menu at specific position
-- menuType: string identifier for the menu type (e.g., "PLAYER_FRAME", "PARTY_MEMBER")
-- x, y: screen position to show the menu
-- data: optional data to pass to menu item callbacks
function ContextMenu_Show(menuType, x, y, data)
    local menuDef = ContextMenus[menuType]
    if not menuDef then
        print("ContextMenu: Unknown menu type: " .. tostring(menuType))
        return
    end
    
    -- Get menu items from the definition
    local items = menuDef.items
    if type(items) == "function" then
        items = items(data)
    end
    
    if not items or #items == 0 then
        return
    end
    
    -- Store current menu state
    currentMenuType = menuType
    currentMenuData = data
    
    -- Clear existing buttons
    ClearMenuButtons()
    
    -- Create buttons for each menu item
    for i, item in ipairs(items) do
        local button = CreateMenuButton(i, item.text, item.callback, item.enabled)
        table.insert(menuButtons, button)
    end
    
    -- Calculate menu size
    local menuHeight = (#items * (CONTEXT_MENU_BUTTON_HEIGHT + CONTEXT_MENU_BUTTON_PADDING)) - CONTEXT_MENU_BUTTON_PADDING + (CONTEXT_MENU_PADDING * 2)
    local menuWidth = CONTEXT_MENU_MIN_WIDTH + (CONTEXT_MENU_PADDING * 2)
    
    -- Set menu size
    ContextMenu:SetWidth(menuWidth)
    ContextMenu:SetHeight(menuHeight)
    
    -- Position the menu at the cursor
    ContextMenu:ClearAnchor(AnchorPoint.LEFT)
    ContextMenu:ClearAnchor(AnchorPoint.TOP)
    ContextMenu:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, x)
    ContextMenu:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, y)
    
    -- Show the backdrop first (to capture clicks outside)
    ContextMenuBackdrop:Show()
    
    -- Show the menu
    ContextMenu:Show()
end

-- Hide the context menu
function ContextMenu_Hide()
    ContextMenuBackdrop:Hide()
    ContextMenu:Hide()
    currentMenuType = nil
    currentMenuData = nil
    ClearMenuButtons()
end

-- Check if context menu is currently visible
function ContextMenu_IsShown()
    return ContextMenu:IsVisible()
end

-- Toggle context menu
function ContextMenu_Toggle(menuType, x, y, data)
    if ContextMenu_IsShown() and currentMenuType == menuType then
        ContextMenu_Hide()
    else
        ContextMenu_Show(menuType, x, y, data)
    end
end

--------------------------------------------------------------------------------
-- Loot rules entry, shared by the player and party member menus. Every party member can
-- open the loot rules window; only the leader can change them there.
--------------------------------------------------------------------------------

function LootMethodMenuItem()
    return {
        text = Localize(IsPartyLeader() and "SET_LOOT_METHOD" or "VIEW_LOOT_METHOD"),
        callback = function()
            LootMethodFrame_Toggle();
        end,
        enabled = true
    }
end

--------------------------------------------------------------------------------
-- Player Frame Context Menu
--------------------------------------------------------------------------------

RegisterContextMenu("PLAYER_FRAME", {
    items = function(data)
        local items = {}
        
        -- Only show "Leave Party" if player is in a party
        if GetPartySize() > 0 then
            table.insert(items, {
                text = Localize("LEAVE_PARTY"),
                callback = function()
                    LeaveParty()
                end,
                enabled = true
            })

            if IsPartyLeader() then
                table.insert(items, {
                    text = Localize("DISBAND_PARTY"),
                    callback = function()
                        DisbandParty()
                    end,
                    enabled = true
                })
            end

            table.insert(items, LootMethodMenuItem())
        end
        
        -- Resetting dungeon instances is the leader's call, so it is only offered to a leader
        -- or to a character which is in no group at all.
        if GetPartySize() == 0 or IsPartyLeader() then
            table.insert(items, {
                text = Localize("RESET_INSTANCES"),
                callback = function()
                    ResetInstances()
                end,
                enabled = true
            })
        end

        -- Add more player frame options here in the future
        -- For example: Set Focus, etc.
        
        return items
    end
})

--------------------------------------------------------------------------------
-- Party Member Context Menu (for future use)
--------------------------------------------------------------------------------

RegisterContextMenu("PARTY_MEMBER", {
    items = function(data)
        local items = {}
        local isLeader = IsPartyLeader()
        local memberIndex = data
        
        if memberIndex then
            table.insert(items, {
                text = Localize("LEAVE_PARTY"),
                callback = function()
                    LeaveParty()
                end,
                enabled = true
            })

            -- Kick from party (leader only)
            if isLeader then
                table.insert(items, {
                    text = Localize("KICK_FROM_PARTY"),
                    callback = function(menuData)
                        local unit = GetUnit("party" .. menuData)
                        if unit then
                            UninviteByName(unit:GetName())
                        end
                    end,
                    enabled = true
                })

                -- Promote to leader
                table.insert(items, {
                    text = Localize("PROMOTE_TO_LEADER"),
                    callback = function(menuData)
                        local unit = GetUnit("party" .. menuData)
                        if unit then
                            PromoteToLeader(unit:GetName())
                        end
                    end,
                    enabled = true
                })
            end

            table.insert(items, LootMethodMenuItem())
        end
        
        return items
    end
})


RegisterContextMenu("LOOT_METHOD", {
    items = function(data)
        return {
            {
                text = Localize("LOOT_FREE_FOR_ALL"),
                callback = function() SetLootMethod(0, ""); end,
                enabled = true
            },
            {
                text = Localize("LOOT_ROUND_ROBIN"),
                callback = function() SetLootMethod(1, ""); end,
                enabled = true
            },
            {
                text = Localize("LOOT_MASTER_LOOT"),
                callback = function() SetLootMethod(2, ""); end,
                enabled = true
            },
            {
                text = Localize("LOOT_GROUP_LOOT"),
                callback = function() SetLootMethod(3, ""); end,
                enabled = true
            },
        };
    end
})


--------------------------------------------------------------------------------
-- Master Loot: the loot master picks who receives an item. data = loot slot.
--------------------------------------------------------------------------------

RegisterContextMenu("MASTER_LOOT", {
    items = function(data)
        local slot = data
        local items = {}

        -- Candidate 0 is the loot master, 1..n the party members (see GiveMasterLoot). The server
        -- refuses anyone who was not near the kill and reports why.
        local player = GetUnit("player")
        if player then
            table.insert(items, {
                text = player:GetName(),
                callback = function() GiveMasterLoot(slot, 0); end,
                enabled = true
            })
        end

        for i = 1, GetPartySize() do
            local name = GetPartyMemberName(i)
            if name and name ~= "" then
                local candidate = i
                table.insert(items, {
                    text = name,
                    callback = function() GiveMasterLoot(slot, candidate); end,
                    enabled = true
                })
            end
        end

        return items
    end
})


RegisterContextMenu("TARGET", {
    items = function(data)
        local items = {}
        local targetUnit = GetUnit("target")
        local isPlayer = targetUnit and (targetUnit:GetType() == "PLAYER")
        local isSelf = isPlayer and (targetUnit == GetUnit("player"))
        
        if isPlayer and not isSelf and CanInteractWithPlayer("target") then
            local duelTargetGuid = targetUnit:GetGuid()
            local inspectUnit = "guid:" .. targetUnit:GetGuidString()
            table.insert(items, {
                text = Localize("INVITE_TO_PARTY"),
                callback = function()
                    InviteByName(targetUnit:GetName());
                end,
                enabled = true
            })
            -- Whisper option
            table.insert(items, {
                text = Localize("WHISPER"),
                callback = function()
                    ChatFrame_WhisperTarget = targetUnit:GetName();
                    ChatType = "WHISPER";
                    ChatEdit_UpdateHeader();
                    if not ChatInputFrame:IsVisible() then
                        ChatFrame_OpenChat();
                    end
                end,
                enabled = true
            })

            table.insert(items, {
                text = Localize("INSPECT"),
                callback = function() InspectWindow_Open(inspectUnit) end,
                enabled = true
            })

            table.insert(items, {
                text = Localize("DUEL"),
                callback = function() RequestDuel(duelTargetGuid) end,
                enabled = targetUnit:IsAlive() and GetUnit("player"):IsAlive()
            })
            
            -- Trade option
            table.insert(items, {
                text = Localize("TRADE"),
                callback = function()
                    local targetGuid = targetUnit:GetGuid();
                    if targetGuid then
                        InitiateTrade(targetGuid);
                    end
                end,
                enabled = true
            })
        end
        
        return items
    end
})
