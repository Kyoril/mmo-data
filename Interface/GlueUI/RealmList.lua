
-- Variables
selectedRealm = nil			-- Selected realm name


function RealmList_OnLoad()
	-- Setup button handlers
	RealmListButton01:SetClickedHandler(RealmList_Accept)
	RealmListButton02:SetClickedHandler(RealmList_Cancel)
end

function RealmList_Accept()
	-- Hide realm list
	RealmListFrame:Hide()
	
	-- Show connect dialog
	
	-- TODO: Connect to the selected realm
	
end

function RealmList_Cancel()
	-- Hide realm list frame
	RealmListFrame:Hide()
	
	-- Reenable login button in login ui
	LoginButton:Enable()
end


-- Initialize realm list
RealmList_OnLoad()
