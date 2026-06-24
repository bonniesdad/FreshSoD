function FreshSoD_ParseDeathAuditAddonMessage(message)
  if not message then
    return nil
  end

  local msgType, auditId, value = message:match('^DA:(%w+):([^:]+):?(.*)$')
  if not msgType or not auditId or auditId == '' then
    return nil
  end

  if msgType == 'RES' then
    local copper = tonumber(value)
    if copper == nil then
      return nil
    end
    return msgType, auditId, copper
  end

  if msgType == 'START' then
    if not value or value == '' then
      return nil
    end
    return msgType, auditId, value
  end

  if msgType == 'CANCEL' or msgType == 'REQ' then
    return msgType, auditId, nil
  end

  return nil
end
