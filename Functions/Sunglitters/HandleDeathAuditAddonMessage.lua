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

  local msgType, auditId, value = FreshSoD_ParseDeathAuditAddonMessage(message)
  if not msgType or not auditId then
    return
  end

  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if not FreshSoD_IsPlayerInGuildRoster(sender) then
    return
  end

  if msgType == 'START' then
    FreshSoD_HandleDeathAuditStart(auditId, value, sender)
  elseif msgType == 'CANCEL' then
    FreshSoD_HandleDeathAuditCancel(auditId)
  elseif msgType == 'REQ' then
    FreshSoD_HandleDeathAuditRequest(auditId, sender)
  elseif msgType == 'RES' then
    FreshSoD_HandleDeathAuditResponse(auditId, value, sender)
  end
end)
