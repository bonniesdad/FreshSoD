local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendGuildStatusRequest(playerName)
  if not playerName or playerName == '' then
    return false
  end

  if Ambiguate(playerName, 'short') == Ambiguate(UnitName('player'), 'short') then
    return false
  end

  if not FreshSoD_IsPlayerInGuildRoster(playerName) then
    return false
  end

  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    return false
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, 'GS:1', 'WHISPER', playerName)
  return true
end
