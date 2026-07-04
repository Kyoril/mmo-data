MAIL_LIST_MAX_DISPLAY = 8;
MAIL_LIST_ROW_HEIGHT = 72;

local mailListOffset = 0;
local selectedMailIndex = -1;
local mailRowButtons = {};
local sendAttachSlot = -1;

function MailFrame_IsSendPanelVisible()
    return MailFrame:IsVisible() and MailSendPanel:IsVisible();
end

function MailFrame_SetDetailVisible(visible)
    if (visible) then
        MailNoSelectionLabel:Hide();
        MailDetailFromLabel:Show();
        MailDetailFromText:Show();
        MailDetailSubjectLabel:Show();
        MailDetailSubjectText:Show();
        MailDetailMessageLabel:Show();
        MailBodyText:Show();
    else
        MailNoSelectionLabel:Show();
        MailDetailFromLabel:Hide();
        MailDetailFromText:Hide();
        MailDetailSubjectLabel:Hide();
        MailDetailSubjectText:Hide();
        MailDetailMessageLabel:Hide();
        MailBodyText:Hide();
    end
end

function MailFrame_UpdateTabs(sendVisible)
    MailInboxTabButton:SetChecked(not sendVisible);
    MailSendTabButton:SetChecked(sendVisible);
end

function MailFrame_ShowMailList()
    MailDetailFrame:Hide();
    MailInboxActions:Hide();
    MailListFrame:Show();
    MailFrame_UpdateList();
end

function MailFrame_ShowMailRead(mailIndex)
    if (mailIndex ~= nil) then
        selectedMailIndex = mailIndex;
    end

    if (selectedMailIndex < 0 or selectedMailIndex >= GetNumMails()) then
        selectedMailIndex = -1;
        MailFrame_ShowMailList();
        return;
    end

    MarkMailRead(selectedMailIndex);
    MailListFrame:Hide();
    MailDetailFrame:Show();
    MailInboxActions:Show();
    MailFrame_UpdateList();
    MailFrame_UpdateDetail();
end

function MailFrame_UpdateList()
    local numMails = GetNumMails();

    local maxScroll = math.max(0, numMails - MAIL_LIST_MAX_DISPLAY);
    MailListScrollBar:SetMaximum(maxScroll);
    if (mailListOffset > maxScroll) then
        mailListOffset = maxScroll;
        MailListScrollBar:SetValue(mailListOffset);
    end

    if (maxScroll > 0) then
        MailListScrollBar:Enable();
    else
        MailListScrollBar:Disable();
    end

    if (selectedMailIndex >= numMails) then
        selectedMailIndex = -1;
    end

    if (numMails > 0) then
        MailEmptyInboxLabel:Hide();
    else
        MailEmptyInboxLabel:Show();
    end

    for i = 1, MAIL_LIST_MAX_DISPLAY do
        local button = mailRowButtons[i];
        local index = mailListOffset + i - 1;
        if (index < numMails) then
            local mail = GetMailInfo(index);
            if (mail) then
                local unreadMarker = "";
                local senderColor = "FFD0D0D0";
                local subjectColor = "FFAAAAAA";
                if (not mail.read) then
                    unreadMarker = "!";
                    senderColor = "FFFFD100";
                    subjectColor = "FFFFFFFF";
                end

                button:GetChild(0):SetText(unreadMarker);
                button:GetChild(1):SetText(mail.senderName);
                button:GetChild(1):SetProperty("TextColor", senderColor);
                button:GetChild(2):SetText(mail.subject);
                button:GetChild(2):SetProperty("TextColor", subjectColor);
                button.id = i;
                button:SetChecked(index == selectedMailIndex);
                button:Show();
            else
                button:Hide();
            end
        else
            button.id = i;
            button:SetChecked(false);
            button:Hide();
        end
    end

    MailFrame_UpdateDetail();
end

function MailFrame_UpdateDetail()
    local mail = nil;
    if (selectedMailIndex >= 0 and selectedMailIndex < GetNumMails()) then
        mail = GetMailInfo(selectedMailIndex);
    end

    if (not mail) then
        MailFrame_SetDetailVisible(false);
        MailDetailFromText:SetText("");
        MailDetailSubjectText:SetText("");
        MailBodyText:SetText("");
        MailTakeMoneyButton:Hide();
        MailTakeItemButton:Hide();
        MailDeleteButton:Hide();
        if (MailDetailFrame:IsVisible()) then
            MailFrame_ShowMailList();
        end
        return;
    end

    MailFrame_SetDetailVisible(true);
    MailDetailFromText:SetText(mail.senderName);
    MailDetailSubjectText:SetText(mail.subject);
    MailBodyText:SetText(mail.body);
    MailDeleteButton:Show();

    if (mail.money > 0) then
        MailTakeMoneyButton:Show();
    else
        MailTakeMoneyButton:Hide();
    end

    local numAttachments = GetMailNumAttachments(selectedMailIndex);
    if (numAttachments > 0) then
        local item = GetMailAttachmentItem(selectedMailIndex, 0);
        if (item) then
            MailTakeItemButton:SetProperty("Icon", item:GetIcon());
        else
            MailTakeItemButton:SetProperty("Icon", "");
        end

        local count = GetMailAttachmentCount(selectedMailIndex, 0);
        if (count > 1) then
            MailTakeItemButton:SetText(tostring(count));
        else
            MailTakeItemButton:SetText("");
        end

        MailTakeItemButton:Show();
    else
        MailTakeItemButton:Hide();
    end
