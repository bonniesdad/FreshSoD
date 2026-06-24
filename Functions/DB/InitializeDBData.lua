function FreshSoD_InitializeDBData()
  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
  end

  if not FRESH_SOD_DB.characterSettings then
    FRESH_SOD_DB.characterSettings = {}
  end

  local defaultSettings = {
    minimapButton = { hide = false },
    levelBracketAcknowledged = {},
    deathTaxOwedCopper = 0,
  }

  local characterGUID = UnitGUID('player')
  if not FRESH_SOD_DB.characterSettings[characterGUID] then
    FRESH_SOD_DB.characterSettings[characterGUID] = defaultSettings
  end

  for settingName, settingValue in pairs(defaultSettings) do
    if FRESH_SOD_DB.characterSettings[characterGUID][settingName] == nil then
      FRESH_SOD_DB.characterSettings[characterGUID][settingName] = settingValue
    end
  end

  FRESH_SOD_GLOBAL_SETTINGS = FRESH_SOD_DB.characterSettings[characterGUID]

  if FreshSoD_EnsureGuildVerificationDB then
    FreshSoD_EnsureGuildVerificationDB()
  end

  if not FRESH_SOD_DB.globalSettings then
    FRESH_SOD_DB.globalSettings = {}
  end

  if FRESH_SOD_DB.globalSettings.deathTaxSoundsMuted == nil then
    FRESH_SOD_DB.globalSettings.deathTaxSoundsMuted = false
  end
end
