function FreshSoD_CancelMailWithMessage(inboxIndex, message)
    if not inboxIndex then return end
    
    if message then FreshSoD_PrintRestrictionMessage(message) end
    ReturnInboxItem(inboxIndex)
    DeleteInboxItem(inboxIndex)
end