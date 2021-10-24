
-- Variables
selectedRealm = nil			-- Selected realm name


function RealmListItem_Clicked(item)
	selectedRealm = item.userData
	RealmListButton01:Enable()
end

function RealmList_Show()
	RealmListFrame:Show()
	RealmListButton01:Disable()
	
	-- Clear realm list entries
	RealmList:RemoveAllChildren()
	
	-- Reset selected realm
	selectedRealm = nil
	
	-- Remember the last cloned realm list item as we need it as anchor 
	-- reference frame to align the list items beneath each other
	local lastRealmListItem = nil
	
	-- Load realm list data for iteration
	local realms = loginConnector:GetRealms()
	for realm in realms do
		-- Clone item
		local realmListItem = RealmListItem:Clone()
		RealmList:AddChild(realmListItem)
		
		-- Assign realm data
		realmListItem:SetText(realm.name)
		realmListItem.userData = realm
		
		-- Setup anchor points
		if (lastRealmListItem ~= nil) then
			realmListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, lastRealmListItem, 0.0)
		else
			realmListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0.0)
		end
		realmListItem:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0.0)
		realmListItem:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0.0)
		
		-- Register click handler
		realmListItem:SetClickedHandler(RealmListItem_Clicked)
		
		-- Add realm to realm list frame
		print("Realm: "..realm.id.." - "..realm.name)

		-- Remember realm list item
		lastRealmListItem = realmListItem
	end	
end

function RealmList_Hide()
	RealmListFrame:Hide()
end

function RealmList_OnLoad()
	-- Setup button handlers
	RealmListButton01:SetClickedHandler(RealmList_Accept)
	RealmListButton02:SetClickedHandler(RealmList_Cancel)
end

function RealmList_Accept()
	-- Hide realm list
	RealmList_Hide()
	
	-- Show message box
	GlueDialog_Show("CONNECTING_TO_REALM")

	-- Connect to the given realm
	realmConnector:ConnectToRealm(selectedRealm)
end

function RealmList_Cancel()
	-- Hide realm list frame
	RealmList_Hide()
	-- Show login ui again
	AccountLogin:Show()
	-- Reenable login button in login ui
	LoginButton:Enable()
end


-- Initialize realm list
RealmList_OnLoad()
