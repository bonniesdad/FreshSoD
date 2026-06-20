local frame = CreateFrame('Frame')
local nonGuildTradeCheckScheduled = false
local guildTradeVerificationTimer = nil
local guildTradeVerificationRetryTimer = nil
local tradeSessionGeneration = 0
local tradeWindowOpen = false

local TRADE_CONTENT_EVENTS = {
  'TRADE_SHOW',
  'TRADE_UPDATE',
  'TRADE_ACCEPT_UPDATE',
  'TRADE_MONEY_CHANGED',
  'PLAYER_TRADE_MONEY',
  'TRADE_PLAYER_ITEM_CHANGED',
  'TRADE_TARGET_ITEM_CHANGED',
}

local TRADE_MONEY_EVENTS = {
  TRADE_MONEY_CHANGED = true,
  PLAYER_TRADE_MONEY = true,
}

for _, tradeEvent in ipairs(TRADE_CONTENT_EVENTS) do
  frame:RegisterEvent(tradeEvent)
end

frame:RegisterEvent('TRADE_CLOSED')
frame:RegisterEvent('AUCTION_HOUSE_SHOW')
frame:RegisterEvent('GUILD_ROSTER_UPDATE')

local function cancelNonGuildTrade()
  local partnerName = GetUnitName('npc', true)
  local hasMoney = type(BonniesUtilities_TradeHasMoney) == 'function'
    and BonniesUtilities_TradeHasMoney()
  local message = hasMoney
    and 'Trade blocked - no gold allowed with non-guild members.'
    or 'Trade blocked - only whitelisted items allowed with non-guild members.'
  if partnerName then
    message = hasMoney
      and ('Trade with ' .. partnerName .. ' blocked - no gold allowed.')
      or ('Trade with ' .. partnerName .. ' blocked - only whitelisted items allowed.')
  end
  FreshSoD_CancelTradeWithMessage(message)
end

local function runNonGuildTradeCheck()
  nonGuildTradeCheckScheduled = false
  if FreshSoD_HasPassedGuildTradeVerification and FreshSoD_HasPassedGuildTradeVerification() then
    return
  end
  if FreshSoD_ShouldDeferNonGuildTradeCheck and FreshSoD_ShouldDeferNonGuildTradeCheck() then
    return
  end
  if type(BonniesUtilities_TradeViolatesNonGuildRestrictions) ~= 'function' then
    return
  end
  if BonniesUtilities_TradeViolatesNonGuildRestrictions() then
    cancelNonGuildTrade()
  end
end

local function cancelGuildTradeVerificationTimers()
  if guildTradeVerificationTimer then
    guildTradeVerificationTimer:Cancel()
    guildTradeVerificationTimer = nil
  end

  if guildTradeVerificationRetryTimer then
    guildTradeVerificationRetryTimer:Cancel()
    guildTradeVerificationRetryTimer = nil
  end
end

local function runGuildTradeVerificationCheck(generation)
  if generation ~= tradeSessionGeneration then
    return
  end

  FreshSoD_UpdateGuildTradeVerification()
end

local function scheduleGuildTradeVerificationRetry(generation)
  if not C_Timer or not C_Timer.After then
    return
  end

  if guildTradeVerificationRetryTimer then
    guildTradeVerificationRetryTimer:Cancel()
  end

  guildTradeVerificationRetryTimer = C_Timer.After(0.05, function()
    guildTradeVerificationRetryTimer = nil

    if generation ~= tradeSessionGeneration then
      return
    end

    if type(BonniesUtilities_TradeRequiresGuildVerification) ~= 'function' then
      return
    end

    if not BonniesUtilities_TradeRequiresGuildVerification() then
      return
    end

    local session = FreshSoD_TradeVerificationSession
    if session and not session.resolved then
      return
    end

    FreshSoD_UpdateGuildTradeVerification()
  end)
end

local function scheduleGuildTradeVerificationCheck()
  local generation = tradeSessionGeneration

  cancelGuildTradeVerificationTimers()

  if C_Timer and C_Timer.After then
    guildTradeVerificationTimer = C_Timer.After(0, function()
      guildTradeVerificationTimer = nil
      runGuildTradeVerificationCheck(generation)
      scheduleGuildTradeVerificationRetry(generation)
    end)
  else
    runGuildTradeVerificationCheck(generation)
  end
end

local function scheduleNonGuildTradeCheck()
  if nonGuildTradeCheckScheduled then
    return
  end
  nonGuildTradeCheckScheduled = true

  if C_Timer and C_Timer.After then
    C_Timer.After(0, runNonGuildTradeCheck)
  else
    runNonGuildTradeCheck()
  end
end

frame:SetScript('OnEvent', function(self, event, ...)
  if event == 'TRADE_SHOW' then
    tradeWindowOpen = true
    tradeSessionGeneration = tradeSessionGeneration + 1
    FreshSoD_ResetGuildTradeVerification()
    scheduleNonGuildTradeCheck()
  elseif event == 'GUILD_ROSTER_UPDATE' then
    -- This trade may have opened before the guild roster was ready check it again now that we have roster data instead of leaving the trade stuck in a blocked state for the rest of the session.

    if tradeWindowOpen then
      scheduleNonGuildTradeCheck()
      if type(FreshSoD_TryResolveTradeVerification) == 'function' then
        FreshSoD_TryResolveTradeVerification()
      end
      scheduleGuildTradeVerificationCheck()
    end
  elseif event == 'TRADE_UPDATE'
    or event == 'TRADE_ACCEPT_UPDATE'
    or event == 'TRADE_MONEY_CHANGED'
    or event == 'PLAYER_TRADE_MONEY'
    or event == 'TRADE_PLAYER_ITEM_CHANGED'
    or event == 'TRADE_TARGET_ITEM_CHANGED' then
    scheduleNonGuildTradeCheck()

    if TRADE_MONEY_EVENTS[event] then
      runGuildTradeVerificationCheck(tradeSessionGeneration)
    end

    scheduleGuildTradeVerificationCheck()
  elseif event == 'TRADE_CLOSED' then
    tradeWindowOpen = false
    tradeSessionGeneration = tradeSessionGeneration + 1
    nonGuildTradeCheckScheduled = false
    cancelGuildTradeVerificationTimers()
    FreshSoD_ResetGuildTradeVerification()
    FreshSoD_ClearPartnerVerificationCache()
    FreshSoD_EndTradeVerification()
  elseif event == 'AUCTION_HOUSE_SHOW' then
    FreshSoD_CancelAuctionHouseWithMessage('Auction House blocked')
  end
end)
