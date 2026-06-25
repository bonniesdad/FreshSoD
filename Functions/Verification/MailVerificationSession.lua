local VERIFICATION_TIMEOUT_SECONDS = 5

FreshSoD_MailVerificationSession = nil
FreshSoD_mailVerificationTimeout = nil

function FreshSoD_ClearMailVerificationSession()
  if FreshSoD_mailVerificationTimeout then
    FreshSoD_mailVerificationTimeout:Cancel()
    FreshSoD_mailVerificationTimeout = nil
  end
  FreshSoD_MailVerificationSession = nil
end

local function getSelfBlockedMessage()
  if not FreshSoD_AmIVerified() then
    return 'Mail blocked - you are not verified.'
  end

  if not IsInGuild() then
    return 'Mail blocked - you are not in a guild.'
  end

  return 'Mail blocked - verification failed.'
end

local function getPartnerBlockedMessage(targetName, partnerVerified, partnerGuildName)
  if partnerVerified == false then
    return 'Cannot send mail to ' .. targetName .. ' - partner not verified.'
  end

  if FreshSoD_IsPlayerInGuildRoster(targetName) then
    return 'Cannot send mail to ' .. targetName .. ' - verification failed.'
  end

  if not partnerGuildName then
    return 'Cannot send mail to ' .. targetName .. ' - partner is not in a guild.'
  end

  if not FreshSoD_IsWhitelistedGuild(partnerGuildName) then
    return 'Cannot send mail to ' .. targetName .. ' - partner not in a sister guild.'
  end

  return 'Cannot send mail to ' .. targetName .. ' - verification failed.'
end

function FreshSoD_TryResolveMailVerification(isTimeout)
  local session = FreshSoD_MailVerificationSession
  if not session or session.resolved then
    return
  end

  if isTimeout and session.partnerVerified == nil then
    session.resolved = true
    local onComplete = session.onComplete
    local targetName = session.targetName
    FreshSoD_ClearMailVerificationSession()
    onComplete(false, 'Cannot send mail to ' .. targetName .. ' - verification timed out (they must be online).')
    return
  end

  if session.partnerVerified == nil then
    return
  end

  session.resolved = true

  local partnerPasses = FreshSoD_PassesLiveTradeVerification(
    session.partnerVerified,
    session.partnerGuildName,
    session.targetName
  )
  local canSend = FreshSoD_AmIEligibleForWhitelistedTrade() and partnerPasses
  local message
  if not canSend then
    if not FreshSoD_AmIEligibleForWhitelistedTrade() then
      message = getSelfBlockedMessage()
    else
      message = getPartnerBlockedMessage(session.targetName, session.partnerVerified, session.partnerGuildName)
    end
  end

  local onComplete = session.onComplete
  local targetName = session.targetName
  FreshSoD_ClearMailVerificationSession()

  if canSend then
    FreshSoD_PrintRestrictionMessage('Mail verification passed for ' .. Ambiguate(targetName, 'short'))
  end

  onComplete(canSend, message)
end

function FreshSoD_BeginMailVerification(playerName, onComplete)
  FreshSoD_ClearMailVerificationSession()

  if not FreshSoD_AmIEligibleForWhitelistedTrade() then
    onComplete(false, getSelfBlockedMessage())
    return
  end

  FreshSoD_MailVerificationSession = {
    targetName = playerName,
    onComplete = onComplete,
    partnerVerified = nil,
    partnerGuildName = nil,
    resolved = false,
  }

  FreshSoD_PrintRestrictionMessage('Requesting verification status from ' .. Ambiguate(playerName, 'short') .. '...')
  FreshSoD_SendMailVerificationQuery(playerName)

  if C_Timer and C_Timer.NewTimer then
    FreshSoD_mailVerificationTimeout = C_Timer.NewTimer(VERIFICATION_TIMEOUT_SECONDS, function()
      FreshSoD_TryResolveMailVerification(true)
    end)
  end
end

function FreshSoD_OnMailVerificationAnswerReceived(sender, isVerified, guildName)
  if type(BonniesUtilities_AddMailVerificationValidSender) == 'function' then
    BonniesUtilities_AddMailVerificationValidSender(sender)
  end

  if isVerified and guildName and FreshSoD_IsWhitelistedGuild(guildName) then
    FreshSoD_SetGuildMemberVerificationStatus(guildName, sender, true)
  elseif isVerified and FreshSoD_IsPlayerInGuildRoster(sender) then
    local myGuildName = FreshSoD_GetPlayerGuildName()
    if myGuildName then
      FreshSoD_SetGuildMemberVerificationStatus(myGuildName, sender, true)
    end
  end

  local session = FreshSoD_MailVerificationSession
  if not session or session.resolved or not FreshSoD_PlayerNamesMatch(sender, session.targetName) then
    return
  end

  session.partnerVerified = isVerified
  session.partnerGuildName = guildName

  if isVerified == true and FreshSoD_PassesLiveTradeVerification(isVerified, guildName, sender) then
    FreshSoD_PrintRestrictionMessage(Ambiguate(sender, 'short') .. ' has passed verification')
  elseif isVerified ~= true then
    FreshSoD_PrintRestrictionMessage(Ambiguate(sender, 'short') .. ' has failed verification')
  elseif FreshSoD_IsPlayerInGuildRoster(sender) then
    FreshSoD_PrintRestrictionMessage(Ambiguate(sender, 'short') .. ' has failed verification')
  elseif not guildName then
    FreshSoD_PrintRestrictionMessage(Ambiguate(sender, 'short') .. ' is not in a guild')
  else
    FreshSoD_PrintRestrictionMessage(Ambiguate(sender, 'short') .. ' is not in a sister guild')
  end

  FreshSoD_TryResolveMailVerification()
end

function FreshSoD_OnMailVerificationQueryReceived(sender, isVerified, guildName)
  local senderPasses = FreshSoD_PassesLiveTradeVerification(isVerified, guildName, sender)
  if not senderPasses and isVerified == nil and FreshSoD_IsPlayerInGuildRoster(sender) then
    senderPasses = FreshSoD_IsPlayerValidatedInWhitelistedGuild(sender)
  end

  if senderPasses and type(BonniesUtilities_AddMailVerificationValidSender) == 'function' then
    BonniesUtilities_AddMailVerificationValidSender(sender)
  end

  if not FreshSoD_AmIEligibleForWhitelistedTrade() then
    return
  end

  FreshSoD_SendMailVerificationAnswer(sender)
end
