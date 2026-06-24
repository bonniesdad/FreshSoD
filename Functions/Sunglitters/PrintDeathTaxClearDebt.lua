local TITLE_COLOR = '|cffffd180'
local NAME_COLOR = '|cffffeb3b'
local TAX_COLOR = '|cffffd100'

local function formatDeathTaxMessage(body)
  return string.format('%s[Death Tax]|r %s', TITLE_COLOR, body)
end

local function formatPlayerName(playerName)
  return string.format('%s%s|r', NAME_COLOR, playerName)
end

local function formatTaxAmount(taxCopper)
  return string.format('%s%s|r', TAX_COLOR, FreshSoD_FormatDeathTaxAmount(taxCopper))
end

function FreshSoD_PrintDeathTaxDebtClearSent(targetPlayerName)
  local body = string.format('You cleared death tax debt for %s.', formatPlayerName(targetPlayerName))
  print(formatDeathTaxMessage(body))
end

function FreshSoD_PrintDeathTaxDebtClearReceived(officerName, clearedCopper)
  local body

  if clearedCopper and clearedCopper > 0 then
    body = string.format(
      '%s cleared your death tax debt of %s.',
      formatPlayerName(officerName),
      formatTaxAmount(clearedCopper)
    )
  else
    body = string.format('%s cleared your death tax debt.', formatPlayerName(officerName))
  end

  print(formatDeathTaxMessage(body))
end
