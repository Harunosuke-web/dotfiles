-- ~/.config/hammerspoon/init.lua
-- アプリを切り替えるたびに入力ソースを英数(ABC)へリセットする。
-- 滞在中に手動で日本語にした時だけ日本語入力になり、
-- 別アプリへ移る/戻ると再び英数になる。

local ENGLISH_SOURCE = "com.apple.keylayout.ABC"

-- 現在が英数でなければ英数へ切り替える（無駄な切替を避ける）
local function toEnglish()
  if hs.keycodes.currentSourceID() ~= ENGLISH_SOURCE then
    hs.keycodes.currentSourceID(ENGLISH_SOURCE)
  end
end

-- アプリのアクティブ化を監視。activated の瞬間に英数へ。
-- 注意: watcher はグローバルに保持しないと GC で停止するため local にしない。
appWatcher = hs.application.watcher.new(function(_appName, eventType, _appObject)
  if eventType == hs.application.watcher.activated then
    toEnglish()
  end
end)
appWatcher:start()

hs.alert.show("Hammerspoon config loaded")
