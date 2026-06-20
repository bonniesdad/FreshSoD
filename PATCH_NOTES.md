# Patch Notes

## 1.1.2 (2026-06-20)

Pushed by Fjella

**BUG FIXES:**
• Trades and mail with guild members no longer require a /reload or relog after logging in
• Fixed mail to guild members getting blocked with "verification status unknown" until both players reloaded
• Verification status now syncs between guild members on login instead of sometimes being missed until a reload
• Opening your mailbox right after login no longer risks flagging guild members' mail for return
• Fixed some settings (death tax owed, level bracket acknowledgements) occasionally not saving

**OTHER:**
• Reworked guild roster handling to be event-driven and cached — this is the root-cause fix behind the trade/mail reload issues
• Added safety guards so a missing or updated BonniesUtilities degrades gracefully instead of throwing errors
• Minor wording fixes on mail messages

## 1.1.1 (2026-06-19)

**HOTFIX:**
• slash command /sgf /sodguildfound /freshsod opens the menu


## 1.1.0 (2026-06-19)

**HOTFIX:**
• Return gold only mail rather than delete


## 1.0.9 (2026-06-18)

**FEATURES:**
• Fix compatability issue with quetie for some peoples


## 1.0.8 (2026-06-18)

**FEATURES:**
• Death tax display update 
• Death tax soundbyte trigger
• Improve wording on level cap message

## 1.0.7 (2026-06-17)

**FEATURES:**
• Death tax guild announcement for Sunglitters guild

## 1.0.6 (2026-06-17)

**FEATURES:**
• Send Mail warning message
• Show remaining mail to return count

**BUG FIXES:**
• Unable to return non returnable items resulting in "mail locked" scenario
• Allow returned mail to be received

## 1.0.5 (2026-06-16)

**FEATURES:**
• Level cap warning on level up

**BUG FIXES:**
• Able to put items in the enchanting ("will not be traded") trade slot with non-valid players


## 1.0.4 (2026-06-16)

**FEATURES:**
• Trade with whitelisted guilds


## 1.0.3 (2026-06-15)

**FEATURES:**
• Guild leaders can reset verification status 

**BUG FIXES:**
• Able to send mail to invalid guild members
• Unable to trade consumables to invalid guild members

## 1.0.2 (2026-06-14)

**OTHER:**
• Update name of addon
• Include all files in addon zip


## 1.0.1 (2026-05-26)

**OTHER:**
• Remove buff requirement from validation


## 1.0.0 (2026-05-26)

**FEATURES:**
•

**BUG FIXES:**
•

**OTHER:**
• Minimap button initialization
