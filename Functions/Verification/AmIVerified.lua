function FreshSoD_AmIVerified()
  -- Verification depends on BonniesUtilities if the function is missing for whatever reason, fail safely and treat the player as unverified better to block verification than spam Lua errors all over the place or?
  if type(BonniesUtilities_GetNaughtyBoolean) ~= 'function' then
    return false
  end

  return not BonniesUtilities_GetNaughtyBoolean()
end
