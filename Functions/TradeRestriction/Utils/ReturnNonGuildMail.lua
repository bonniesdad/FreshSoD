function FreshSoD_ReturnNonGuildMailAtIndex(inboxIndex, printMessage)
  if not inboxIndex then
    return
  end

  local message = printMessage ~= false and 'Returned mail from invalid sender.' or nil
  FreshSoD_CancelMailWithMessage(inboxIndex, message)
end

function FreshSoD_DeleteNonGuildMailAtIndex(inboxIndex)
  if not inboxIndex then
    return
  end

  DeleteInboxItem(inboxIndex)
  FreshSoD_PrintRestrictionMessage('Deleted mail from invalid sender.')
end

function FreshSoD_ReturnNonGuildMail()
  local indices = FreshSoD_GetNonGuildMailIndices()

  for _, inboxIndex in ipairs(indices) do
    FreshSoD_ReturnNonGuildMailAtIndex(inboxIndex, false)
  end

  if #indices > 0 then
    FreshSoD_PrintRestrictionMessage('Removed mail from non valid guild senders.')
  end
end
