local sendGuardInstalled = false
local canSendHookInstalled = false

local RECIPIENT_REQUEST_THROTTLE_SECONDS = 5
local lastRecipientRequest = {}

local function hookSendMailFrame()
  if not SendMailFrame or SendMailFrame.freshSoDSendMailHooked then
    return
  end

  SendMailFrame.freshSoDSendMailHooked = true
  SendMailFrame:HookScript('OnShow', function()
    FreshSoD_ShowSendMailRestrictionOverlay()
  end)
  SendMailFrame:HookScript('OnHide', function()
    FreshSoD_HideSendMailRestrictionOverlay()
  end)
end

local function getRecipient()
  if SendMailNameEditBox then
    return SendMailNameEditBox:GetText()
  end
  return nil
end

-- We have not received this guildies verification status yet.
-- That means the send check is stuck with "I dunno" and cannot continue.
-- Request their status now so the next attempt can succeed instead of telling people to /reload and pray.
local function requestRecipientVerificationIfNeeded(recipient)
  if not recipient or recipient == '' or not IsInGuild() then
    return
  end

  if not FreshSoD_IsPlayerInGuildRoster(recipient) then
    return
  end

  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    return
  end

  if FreshSoD_GetGuildMemberVerificationStatus(guildName, recipient) ~= nil then
    return
  end

  local key = string.lower(Ambiguate(recipient, 'short'))
  local now = (GetTime and GetTime()) or 0
  if lastRecipientRequest[key] and (now - lastRecipientRequest[key]) < RECIPIENT_REQUEST_THROTTLE_SECONDS then
    return
  end
  lastRecipientRequest[key] = now

  if FreshSoD_RequestGuildVerificationFromPlayer then
    FreshSoD_RequestGuildVerificationFromPlayer(recipient)
  end
end

local function evaluateRecipientAndMaybeBlock()
  if not SendMailMailButton or not SendMailMailButton:IsEnabled() then
    return
  end

  local recipient = getRecipient()
  if not recipient or recipient == '' then
    return
  end

  requestRecipientVerificationIfNeeded(recipient)

  local allowed = FreshSoD_CanSendMailToRecipient(recipient)
  if not allowed then
    SendMailMailButton:Disable()
  end
end

local function updateSendMailButtonState()
  if type(SendMailFrame_CanSend) == 'function' then
    SendMailFrame_CanSend()
    return
  end

  evaluateRecipientAndMaybeBlock()
end

local function blockInvalidSend(recipient)
  local allowed, reason = FreshSoD_CanSendMailToRecipient(recipient)
  if allowed then
    return false
  end

  requestRecipientVerificationIfNeeded(recipient)
  FreshSoD_PrintRestrictionMessage(reason)
  if SendMailMailButton then
    SendMailMailButton:Enable()
  end
  return true
end

local function installCanSendHook()
  if canSendHookInstalled or type(SendMailFrame_CanSend) ~= 'function' then
    return
  end

  hooksecurefunc('SendMailFrame_CanSend', evaluateRecipientAndMaybeBlock)

  canSendHookInstalled = true
end

local function installSendGuard()
  if not sendGuardInstalled then
    if type(SendMail) == 'function' then
      local origSendMail = SendMail
      SendMail = function(recipient, ...)
        if blockInvalidSend(recipient) then
          return
        end
        return origSendMail(recipient, ...)
      end
      sendGuardInstalled = true
    elseif type(SendMailFrame_SendMail) == 'function' then
      local origFrameSend = SendMailFrame_SendMail
      SendMailFrame_SendMail = function(...)
        if blockInvalidSend(getRecipient()) then
          return
        end
        return origFrameSend(...)
      end
      sendGuardInstalled = true
    end
  end

  installCanSendHook()
end

local mailSendRestrictionFrame = CreateFrame('Frame')
mailSendRestrictionFrame:RegisterEvent('PLAYER_LOGIN')
mailSendRestrictionFrame:RegisterEvent('MAIL_SHOW')
mailSendRestrictionFrame:RegisterEvent('MAIL_CLOSED')
mailSendRestrictionFrame:RegisterEvent('MAIL_SEND_INFO_UPDATE')
mailSendRestrictionFrame:RegisterEvent('GUILD_ROSTER_UPDATE')
mailSendRestrictionFrame:RegisterEvent('CHAT_MSG_ADDON')

mailSendRestrictionFrame:SetScript('OnEvent', function(_, event, ...)
  if event == 'PLAYER_LOGIN' or event == 'MAIL_SHOW' then
    hookSendMailFrame()
    installSendGuard()
    updateSendMailButtonState()
    return
  end

  if event == 'MAIL_CLOSED' then
    FreshSoD_HideSendMailRestrictionOverlay()
    return
  end

  if event == 'CHAT_MSG_ADDON' then
    -- We might have received the recipient's verification status by now check again and enable the Send button if we finally have enough information to make a decision.

    local prefix = ...
    if prefix == 'FreshSoD' and SendMailFrame and SendMailFrame:IsShown() then
      updateSendMailButtonState()
    end
    return
  end

  updateSendMailButtonState()
end)

hookSendMailFrame()
