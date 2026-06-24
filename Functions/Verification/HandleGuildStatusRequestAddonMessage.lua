local ADDON_PREFIX = 'FreshSoD'

local addonMessageFrame = CreateFrame('Frame')
addonMessageFrame:RegisterEvent('CHAT_MSG_ADDON')

addonMessageFrame:SetScript('OnEvent', function(_, event, ...)
  if event ~= 'CHAT_MSG_ADDON' then
    return
  end

  local prefix, message, channel, sender = ...
  if prefix ~= ADDON_PREFIX or channel ~= 'WHISPER' or not sender then
    return
  end

  if not FreshSoD_ParseGuildStatusRequestMessage(message) then
    return
  end

  if not IsInGuild() or not FreshSoD_IsPlayerInGuildRoster(sender) then
    return
  end

  if FreshSoD_BroadcastGuildVerificationStatusIfChanged then
    FreshSoD_BroadcastGuildVerificationStatusIfChanged(true)
  end
end)
