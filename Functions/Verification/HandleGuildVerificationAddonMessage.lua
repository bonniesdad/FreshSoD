local ADDON_PREFIX = 'FreshSoD'

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
  local isVerified = FreshSoD_ParseGuildVerificationMessage(message)
  if isVerified == nil then
    
    return
  end


  if not FreshSoD_IsPlayerInGuildRoster(sender) then
    return
  end

  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    return
  end

  FreshSoD_SetGuildMemberVerificationStatus(guildName, sender, isVerified)

  if FreshSoD_OnGuildMemberVerificationUpdated then
    FreshSoD_OnGuildMemberVerificationUpdated(sender, isVerified)
  end
end)
