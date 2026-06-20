function FreshSoD_ReturnNonGuildMail()
  local indices = FreshSoD_GetNonGuildMailIndices()

  for _, inboxIndex in ipairs(indices) do
    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(inboxIndex)
    if (hasItem and hasItem > 0) or (CODAmount and CODAmount > 0) or (money and money > 0) then
      ReturnInboxItem(inboxIndex)
    end
  end

  if #indices > 0 then
    FreshSoD_PrintRestrictionMessage('Returned mail from non-guild senders to the sender.')
  end

  if FreshSoD_InvalidateNonGuildMailCache then
    FreshSoD_InvalidateNonGuildMailCache()
  end
end
