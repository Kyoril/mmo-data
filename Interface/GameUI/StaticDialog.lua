
StaticDialogs = {}

StaticDialogs["DEATH"] = {
	text = "YOU_DIED",
	button1 = "DEATH_RELEASE",
	button2 = nil,
	OnAccept = function()
		ReviveMe();
	end,
	OnCancel = function()
	end
}

function StaticDialog_OnLoad(self)

end

function StaticDialog_Show(which, text, data)
	-- Hide the previous dialog using the cancel button
	if (StaticDialog:IsVisible()) then
		StaticDialogs[StaticDialog.which].OnCancel()
	end
	
	-- Setup the dialog text
	if (text ~= nil) then
		StaticDialogLabel:SetText(Localize(text))
	else
		StaticDialogLabel:SetText(Localize(StaticDialogs[which].text))
	end

	-- Check if there is a second button requested
	if (StaticDialogs[which].button2) then
		-- TODO
	else
		-- TODO
	end
	
	-- Change button text
	StaticDialogButton01:SetText(Localize(StaticDialogs[which].button1))

	-- Save parameters
	StaticDialog.which = which
	StaticDialog.data = data
	
	-- Load text height
	local textHeight = StaticDialogLabel:GetTextHeight();
	StaticDialog:SetHeight(StaticDialogButton01:GetHeight() + textHeight + 136);

	-- Show the glue dialog
	StaticDialog:Show();
end

function StaticDialog_Hide()
	StaticDialog_Button2Clicked()
end

function StaticDialog_Button1Clicked()
	StaticDialog:Hide()
	
	if (StaticDialogs[StaticDialog.which].OnAccept) then
		StaticDialogs[StaticDialog.which].OnAccept()
	end
end

function StaticDialog_Button2Clicked()
	StaticDialog:Hide()
	
	if (StaticDialogs[GlueDialog.which].OnCancel) then
		StaticDialogs[GlueDialog.which].OnCancel()
	end
end
