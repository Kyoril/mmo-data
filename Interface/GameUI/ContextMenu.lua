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
        end
        
        return items
    end
})
