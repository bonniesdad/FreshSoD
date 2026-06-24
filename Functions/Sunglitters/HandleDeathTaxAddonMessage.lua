local ADDON_PREFIX = 'FreshSoD'

local function normalizePlayerName(playerName)
  if not playerName then
    return nil
  end

  return string.lower(Ambiguate(playerName, 'short'))
end

local function handleDeathTaxLeaderboardMessage(message, sender)
  local playerName, totalCopper = FreshSoD_ParseDeathTaxLeaderboardMessage(message)
  if not playerName or totalCopper == nil then
    return false
  end

  if not FreshSoD_IsPlayerInGuildRoster(sender) then
    return false
  end

  if normalizePlayerName(sender) ~= normalizePlayerName(playerName) then
    return false
  end

  FreshSoD_SetDeathTaxLeaderboardEntry(playerName, totalCopper)

  if FreshSoD_RefreshDeathTaxPanel then
    FreshSoD_RefreshDeathTaxPanel()
  end

  return true
end

local function handleDeathTaxAnnouncementMessage(message, sender)
  local playerName, taxCopper = FreshSoD_ParseDeathTaxAddonMessage(message)
  if not playerName or taxCopper == nil then
    return false
  end

  if not FreshSoD_IsPlayerInGuildRoster(sender) then
    return false
  end

  if normalizePlayerName(sender) ~= normalizePlayerName(playerName) then
    return false
  end

  local localPlayerName = UnitName('player')
  if localPlayerName and normalizePlayerName(sender) == normalizePlayerName(localPlayerName) then
    return false
  end

  FreshSoD_ShowDeathTaxAnnouncement(playerName, taxCopper)
  return true
end

local addonMessageFrame = CreateFrame('Frame')
addonMessageFrame:RegisterEvent('CHAT_MSG_ADDON')

addonMessageFrame:SetScript('OnEvent', function(_, event, ...)
  if event ~= 'CHAT_MSG_ADDON' then
    return
  end

  local prefix, message, channel, sender = ...
  if prefix ~= ADDON_PREFIX or channel ~= 'GUILD' or not sender then
    return
  end

  if not message:match('^DL:') and not message:match('^DT:') then
    return
  end

  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if message:match('^DL:') then
    handleDeathTaxLeaderboardMessage(message, sender)
    return
  end

  if message:match('^DT:') then
    handleDeathTaxAnnouncementMessage(message, sender)
  end
end)
