
-- Variables
selectedRealm = nil			-- Selected realm name


function RealmList_Show()
	RealmListFrame:Show()
	RealmListButton01:Disable()
	
	-- Clear realm list entries
	RealmList:RemoveAllChildren()
	
	-- Load realm data
	local realms = loginConnector:GetRealms()
	for realm in realms do
		print("Realm: "..realm.id.." - "..realm.name)
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
	
	-- Show connect dialog
	
	-- TODO: Connect to the selected realm
	
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
