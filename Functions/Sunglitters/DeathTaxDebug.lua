local LOG_PREFIX = '|cffd48806[FreshSoD Death Tax]|r'

local function ensureDeathTaxDebugDB()
  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
  end

  if not FRESH_SOD_DB.globalSettings then
    FRESH_SOD_DB.globalSettings = {}
  end

  if FRESH_SOD_DB.globalSettings.deathTaxDebug == nil then
    FRESH_SOD_DB.globalSettings.deathTaxDebug = true
  end
end

function FreshSoD_IsDeathTaxDebugEnabled()
  ensureDeathTaxDebugDB()
  return FRESH_SOD_DB.globalSettings.deathTaxDebug == true
end

function FreshSoD_SetDeathTaxDebugEnabled(isEnabled)
  ensureDeathTaxDebugDB()
  FRESH_SOD_DB.globalSettings.deathTaxDebug = isEnabled == true
end

function FreshSoD_ToggleDeathTaxDebug()
  FreshSoD_SetDeathTaxDebugEnabled(not FreshSoD_IsDeathTaxDebugEnabled())
  print(LOG_PREFIX .. ' Debug ' .. (FreshSoD_IsDeathTaxDebugEnabled() and 'enabled' or 'disabled') .. '.')
end

function FreshSoD_LogDeathTax(message)
  if not FreshSoD_IsDeathTaxDebugEnabled() then
    return
  end

  print(LOG_PREFIX .. ' ' .. tostring(message))
end

local debugLoginFrame = CreateFrame('Frame')
debugLoginFrame:RegisterEvent('PLAYER_LOGIN')
debugLoginFrame:SetScript('OnEvent', function()
  if FreshSoD_IsDeathTaxDebugEnabled() then
    print(LOG_PREFIX .. ' Debug logging enabled. Toggle with /sgfdeathtaxdebug')
  end
end)

SLASH_FRESHSOD_DEATH_TAX_DEBUG1 = '/sgfdeathtaxdebug'
SlashCmdList['FRESHSOD_DEATH_TAX_DEBUG'] = function()
  FreshSoD_ToggleDeathTaxDebug()
end
