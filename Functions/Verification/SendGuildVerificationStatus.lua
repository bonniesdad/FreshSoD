local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendGuildVerificationStatus(isVerified)
  if not IsInGuild() then
    return
  end

  local message = isVerified and 'GV:1' or 'GV:0'
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'GUILD')
end

-- Someone pinged us for our status so we whisper it straight back to just them instead of shouting it at the entire guild. If half the guild asks at the same
-- time we'd rather not carpet bomb guild chat so theres a tiny random delay below to space the replies out.
function FreshSoD_ReplyGuildVerificationStatus(target)
  if not target or not IsInGuild() then
    return
  end

  local message = FreshSoD_AmIVerified() and 'GV:1' or 'GV:0'

  local function send()
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'WHISPER', target)
  end

  if C_Timer and C_Timer.After and math and math.random then
    -- little random stagger so a big synced login doesnt turn into everybody whispering everybody at the exact same millisecond. chaos avoided.
    C_Timer.After(math.random() * 3, send)
  else
    send()
  end
end

-- Yell at the whole guild to (re)send their status. We only do this once after login, because if you logged in late then everyone already shouted their status
-- while you werent even listening, so you basically missed the whole convo.
function FreshSoD_SendGuildVerificationRequest()
  if not IsInGuild() then
    return
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, 'GVR:1', 'GUILD')
end

-- Poke one specific person for their status. Mostly used when youre trying to mail someone and we genuinely have no clue yet whether theyre legit.
function FreshSoD_RequestGuildVerificationFromPlayer(target)
  if not target or target == '' or not IsInGuild() then
    return
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, 'GVR:1', 'WHISPER', target)
end
