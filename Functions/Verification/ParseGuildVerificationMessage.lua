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

function FreshSoD_ParseGuildVerificationCommsMessage(message)
  if not message then
    return nil, nil
  end

  local status, guildName = message:match('^GV:(%d):(.+)$')
  if not guildName then
    return nil, nil
  end

  guildName = guildName:match('^%s*(.-)%s*$')
  if status == '1' then
    return true, guildName
  end
  if status == '0' then
    return false, guildName
  end

  return nil, nil
end
