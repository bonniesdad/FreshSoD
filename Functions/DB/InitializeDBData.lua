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
    deathTaxTotalAccumulatedCopper = 0,
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

  local characterSettings = FRESH_SOD_DB.characterSettings[characterGUID]
  if characterSettings.deathTaxTotalAccumulatedCopper == nil then
    characterSettings.deathTaxTotalAccumulatedCopper = characterSettings.deathTaxOwedCopper or 0
  end

  FRESH_SOD_GLOBAL_SETTINGS = characterSettings

  if FreshSoD_EnsureGuildVerificationDB then
    FreshSoD_EnsureGuildVerificationDB()
  end

  if not FRESH_SOD_DB.globalSettings then
    FRESH_SOD_DB.globalSettings = {}
  end

  if FRESH_SOD_DB.globalSettings.deathTaxSoundsMuted == nil then
    FRESH_SOD_DB.globalSettings.deathTaxSoundsMuted = false
  end

  if FRESH_SOD_DB.globalSettings.deathTaxNotificationsDisabled == nil then
    FRESH_SOD_DB.globalSettings.deathTaxNotificationsDisabled = false
  end

  if FreshSoD_EnsureDeathTaxLeaderboardDB then
    FreshSoD_EnsureDeathTaxLeaderboardDB()
  end
end
