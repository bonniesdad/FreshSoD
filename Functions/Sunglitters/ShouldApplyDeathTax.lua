local DAMAGE_EVENTS = {
  SWING_DAMAGE = true,
  SPELL_DAMAGE = true,
  RANGE_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
  ENVIRONMENTAL_DAMAGE = true,
}

local playerGUID
local lastDamageFromPlayer = false

local function isInDungeonOrRaid()
  local inInstance, instanceType = IsInInstance()
  if not inInstance then
    return false
  end

  return instanceType == 'party' or instanceType == 'raid'
end

local function isPlayerDamageSource(sourceFlags)
  if not sourceFlags then
    return false
  end

  return bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0
end

function FreshSoD_ShouldApplyDeathTaxOnDeath()
  if isInDungeonOrRaid() then
    local _, instanceType = IsInInstance()
    FreshSoD_LogDeathTax('Exempt: in instance (' .. tostring(instanceType) .. ')')
    lastDamageFromPlayer = false
    return false
  end

  local killedByPlayer = lastDamageFromPlayer
  lastDamageFromPlayer = false

  if killedByPlayer then
    FreshSoD_LogDeathTax('Exempt: final hit from a player')
    return false
  end

  FreshSoD_LogDeathTax('Death tax applies (final hit not from a player)')
  return true
end

local deathTaxExemptionFrame = CreateFrame('Frame')

deathTaxExemptionFrame:RegisterEvent('PLAYER_LOGIN')
deathTaxExemptionFrame:RegisterEvent('PLAYER_ALIVE')
deathTaxExemptionFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

deathTaxExemptionFrame:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_LOGIN' or event == 'PLAYER_ALIVE' then
    playerGUID = UnitGUID('player')
    lastDamageFromPlayer = false
    return
  end

  if event ~= 'COMBAT_LOG_EVENT_UNFILTERED' then
    return
  end

  if not playerGUID then
    playerGUID = UnitGUID('player')
  end

  local _, subEvent, _, _, _, sourceFlags, _, destGUID = CombatLogGetCurrentEventInfo()

  if not DAMAGE_EVENTS[subEvent] or destGUID ~= playerGUID then
    return
  end

  lastDamageFromPlayer = isPlayerDamageSource(sourceFlags)
end)

if UnitGUID('player') then
  playerGUID = UnitGUID('player')
end
