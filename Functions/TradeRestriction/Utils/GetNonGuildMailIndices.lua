local cachedIndices = nil

local function computeNonGuildMailIndices()
  FreshSoD_RefreshGuildRoster()

  local indices = {}
  local numItems = GetInboxNumItems()

  for inboxIndex = numItems, 1, -1 do
    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(inboxIndex)
    if sender and not isGM and not wasReturned and not FreshSoD_IsPlayerInGuildRoster(sender) and ((money and money > 0) or (CODAmount and CODAmount > 0) or (hasItem and hasItem > 0)) then
      indices[#indices + 1] = inboxIndex
    end
  end

  return indices
end

function FreshSoD_GetNonGuildMailIndices()
  if not cachedIndices then
    cachedIndices = computeNonGuildMailIndices()
  end

  return cachedIndices
end

function FreshSoD_InvalidateNonGuildMailCache()
  cachedIndices = nil
end

function FreshSoD_HasNonGuildMail()
  return #FreshSoD_GetNonGuildMailIndices() > 0
end

local mailScanCacheFrame = CreateFrame('Frame')
mailScanCacheFrame:RegisterEvent('MAIL_SHOW')
mailScanCacheFrame:RegisterEvent('MAIL_INBOX_UPDATE')
mailScanCacheFrame:RegisterEvent('MAIL_CLOSED')
mailScanCacheFrame:RegisterEvent('GUILD_ROSTER_UPDATE')
mailScanCacheFrame:SetScript('OnEvent', function()
  cachedIndices = nil
end)
