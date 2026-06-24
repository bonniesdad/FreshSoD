function FreshSoD_ParseDeathTaxLeaderboardMessage(message)
  if not message then
    return nil, nil
  end

  local totalCopper, playerName = message:match('^DL:(%d+):(.+)$')
  if not totalCopper or not playerName or playerName == '' then
    return nil, nil
  end

  return playerName, tonumber(totalCopper)
end
