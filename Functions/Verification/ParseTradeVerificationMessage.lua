function FreshSoD_ParseTradeVerificationMessage(message)
  if not message then
    return nil, nil
  end

  local status, guildName = message:match('^TV:(%d):G:(.+)$')
  if not guildName then
    status = message:match('^TV:(%d)$')
  else
    guildName = guildName:match('^%s*(.-)%s*$')
  end

  if status == '1' then
    return true, guildName
  end
  if status == '0' then
    return false, guildName
  end

  return nil, nil
end
