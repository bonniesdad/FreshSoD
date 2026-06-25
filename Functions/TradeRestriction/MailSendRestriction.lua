local sendGuardInstalled = false
local canSendHookInstalled = false

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
    FreshSoD_ClearMailVerificationSession()
  end)
end

local function getRecipient()
  if SendMailNameEditBox then
    return SendMailNameEditBox:GetText()
  end
  return nil
end

local function updateSendMailButtonState()
  if type(SendMailFrame_CanSend) == 'function' then
    SendMailFrame_CanSend()
    return
  end

  if not SendMailMailButton or not SendMailMailButton:IsEnabled() then
    return
  end

  local recipient = getRecipient()
  if not recipient or recipient == '' then
    return
  end

  local allowed = FreshSoD_CanSendMailToRecipientOrVerify(recipient)
  if not allowed then
    SendMailMailButton:Disable()
  end
end

local function beginVerifiedSend(recipient, sendFn, ...)
  if FreshSoD_CanSendMailToRecipient(recipient) then
    return sendFn(recipient, ...)
  end

  FreshSoD_BeginMailVerification(recipient, function(canSend, reason)
    if not canSend then
      FreshSoD_PrintRestrictionMessage(reason)
      if SendMailMailButton then
        SendMailMailButton:Enable()
      end
      return
    end

    sendFn(recipient, ...)
  end)

  return true
end

local function blockInvalidSend(recipient, sendFn, ...)
  if not recipient or recipient == '' then
    return false
  end

  if FreshSoD_CanSendMailToRecipient(recipient) then
    return false
  end

  if FreshSoD_CanAttemptMailVerification(recipient) then
    beginVerifiedSend(recipient, sendFn, ...)
    return true
  end

  local _, reason = FreshSoD_CanSendMailToRecipient(recipient)
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

  hooksecurefunc('SendMailFrame_CanSend', function()
    if not SendMailMailButton or not SendMailMailButton:IsEnabled() then
      return
    end

    local recipient = getRecipient()
    if not recipient or recipient == '' then
      return
    end

    local allowed = FreshSoD_CanSendMailToRecipientOrVerify(recipient)
    if not allowed then
      SendMailMailButton:Disable()
    end
  end)

  canSendHookInstalled = true
end

local function installSendGuard()
  if not sendGuardInstalled then
    if type(SendMail) == 'function' then
      local origSendMail = SendMail
      SendMail = function(recipient, ...)
        if blockInvalidSend(recipient, origSendMail, ...) then
          return
        end
        return origSendMail(recipient, ...)
      end
      sendGuardInstalled = true
    elseif type(SendMailFrame_SendMail) == 'function' then
      local origFrameSend = SendMailFrame_SendMail
      SendMailFrame_SendMail = function(...)
        if blockInvalidSend(getRecipient(), origFrameSend, ...) then
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

mailSendRestrictionFrame:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_LOGIN' or event == 'MAIL_SHOW' then
    hookSendMailFrame()
    installSendGuard()
    updateSendMailButtonState()
    return
  end

  if event == 'MAIL_CLOSED' then
    FreshSoD_HideSendMailRestrictionOverlay()
    FreshSoD_ClearMailVerificationSession()
    return
  end

  updateSendMailButtonState()
end)

hookSendMailFrame()
