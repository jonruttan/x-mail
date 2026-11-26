; # x-mail -- a mail client on x-lang
;
; ## lib/mail-client/help.x -- the keys, as the help tab shows them
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)

(module mail-client/help)

(def client-help
  (Str8 join "\n"
    (list
      "# mail-client"
      ""
      "The folders are on the left; on the right, the folder's messages, newest first, over the selected one.  One of the three has the keys: its bar is bold.  The bar at the top lists the tabs; the line at the bottom says where you are."
      ""
      "## Moving"
      ""
      "- `j` `Down`: a line down; `k` `Up`: a line up"
      "- `Space` `PgDn`: a page down; `b` `PgUp`: a page up"
      "- `g` `Home`: the top; `G` `End`: the bottom"
      "- `Tab`: the next of folders, list and preview"
      "- `F`: hide or show the folders"
      ""
      "## Messages"
      ""
      "- `Enter` on a folder: its messages"
      "- `Enter` on a message: open it in a tab, and mark it seen"
      "- `J`: the next message; `K`: the previous one"
      "- `Space` in the list: the preview a page on, then the next message"
      ""
      "A message is marked seen only when it is opened: the preview leaves it as it is."
      ""
      "## Tabs"
      ""
      "- `]`: the next tab; `[`: the previous one"
      "- `1` to `9`: that tab"
      "- `x`: close this tab (the first, the folders, stays)"
      ""
      "## Else"
      ""
      "- `?` `F1`: these keys"
      "- `Ctrl-L`: draw the screen again"
      "- `q` `Ctrl-C`: quit")))

(provide mail-client/help client-help)
