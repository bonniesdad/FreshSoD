function FreshSoD_CanSendMailToRecipient(recipient)
  if not recipient or recipient == '' then
    return true
  end

  if not IsInGuild() then
    return false, 'Cannot send mail - you are not in a guild.'
  end

  local shortRecipient = Ambiguate(recipient, 'short')
  local playerShortName = Ambiguate(UnitName('player'), 'short')

  if string.lower(shortRecipient) == string.lower(playerShortName) then
    if FreshSoD_AmIVerified() then
      return true
    end
    return false, 'Cannot send mail - you are not verified.'
  end

  if not FreshSoD_IsPlayerInGuildRoster(recipient) then
    return false, 'Cannot send mail to ' .. shortRecipient .. ' - not in guild.'
  end

  local guildName = FreshSoD_GetPlayerGuildName()
  local status = FreshSoD_GetGuildMemberVerificationStatus(guildName, recipient)

  if status == nil then
    status = FreshSoD_GetLocalCharacterVerificationStatus(recipient, guildName)
  end

  if status == true then
    return true
  end

  if status == false then
    return false, 'Cannot send mail to ' .. shortRecipient .. ' - not verified.'
  end

  return false, 'Cannot send mail to ' .. shortRecipient .. ' - verification status unknown.'
end
