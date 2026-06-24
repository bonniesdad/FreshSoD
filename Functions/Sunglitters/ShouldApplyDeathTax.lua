local DAMAGE_EVENTS = {
  SWING_DAMAGE = true,
  SPELL_DAMAGE = true,
  RANGE_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
  ENVIRONMENTAL_DAMAGE = true,
}

local playerGUID
local lastDamageFromHostilePlayer = false

local function isInDungeonOrRaid()
  local inInstance, instanceType = IsInInstance()
  if not inInstance then
    return false
  end

  return instanceType == 'party' or instanceType == 'raid'
end

local function isHostilePlayerSource(sourceFlags)
  if not sourceFlags then
    return false
  end

  local isPlayer = bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0
  local isHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0
  return isPlayer and isHostile
end

local function isPvpDeath()
  if GetPVPTimer and GetPVPTimer() > 0 then
    return true
  end

  return lastDamageFromHostilePlayer
end

function FreshSoD_ShouldApplyDeathTaxOnDeath()
  if isInDungeonOrRaid() then
    lastDamageFromHostilePlayer = false
    return false
  end

  local pvpDeath = isPvpDeath()
  lastDamageFromHostilePlayer = false

  if pvpDeath then
    return false
  end

  return true
end

local deathTaxExemptionFrame = CreateFrame('Frame')

deathTaxExemptionFrame:RegisterEvent('PLAYER_LOGIN')
deathTaxExemptionFrame:RegisterEvent('PLAYER_ALIVE')
deathTaxExemptionFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

deathTaxExemptionFrame:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_LOGIN' or event == 'PLAYER_ALIVE' then
    playerGUID = UnitGUID('player')
    lastDamageFromHostilePlayer = false
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

  lastDamageFromHostilePlayer = isHostilePlayerSource(sourceFlags)
end)

if UnitGUID('player') then
  playerGUID = UnitGUID('player')
end
