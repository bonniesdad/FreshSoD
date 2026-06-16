local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendTradeVerificationStatus(isVerified, playerName)
  if not playerName then
    return
  end

  local message = isVerified and 'TV:1' or 'TV:0'
  local guildName = FreshSoD_GetPlayerGuildName()
  if guildName then
    message = message .. ':G:' .. guildName
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'WHISPER', playerName)
end
