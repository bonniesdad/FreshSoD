function FreshSoD_CanSendMailToRecipient(recipient)
  if not recipient or recipient == '' then
    return true
  end

  if not IsInGuild() then
    return false, 'Cannot send mail - you are not in a guild.'
  end

  local shortRecipient = Ambiguate(recipient, 'short')
  local playerShortName = Ambiguate(UnitName('player'), 'short')

  if shortRecipient == playerShortName then
    if FreshSoD_AmIVerified() then
      return true
    end
    return false, 'Cannot send mail - you are not verified.'
  end

  local localStatus = FreshSoD_GetLocalCharacterVerificationStatus(recipient)
  if localStatus == true then
    return true
  end

  if localStatus ~= nil then
    return false, 'Cannot send mail to ' .. shortRecipient .. ' - alt account has invalid status.'
  end

  if not FreshSoD_IsPlayerInGuildRoster(recipient) then
    return false, 'Cannot send mail to ' .. shortRecipient .. ' - not in my guild.'
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

  return false, 'Cannot send mail to ' .. shortRecipient .. ' - verification status unknown (ask them to relog to automatically send their verification status).'
end

function FreshSoD_CanAttemptMailVerification(recipient)
  if not recipient or recipient == '' then
    return false
  end

  if not FreshSoD_AmIEligibleForWhitelistedTrade() then
    return false
  end

  local shortRecipient = Ambiguate(recipient, 'short')
  local playerShortName = Ambiguate(UnitName('player'), 'short')
  if shortRecipient == playerShortName then
    return false
  end

  local localStatus = FreshSoD_GetLocalCharacterVerificationStatus(recipient)
  if localStatus == false then
    return false
  end
  if localStatus ~= nil and localStatus ~= true then
    return false
  end

  if FreshSoD_CanSendMailToRecipient(recipient) then
    return false
  end

  if FreshSoD_IsPlayerInGuildRoster(recipient) then
    local guildName = FreshSoD_GetPlayerGuildName()
    local status = FreshSoD_GetGuildMemberVerificationStatus(guildName, recipient)
    if status == nil then
      status = FreshSoD_GetLocalCharacterVerificationStatus(recipient, guildName)
    end
    if status == false then
      return false
    end
    if status == true then
      return false
    end
    return true
  end

  return true
end

function FreshSoD_CanSendMailToRecipientOrVerify(recipient)
  local allowed, reason = FreshSoD_CanSendMailToRecipient(recipient)
  if allowed then
    return true
  end

  if FreshSoD_CanAttemptMailVerification(recipient) then
    return true
  end

  return false, reason
end

function FreshSoD_CanReceiveMailFromSender(sender)
  if not sender or sender == '' then
    return true
  end

  if type(BonniesUtilities_IsMailVerificationValidSender) == 'function'
    and BonniesUtilities_IsMailVerificationValidSender(sender) then
    return true
  end

  return FreshSoD_CanSendMailToRecipient(sender)
end
