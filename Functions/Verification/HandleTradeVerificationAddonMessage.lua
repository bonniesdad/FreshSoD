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

  local isVerified, senderGuild = FreshSoD_ParseTradeVerificationMessage(message)
  if isVerified == nil then
    return
  end

  if isVerified then
    FreshSoD_SetAllowedPartnerGuildMemberStatus(senderGuild, sender, true)
  end

  FreshSoD_OnTradeVerificationMessageReceived(sender, isVerified)
end)
