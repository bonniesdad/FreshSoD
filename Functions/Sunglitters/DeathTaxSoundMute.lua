local function ensureDeathTaxSoundMuteDB()
  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
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
end

function FreshSoD_AreDeathTaxNotificationsDisabled()
  ensureDeathTaxSoundMuteDB()
  return FRESH_SOD_DB.globalSettings.deathTaxNotificationsDisabled == true
end

function FreshSoD_SetDeathTaxNotificationsDisabled(isDisabled)
  ensureDeathTaxSoundMuteDB()
  FRESH_SOD_DB.globalSettings.deathTaxNotificationsDisabled = isDisabled == true
end

function FreshSoD_ToggleDeathTaxNotificationsDisabled()
  FreshSoD_SetDeathTaxNotificationsDisabled(not FreshSoD_AreDeathTaxNotificationsDisabled())
end

function FreshSoD_AreDeathTaxSoundsMuted()
  ensureDeathTaxSoundMuteDB()
  return FRESH_SOD_DB.globalSettings.deathTaxSoundsMuted == true
end

function FreshSoD_SetDeathTaxSoundsMuted(isMuted)
  ensureDeathTaxSoundMuteDB()
  FRESH_SOD_DB.globalSettings.deathTaxSoundsMuted = isMuted == true
end

function FreshSoD_ToggleDeathTaxSoundsMuted()
  FreshSoD_SetDeathTaxSoundsMuted(not FreshSoD_AreDeathTaxSoundsMuted())
end
