-- Classic blocks SendChatMessage from addon event handlers. Partner guild status is
-- shared via whisper addon messages during trade verification instead.

function FreshSoD_OnCommsChannelMessage(...)
  local message, sender = select(1, ...), select(2, ...)
  if not message or not sender then
    return
  end

  local isVerified, guildName = FreshSoD_ParseGuildVerificationCommsMessage(message)
  if isVerified == nil then
    return
  end

  if isVerified then
    FreshSoD_SetAllowedPartnerGuildMemberStatus(guildName, sender, true)
  end

  if FreshSoD_RefreshGuildBoardTabIfVisible then
    FreshSoD_RefreshGuildBoardTabIfVisible()
  end
end
