local TITLE_COLOR = '|cffffd180'
local NAME_COLOR = '|cffffeb3b'
local TAX_COLOR = '|cffffd100'
local BODY_COLOR = '|cffe6e0d6'

function FreshSoD_PrintDeathAuditResult(playerName, taxCopper)
  local formattedAmount = FreshSoD_FormatDeathTaxAmount(taxCopper)
  local message = string.format(
    '%s[Death Tax Audit]|r %s%s|r owes %s%s|r in outstanding death tax.',
    TITLE_COLOR,
    NAME_COLOR,
    playerName,
    TAX_COLOR,
    formattedAmount
  )

  print(message)
end
