local ADDON_PREFIX = 'FreshSoD'

local function getWhisperTargetName(playerName)
  if not playerName or not IsInGuild() then
    return nil
  end

  local targetShortName = Ambiguate(playerName, 'short')
  local numMembers = GetNumGuildMembers()

  for index = 1, numMembers do
    local rosterName = GetGuildRosterInfo(index)
    if rosterName and Ambiguate(rosterName, 'short') == targetShortName then
      return rosterName
    end
  end

  return playerName
end

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

  local whisperTarget = getWhisperTargetName(playerName)
  if not whisperTarget then
    return false
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, 'GS:1', 'WHISPER', whisperTarget)
  return true
end
