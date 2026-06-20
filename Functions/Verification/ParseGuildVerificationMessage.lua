function FreshSoD_ParseGuildVerificationMessage(message)
  if not message then
    return nil
  end

  local status = message:match('^GV:(%d)$')
  if status == '1' then
    return true
  end
  if status == '0' then
    return false
  end

  return nil
end

-- GVR:1 is just someone going "oi, tell me your status again" kept seperate from the GV: parser above so the two never step on each others toes.
function FreshSoD_ParseGuildVerificationRequest(message)
  if not message then
    return false
  end

  return message:match('^GVR:1$') ~= nil
end
