local function parseStatusMessage(prefix, message)
  if not message then
    return nil
  end

  local status, guildName = message:match('^' .. prefix .. ':(%d):G:(.+)$')
  if not status then
    status = message:match('^' .. prefix .. ':(%d)$')
    guildName = nil
  end

  if status == '1' then
    return true, guildName
  end
  if status == '0' then
    return false, guildName
  end

  return nil
end

function FreshSoD_ParseMailVerificationQueryMessage(message)
  if message == 'MV:Q' then
    return nil, nil
  end

  return parseStatusMessage('MV:Q', message)
end

function FreshSoD_ParseMailVerificationAnswerMessage(message)
  return parseStatusMessage('MV:A', message)
end
