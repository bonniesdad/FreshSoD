local TITLE_COLOR = '|cffffd180'
local NAME_COLOR = '|cffffeb3b'
local TAX_COLOR = '|cffffd100'

local function formatAuditMessage(body)
  return string.format('%s[Death Tax Audit]|r %s', TITLE_COLOR, body)
end

local function formatPlayerName(playerName)
  return string.format('%s%s|r', NAME_COLOR, playerName)
end

local function formatTaxAmount(taxCopper)
  return string.format('%s%s|r', TAX_COLOR, FreshSoD_FormatDeathTaxAmount(taxCopper))
end

function FreshSoD_PrintDeathAuditStarted(otherPlayerName, isAuditor)
  local body

  if isAuditor then
    body = string.format('You began auditing %s.', formatPlayerName(otherPlayerName))
  else
    body = string.format('You are being audited by %s.', formatPlayerName(otherPlayerName))
  end

  print(formatAuditMessage(body))
end

function FreshSoD_PrintDeathAuditCancelled(otherPlayerName, isAuditor)
  local body

  if isAuditor then
    body = string.format('Audit of %s was cancelled.', formatPlayerName(otherPlayerName))
  else
    body = string.format('Your audit by %s was cancelled.', formatPlayerName(otherPlayerName))
  end

  print(formatAuditMessage(body))
end

function FreshSoD_PrintDeathAuditResult(playerName, taxCopper)
  local body = string.format(
    '%s owes %s in outstanding death tax.',
    formatPlayerName(playerName),
    formatTaxAmount(taxCopper)
  )

  print(formatAuditMessage(body))
end

function FreshSoD_PrintDeathAuditCompleted(otherPlayerName, taxCopper, isAuditor)
  local body

  if isAuditor then
    body = string.format(
      'Audit of %s is complete. They owe %s in outstanding death tax.',
      formatPlayerName(otherPlayerName),
      formatTaxAmount(taxCopper)
    )
  else
    body = string.format(
      'Your audit by %s is complete. You owe %s in outstanding death tax.',
      formatPlayerName(otherPlayerName),
      formatTaxAmount(taxCopper)
    )
  end

  print(formatAuditMessage(body))
end
