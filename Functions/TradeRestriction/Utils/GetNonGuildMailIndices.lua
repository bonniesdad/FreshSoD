function FreshSoD_GetNonGuildMailIndices()
  FreshSoD_RefreshGuildRoster()

  local indices = {}
  local numItems = GetInboxNumItems()

  for inboxIndex = numItems, 1, -1 do
    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(inboxIndex)
    local hasValue = (money and money > 0) or (CODAmount and CODAmount > 0) or (hasItem and hasItem > 0)
    if canReply and sender and not isGM and not wasReturned and hasValue and not FreshSoD_CanReceiveMailFromSender(sender) then
      indices[#indices + 1] = inboxIndex
    end
  end

  return indices
end

function FreshSoD_HasNonGuildMail()
  return #FreshSoD_GetNonGuildMailIndices() > 0
end
