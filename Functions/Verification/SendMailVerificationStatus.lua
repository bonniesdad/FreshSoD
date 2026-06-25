local ADDON_PREFIX = 'FreshSoD'

local function buildAnswerMessage(isVerified)
  local message = isVerified and 'MV:A:1' or 'MV:A:0'
  local guildName = FreshSoD_GetPlayerGuildName()
  if guildName then
    message = message .. ':G:' .. guildName
  end

  return message
end

function FreshSoD_SendMailVerificationAnswer(playerName)
  if not playerName or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    return false
  end

  local iAmVerified = FreshSoD_AmIVerified()
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, buildAnswerMessage(iAmVerified), 'WHISPER', playerName)
  return true
end

function FreshSoD_SendMailVerificationQuery(playerName)
  if not playerName or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    return false
  end

  local message = 'MV:Q'
  local guildName = FreshSoD_GetPlayerGuildName()
  local iAmVerified = FreshSoD_AmIVerified()
  if iAmVerified then
    message = 'MV:Q:1'
    if guildName then
      message = message .. ':G:' .. guildName
    end
  else
    message = 'MV:Q:0'
    if guildName then
      message = message .. ':G:' .. guildName
    end
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'WHISPER', playerName)
  return true
end
