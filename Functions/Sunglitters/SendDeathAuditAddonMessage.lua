local ADDON_PREFIX = 'FreshSoD'

local function sendWhisperAddonMessage(targetName, message)
  if not targetName or not message or not FreshSoD_IsDeathTaxGuild() then
    return
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'WHISPER', targetName)
end

function FreshSoD_SendDeathAuditStart(targetName, auditId, auditorName)
  sendWhisperAddonMessage(targetName, 'DA:START:' .. auditId .. ':' .. auditorName)
end

function FreshSoD_SendDeathAuditCancel(targetName, auditId)
  sendWhisperAddonMessage(targetName, 'DA:CANCEL:' .. auditId)
end

function FreshSoD_SendDeathAuditRequest(targetName, auditId)
  sendWhisperAddonMessage(targetName, 'DA:REQ:' .. auditId)
end

function FreshSoD_SendDeathAuditResponse(targetName, auditId, taxCopper)
  sendWhisperAddonMessage(targetName, 'DA:RES:' .. auditId .. ':' .. taxCopper)
end
