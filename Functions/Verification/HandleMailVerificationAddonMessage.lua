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

  local queryVerified, queryGuildName = FreshSoD_ParseMailVerificationQueryMessage(message)
  if queryVerified ~= nil or message == 'MV:Q' then
    FreshSoD_OnMailVerificationQueryReceived(sender, queryVerified, queryGuildName)
    return
  end

  local answerVerified, answerGuildName = FreshSoD_ParseMailVerificationAnswerMessage(message)
  if answerVerified == nil then
    return
  end

  FreshSoD_OnMailVerificationAnswerReceived(sender, answerVerified, answerGuildName)
end)
