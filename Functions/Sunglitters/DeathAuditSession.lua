local auditorSession
local auditeeSession

local function normalizePlayerName(playerName)
  if not playerName then
    return nil
  end

  return string.lower(Ambiguate(playerName, 'short'))
end

local function generateAuditId()
  return string.format('%.0f', GetTime() * 1000)
end

local function getInspectTargetName()
  if not InspectFrame or not InspectFrame.unit then
    return nil
  end

  return GetUnitName(InspectFrame.unit, true)
end

local function isInspectSessionValid(session)
  if not session or not InspectFrame or not InspectFrame:IsShown() then
    return false
  end

  if not InspectFrame.unit then
    return false
  end

  local currentTarget = GetUnitName(InspectFrame.unit, true)
  return currentTarget ~= nil and currentTarget == session.targetName
end

local function clearAuditorSession(sendCancel)
  if not auditorSession then
    return
  end

  local session = auditorSession
  auditorSession = nil

  if session.progressBar then
    FreshSoD_HideAuditProgressBar(session.progressBar)
  end

  if sendCancel and session.targetName and session.auditId then
    FreshSoD_SendDeathAuditCancel(session.targetName, session.auditId)
  end
end

local function clearAuditeeSession()
  if not auditeeSession then
    return
  end

  local session = auditeeSession
  auditeeSession = nil

  if session.progressBar then
    FreshSoD_HideAuditProgressBar(session.progressBar)
  end
end

function FreshSoD_CancelDeathAudit(sendCancelMessage)
  clearAuditorSession(sendCancelMessage == true)
end

function FreshSoD_StartDeathAudit()
  if not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    return
  end

  if auditorSession then
    return
  end

  local targetName = getInspectTargetName()
  if not targetName or UnitIsUnit(InspectFrame.unit, 'player') then
    return
  end

  if not FreshSoD_IsUnitInDeathTaxGuild(InspectFrame.unit) then
    return
  end

  clearAuditorSession(true)
  clearAuditeeSession()

  local auditId = generateAuditId()
  local auditorName = GetUnitName('player', true)

  auditorSession = {
    auditId = auditId,
    targetName = targetName,
    auditorName = auditorName,
    progressBar = nil,
  }

  FreshSoD_SendDeathAuditStart(targetName, auditId, auditorName)

  local inspectParent = InspectPaperDollFrame or InspectFrame or UIParent
  auditorSession.progressBar = FreshSoD_ShowAuditProgressBar({
    parent = inspectParent,
    label = 'Auditing',
    onComplete = function()
      if not auditorSession or auditorSession.auditId ~= auditId then
        return
      end

      auditorSession.progressBar = nil
      FreshSoD_SendDeathAuditRequest(auditorSession.targetName, auditId)
    end,
    onCancelled = function()
      if auditorSession and auditorSession.auditId == auditId then
        clearAuditorSession(true)
      end
    end,
    shouldCancel = function()
      return not isInspectSessionValid(auditorSession)
    end,
  })
end

function FreshSoD_HandleDeathAuditStart(auditId, auditorName, sender)
  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if not sender or not FreshSoD_IsPlayerInGuildRoster(sender) then
    return
  end

  if not FreshSoD_IsOfficerGuildRank(sender) then
    return
  end

  clearAuditeeSession()

  auditeeSession = {
    auditId = auditId,
    auditorName = sender,
    progressBar = nil,
  }

  auditeeSession.progressBar = FreshSoD_ShowAuditProgressBar({
    parent = UIParent,
    label = 'Being audited...',
    onCancelled = function()
      if auditeeSession and auditeeSession.auditId == auditId then
        clearAuditeeSession()
      end
    end,
    onComplete = function()
      if auditeeSession and auditeeSession.auditId == auditId then
        auditeeSession.progressBar = nil
      end
    end,
    shouldCancel = function()
      return auditeeSession == nil or auditeeSession.auditId ~= auditId
    end,
  })
end

function FreshSoD_HandleDeathAuditCancel(auditId)
  if auditeeSession and auditeeSession.auditId == auditId then
    clearAuditeeSession()
  end
end

function FreshSoD_HandleDeathAuditRequest(auditId, sender)
  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if not auditeeSession or auditeeSession.auditId ~= auditId then
    return
  end

  if not sender or normalizePlayerName(sender) ~= normalizePlayerName(auditeeSession.auditorName) then
    return
  end

  clearAuditeeSession()
  FreshSoD_SendDeathAuditResponse(sender, auditId, FreshSoD_GetDeathTaxOwedCopper())
end

function FreshSoD_HandleDeathAuditResponse(auditId, taxCopper, sender)
  if not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    return
  end

  if not auditorSession or auditorSession.auditId ~= auditId then
    return
  end

  if not sender or normalizePlayerName(sender) ~= normalizePlayerName(auditorSession.targetName) then
    return
  end

  clearAuditorSession(false)
  FreshSoD_PrintDeathAuditResult(Ambiguate(sender, 'short'), taxCopper)
end

local inspectCancelFrame = CreateFrame('Frame')
inspectCancelFrame:RegisterEvent('ADDON_LOADED')

inspectCancelFrame:SetScript('OnEvent', function(_, event, loadedAddon)
  if event ~= 'ADDON_LOADED' or loadedAddon ~= 'Blizzard_InspectUI' then
    return
  end

  if InspectFrame then
    InspectFrame:HookScript('OnHide', function()
      FreshSoD_CancelDeathAudit(true)
    end)
  end
end)

if InspectFrame then
  InspectFrame:HookScript('OnHide', function()
    FreshSoD_CancelDeathAudit(true)
  end)
end