end

function MailFrame_OnRowClicked(this)
    local mailIndex = mailListOffset + this.id - 1;
    if (mailIndex >= 0 and mailIndex < GetNumMails()) then
        MailFrame_ShowMailRead(mailIndex);
    end
end

function MailFrame_TakeMoneyClicked()
    if (selectedMailIndex >= 0) then
        TakeMailMoney(selectedMailIndex);
    end
end

function MailFrame_TakeItemClicked()
    if (selectedMailIndex >= 0) then
        TakeMailItem(selectedMailIndex, 0);
    end
end

function MailFrame_DeleteClicked()
    if (selectedMailIndex >= 0) then
        DeleteMail(selectedMailIndex);
        selectedMailIndex = -1;
        MailFrame_ShowMailList();
    end
end

function MailFrame_ShowInbox()
    MailSendPanel:Hide();
    MailInboxPanel:Show();
    MailFrame_UpdateTabs(false);
    MailFrame_ShowMailList();
end

function MailFrame_ShowSend()
    MailInboxPanel:Hide();
    MailSendPanel:Show();
    MailFrame_UpdateTabs(true);
end

-- Called from the inventory button right click handler while the send panel is open
function MailFrame_AttachItem(slotId)
    sendAttachSlot = slotId;

    local item = GetInventorySlotItem("player", slotId);
    if (item) then
        MailSendAttachButton:SetProperty("Icon", item:GetIcon());
    end
end

function MailFrame_ClearAttachment()
    sendAttachSlot = -1;
    MailSendAttachButton:SetProperty("Icon", "");
    MailSendAttachButton:SetText("");
end

function MailFrame_SendClicked()
    local recipient = MailSendToField:GetText();
    if (recipient == nil or recipient == "") then
        return;
    end

    local money = tonumber(MailSendMoneyField:GetText()) or 0;
    SendMail(recipient, MailSendSubjectField:GetText(), MailSendBodyField:GetText(), money, sendAttachSlot);
end

function MailFrame_OnMailSent()
    MailSendToField:SetText("");
    MailSendSubjectField:SetText("");
    MailSendBodyField:SetText("");
    MailSendMoneyField:SetText("0");
    MailFrame_ClearAttachment();

    RequestMailList();
    MailFrame_ShowInbox();
end

function MailFrame_OnMailboxShow(this)
    selectedMailIndex = -1;
    mailListOffset = 0;
    MailListScrollBar:SetValue(0);
    MailFrame_ClearAttachment();
    MailFrame_ShowInbox();
    MailFrame_UpdateList();

    ShowUIPanel(MailFrame);
    OpenInventory();
end

function MailFrame_OnMailboxClosed(this)
    HideUIPanel(MailFrame);
end

function MailFrame_OnListUpdated(this)
    if (MailFrame:IsVisible()) then
        MailFrame_UpdateList();
    end
end

function MailFrame_OnMailNotify(this)
    if (GetUnreadMailCount() > 0) then
        print(Localize("MAIL_NEW_MAIL"));
    end
end

function MailFrame_Load(this)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(this);

    this:GetChild(0):SetText(Localize("MAIL"));

    -- Create the fixed inbox row buttons once (virtual scrolling)
    for i = 1, MAIL_LIST_MAX_DISPLAY do
        local row = MailListRowTemplate:Clone();
        row.id = i;
        MailListContent:AddChild(row);
        row:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, MailListContent, 0);
        row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, MailListContent, 0);
        row:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, MailListContent, (i - 1) * MAIL_LIST_ROW_HEIGHT);
        row:SetClickedHandler(MailFrame_OnRowClicked);
        row:Hide();
        mailRowButtons[i] = row;
    end

    MailListScrollBar:SetMinimum(0);
    MailListScrollBar:SetMaximum(0);
    MailListScrollBar:SetValue(0);
    MailListScrollBar:SetStep(1);
    MailListScrollBar:SetOnValueChangedHandler(function(self, value)
        mailListOffset = math.floor(value + 0.5);
        MailFrame_UpdateList();
    end);

    MailTakeItemButton:SetClickedHandler(MailFrame_TakeItemClicked);
    MailSendAttachButton:SetClickedHandler(MailFrame_ClearAttachment);

    this:RegisterEvent("MAILBOX_SHOW", MailFrame_OnMailboxShow);
    this:RegisterEvent("MAILBOX_CLOSED", MailFrame_OnMailboxClosed);
    this:RegisterEvent("MAIL_LIST_UPDATED", MailFrame_OnListUpdated);
    this:RegisterEvent("MAIL_SENT", MailFrame_OnMailSent);
    this:RegisterEvent("MAIL_NOTIFY", MailFrame_OnMailNotify);
end
