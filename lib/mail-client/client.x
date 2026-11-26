; # x-mail -- a mail client on x-lang
;
; ## lib/mail-client/client.x -- the three panes, the tabs, the keys, the drawing
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; A client holds tabs (x/tui/tabs).  Tab 1 is the folder view and stays open:
; the folder column on the left, and on its right the message list over the
; preview of the selected message.  A message opened has a tab of its own, a
; window (x/tui/window) on its page, as the help does.  One pane of the folder
; view has the focus: its selected row is reversed and the bar beside it is
; bold.
;
; The client takes keys as x/repl/term's (Term key) decodes them and draws on a
; screen (x/tui/screen): the tab bar on the first row, the tab below it, and on
; the last row a message or where the selection is.  Nothing here touches a
; terminal, so a spec drives it with keys and reads the screen back.
;
; Only opening a message writes: it is marked seen.  The preview never is.
(module mail-client/client)

(import x/core/doors int+ int- int/ int< int=)
(import x/type/vector)
(import x/tui/width text-width)
(import x/tui/style)
(import x/tui/screen)
(import x/tui/page)
(import x/tui/window)
(import x/tui/tabs)
(import x/codec/markdown)
(import mail/maildir)
(import mail-client/store store-folders store-rows store-when store-with-entry store-blocks)
(import mail-client/help client-help)

; A client is a vector: 0 the tabs, 1 rows, 2 columns, 3 the Maildir root,
; 4 the folder rows, 5 the folder cursor, 6 the open folder's index, 7 its
; message rows, 8 the selected message, 9 the list's top row, 10 the focus
; (folders, list or preview), 11 whether the folder column shows, 12 the
; preview's window or nil, 13 the message shown, 14 whether to quit, 15
; whether the screen is to be drawn whole, 16 the time "today" is read from.
(def %get (fn (_ c k) (Vector ref k c)))
(def %put! (fn (_ c k x) (Vector set! k x c)))
(def %min (fn (_ a b) (if (int< a b) a b)))
(def %max (fn (_ a b) (if (int< a b) b a)))
(def %clamp (fn (_ x lo hi) (%max lo (%min x hi))))

(def %tabs (fn (_ c) (%get c 0)))
(def %rows (fn (_ c) (%get c 1)))
(def %cols (fn (_ c) (%get c 2)))
(def %root (fn (_ c) (%get c 3)))
(def %folders (fn (_ c) (%get c 4)))
(def %msgs (fn (_ c) (%get c 7)))
(def %focus (fn (_ c) (%get c 10)))
(def %say! (fn (_ c text) (%put! c 13 text)))
(def %folder-view? (fn (_ c) (int= (Tabs index (%tabs c)) 0)))

; --- Layout ---

(def %body-rows (fn (_ c) (%max 1 (int- (%rows c) 2))))
(def %side (fn (_ c) (if (%get c 11) (%min 20 (int/ (%cols c) 3)) 0)))
; The column the list and preview start at: after the side and its bar.
(def %x0 (fn (_ c) (if (%get c 11) (int+ (%side c) 1) 0)))
(def %width (fn (_ c) (%max 1 (int- (%cols c) (%x0 c)))))
(def %list-rows (fn (_ c) (%max 1 (int/ (%body-rows c) 3))))
(def %rule-row (fn (_ c) (int+ 1 (%list-rows c))))
(def %preview-row (fn (_ c) (int+ 2 (%list-rows c))))
(def %preview-rows (fn (_ c) (%max 1 (int- (%body-rows c) (int+ 1 (%list-rows c))))))

; --- Folders ---

(def %open-folder (fn (_ c) (first (List ref (%get c 6) (%folders c)))))

(def %sent? (fn (_ folder) (List any? (fn (_ n) (Str8 ci=? (first folder) n)) (list "Sent" "Sent Messages" "Sent Items" "Drafts"))))

; Open folder K: its rows read, the newest selected.
(def %open!
  (fn (_ c k)
    (%put! c 6 k)
    (%put! c 7 (store-rows (%root c) (first (List ref k (%folders c)))))
    (%put! c 8 0)
    (%put! c 9 0)
    (%put! c 12 ())
    (Window retitle (Tabs window (%tabs c) 0) (%folder-title (first (List ref k (%folders c)))))))

(def %folder-title (fn (_ folder) (List last folder)))

; --- The preview ---

(def %row (fn (_ c) (if (null? (%msgs c)) () (List ref (%get c 8) (%msgs c)))))

(def %page-of (fn (_ c row width) (Page markdown (store-blocks (%root c) (%open-folder c) row) width)))

; The preview's window, laid out for the selected message the first time it
; is asked for.
(def %preview
  (fn (_ c)
    (def row (%row c))
    (match
      ((null? row) ())
      ((not (null? (%get c 12))) (%get c 12))
      (#t (do (%put! c 12 (Window make "" (guard (e (Page text (Str8 append "cannot read this message: " (%err-text e)) (%width c)))
                                                    (%page-of c row (%width c)))))
              (%get c 12))))))

(def %err-text (fn (_ e) (match ((Err err? e) (Err text e)) ((str? e) e) (#t "error"))))

; --- Moving ---

; Select message K, kept in the list's rows; the preview starts again.
(def %select!
  (fn (_ c k)
    (def n (List length (%msgs c)))
    (unless (int= n 0)
      (do (def j (%clamp k 0 (int- n 1)))
          (unless (int= j (%get c 8)) (%put! c 12 ()))
          (%put! c 8 j)
          (%put! c 9 (%clamp (%get c 9) (int- j (int- (%list-rows c) 1)) j))))))

(def %folder-cursor! (fn (_ c k) (%put! c 5 (%clamp k 0 (int- (List length (%folders c)) 1)))))

(def %scroll-preview!
  (fn (_ c n)
    (def w (%preview c))
    (unless (null? w) (Window scroll w n (%preview-rows c)))))

; Space in the list: the preview a page on, the next message at its end.
(def %space!
  (fn (_ c)
    (def w (%preview c))
    (match
      ((null? w) ())
      ((int< (int+ (Window top w) (%preview-rows c)) (Page count (Window page w))) (%scroll-preview! c (%preview-rows c)))
      (#t (%select! c (int+ (%get c 8) 1))))))

; N lines in the focused pane: down when positive.
(def %move!
  (fn (_ c n)
    (match
      ((eq? (%focus c) (lit folders)) (%folder-cursor! c (int+ (%get c 5) n)))
      ((eq? (%focus c) (lit list)) (%select! c (int+ (%get c 8) n)))
      (#t (%scroll-preview! c n)))))

(def %page-rows
  (fn (_ c)
    (match
      ((eq? (%focus c) (lit list)) (%list-rows c))
      ((eq? (%focus c) (lit preview)) (%preview-rows c))
      (#t (%body-rows c)))))

(def %ends!
  (fn (_ c last?)
    (match
      ((eq? (%focus c) (lit folders)) (%folder-cursor! c (if last? (List length (%folders c)) 0)))
      ((eq? (%focus c) (lit list)) (%select! c (if last? (List length (%msgs c)) 0)))
      (#t (let ((w (%preview c)))
            (unless (null? w) (Window go w (if last? (Page count (Window page w)) 0) (%preview-rows c))))))))

(def %next-pane!
  (fn (_ c)
    (%put! c 10
      (match
        ((eq? (%focus c) (lit folders)) (lit list))
        ((eq? (%focus c) (lit list)) (lit preview))
        ((%get c 11) (lit folders))
        (#t (lit list))))))

(def %toggle-side!
  (fn (_ c)
    (%put! c 11 (not (%get c 11)))
    (%put! c 12 ())
    (when (if (eq? (%focus c) (lit folders)) (not (%get c 11)) #f) (%put! c 10 (lit list)))))

; --- Opening ---

(def %mark-seen!
  (fn (_ c row)
    (def entry (first row))
    (match
      ((List any? (fn (_ f) (eq? f (lit seen))) (List ref 2 entry)) row)
      (#t (let ((new (Maildir flag! (%root c) (%open-folder c) entry (pair (lit seen) (List ref 2 entry)))))
            (do (%put! c 7 (List map (fn (_ r) (if (str=? (first (first r)) (first entry)) (store-with-entry r new) r)) (%msgs c)))
                (%put! c 4 (List map (fn (_ f) (if (equal? (first f) (%open-folder c)) (list (first f) (%max 0 (int- (List ref 1 f) 1))) f))
                                     (%folders c)))
                (store-with-entry row new)))))))

; The selected message in a tab of its own, marked seen.
(def %open-message!
  (fn (_ c)
    (def row (%row c))
    (if (null? row) ()
      (guard (e (%say! c (Str8 append "cannot open this message: " (%err-text e))))
        (%tab-of! c (%mark-seen! c row))))))

(def %tab-of!
  (fn (_ c row)
    (def title (%subject-title row))
    (Tabs add (%tabs c) (Window make title (%page-of c row (%cols c))))))

(def %subject-title (fn (_ row) (if (str=? (List ref 4 row) "") "(no subject)" (List ref 4 row))))

(def %enter!
  (fn (_ c)
    (match
      ((not (%folder-view? c)) ())
      ((eq? (%focus c) (lit folders)) (do (%open! c (%get c 5)) (%put! c 10 (lit list))))
      (#t (%open-message! c)))))

(def %help!
  (fn (_ c) (Tabs add (%tabs c) (Window make "Keys" (Page markdown (Markdown parse client-help) (%cols c))))))

(def %close!
  (fn (_ c)
    (if (%folder-view? c) (%say! c "the folder view stays open")
      (Tabs close (%tabs c) (Tabs index (%tabs c))))))

; --- Keys ---

(def %key? (fn (_ key names) (List any? (fn (_ n) (if (str? n) (if (str? key) (str=? key n) #f) (eq? key n))) names)))

; In a message's tab: the window scrolled.
(def %tab-key!
  (fn (_ c key)
    (def w (Tabs current (%tabs c)))
    (def n (%body-rows c))
    (match
      ((%key? key (list "j" (lit down))) (Window scroll w 1 n))
      ((%key? key (list "k" (lit up))) (Window scroll w -1 n))
      ((%key? key (list " " (lit page-down))) (Window scroll w n n))
      ((%key? key (list "b" (lit page-up))) (Window scroll w (int- 0 n) n))
      ((%key? key (list "g" (lit home))) (Window go w 0 n))
      ((%key? key (list "G" (lit end))) (Window go w (Page count (Window page w)) n))
      (#t ()))))

(def %view-key!
  (fn (_ c key)
    (match
      ((%key? key (list "j" (lit down))) (%move! c 1))
      ((%key? key (list "k" (lit up))) (%move! c -1))
      ((%key? key (list " "))
        (if (eq? (%focus c) (lit list)) (%space! c) (%move! c (%page-rows c))))
      ((%key? key (list (lit page-down))) (%move! c (%page-rows c)))
      ((%key? key (list "b" (lit page-up))) (%move! c (int- 0 (%page-rows c))))
      ((%key? key (list "g" (lit home))) (%ends! c #f))
      ((%key? key (list "G" (lit end))) (%ends! c #t))
      ((%key? key (list (lit complete))) (%next-pane! c))
      ((%key? key (list "F")) (%toggle-side! c))
      ((%key? key (list "J")) (%select! c (int+ (%get c 8) 1)))
      ((%key? key (list "K")) (%select! c (int- (%get c 8) 1)))
      (#t ()))))

(def client-key!
  (fn (_ c key)
    (%say! c ())
    (match
      ((%key? key (list "q" (lit interrupt))) (%put! c 14 #t))
      ((%key? key (list (lit enter))) (%enter! c))
      ((%key? key (list "]" ">")) (Tabs next (%tabs c)))
      ((%key? key (list "[" "<")) (Tabs prev (%tabs c)))
      ((%key? key (list "1" "2" "3" "4" "5" "6" "7" "8" "9"))
        (Tabs select (%tabs c) (int- (Char ->int (Str8 ref 0 key)) 49)))
      ((%key? key (list "x")) (%close! c))
      ((%key? key (list "?" (lit f1))) (%help! c))
      ((%key? key (list (lit clear))) (%put! c 15 #t))
      ((%folder-view? c) (%view-key! c key))
      (#t (%tab-key! c key)))
    c))

; --- Making one ---

; A ROWS by COLS client on the Maildir at ROOT, INBOX open; NOW, unix time,
; says which day is today (the clock's when not given).
(def client-make
  (fn (_ rows cols root . now)
    (def c (Vector make 17 ()))
    (%put! c 0 (Tabs make))
    (%put! c 1 rows)
    (%put! c 2 cols)
    (%put! c 3 root)
    (%put! c 4 (store-folders root))
    (%put! c 5 0)
    (%put! c 10 (lit list))
    (%put! c 11 #t)
    (%put! c 14 #f)
    (%put! c 15 #f)
    (%put! c 16 (if (null? now) (Sys now) (first now)))
    (Tabs add (%tabs c) (Window make "" (Page text "" cols)))
    (unless (null? (%folders c)) (%open! c 0))
    c))

(def client-resize!
  (fn (_ c rows cols)
    (%put! c 1 rows)
    (%put! c 2 cols)
    (%put! c 12 ())
    (%select! c (%get c 8))
    c))

(def client-quit? (fn (_ c) (%get c 14)))
(def client-message (fn (_ c) (%get c 13)))

; Whether the whole screen is to be drawn again, asked once.
(def client-repaint?
  (fn (_ c)
    (def r (%get c 15))
    (%put! c 15 #f)
    r))

; --- Drawing ---

(def %bold (Style make (lit (bold)) () ()))
(def %reverse (Style make (lit (reverse)) () ()))
(def %bold-reverse (Style make (lit (bold reverse)) () ()))
(def %dim (Style make (lit (dim)) () ()))

; The bytes of S that fit in W columns.
(def %cut
  (fn (_ s w)
    (let go ((n (Str8 length s)))
      (match
        ((int< w 1) "")
        ((int< (text-width (Str8 sub 0 n s)) (int+ w 1)) (Str8 sub 0 n s))
        (#t (go (int- n 1)))))))

; S cut to W columns and padded with spaces to them.
(def %pad
  (fn (_ s w)
    (def t (%cut s w))
    (Str8 append t (Str8 repeat (%max 0 (int- w (text-width t))) " "))))

; Folder row F's line, W wide, its unread count at the right.  A folder under
; one listed is indented by its depth and shows its last name; one whose parent
; is not listed shows its names joined by "/".
(def %folder-line
  (fn (_ f w folders)
    (def folder (first f))
    (def count (if (int= (List ref 1 f) 0) "" (Str8 str (List ref 1 f))))
    (def parent (List take (int- (List length folder) 1) folder))
    (def name
      (match
        ((null? parent) (first folder))
        ((List any? (fn (_ g) (equal? (first g) parent)) folders)
          (Str8 append (Str8 repeat (List length parent) "  ") (List last folder)))
        (#t (Str8 join "/" folder))))
    (pair (%pad name (%max 0 (int- w (int+ 1 (Str8 length count))))) count)))

(def %draw-folders!
  (fn (_ c screen)
    (def w (%side c))
    (def n (%body-rows c))
    (def top (%max 0 (int- (%get c 5) (int- n 1))))
    (def focused? (eq? (%focus c) (lit folders)))
    (List for-each
      (fn (_ i)
        (def k (int+ top i))
        (def f (if (int< k (List length (%folders c))) (List ref k (%folders c)) ()))
        (Screen fill screen (int+ 1 i) 0 w 0)
        (unless (null? f)
          (do (def line (%folder-line f w (%folders c)))
              (def cursor? (if focused? (int= k (%get c 5)) #f))
              (def open? (int= k (%get c 6)))
              (Screen put screen (int+ 1 i) 0 (Str8 append " " (first line))
                      (match ((if cursor? open? #f) %bold-reverse) (cursor? %reverse) (open? %bold) (#t 0)))
              (Screen put screen (int+ 1 i) (int- w (Str8 length (rest line))) (rest line)
                      (if cursor? %bold-reverse %bold)))))
      (List range 0 n))
    (List for-each
      (fn (_ i)
        (def r (int+ 1 i))
        (def bold? (match ((eq? (%focus c) (lit folders)) #t)
                          ((eq? (%focus c) (lit list)) (int< r (%rule-row c)))
                          (#t (int< (%rule-row c) r))))
        (Screen put screen r w (if (int= r (%rule-row c)) "\xe2\x94\x9c" "\xe2\x94\x82") (if bold? %bold %dim)))
      (List range 0 n))))

; A message row as the list shows it, W wide.
(def %list-line
  (fn (_ c row w)
    (def sender-w (%min 20 (%max 6 (int/ w 4))))
    (def who (if (%sent? (%open-folder c)) (List ref 3 row) (List ref 2 row)))
    (def unread? (not (List any? (fn (_ f) (eq? f (lit seen))) (List ref 2 (first row)))))
    (%cut (Str8 append (if unread? "\xe2\x97\x8f " "  ") (%pad (store-when (List ref 1 row) (%get c 16)) 6) " "
                       (%pad who sender-w) " " (List ref 4 row))
          w)))

(def %draw-list!
  (fn (_ c screen)
    (def x (%x0 c))
    (def w (%width c))
    (def focused? (eq? (%focus c) (lit list)))
    (List for-each
      (fn (_ i)
        (def k (int+ (%get c 9) i))
        (def row (if (int< k (List length (%msgs c))) (List ref k (%msgs c)) ()))
        (Screen fill screen (int+ 1 i) x w 0)
        (unless (null? row)
          (Screen put screen (int+ 1 i) x (%pad (%list-line c row w) w)
                  (match ((not (int= k (%get c 8))) 0) (focused? %reverse) (#t %bold)))))
      (List range 0 (%list-rows c)))
    (Screen put screen (%rule-row c) x (Str8 repeat w "\xe2\x94\x80") (if (eq? (%focus c) (lit folders)) %dim %bold))
    (when (null? (%msgs c)) (Screen put screen 1 (int+ x 2) "No messages" %dim))))

; The runs of page line I on SCREEN's ROW from column X.
(def %put-runs!
  (fn (_ screen row x runs)
    (List fold (fn (_ col r) (Screen put screen row col (first r) (List ref 1 r))) x runs)))

(def %draw-preview!
  (fn (_ c screen)
    (def x (%x0 c))
    (def w (%preview c))
    (List for-each
      (fn (_ i)
        (def r (int+ (%preview-row c) i))
        (Screen fill screen r x (%width c) 0)
        (unless (null? w)
          (let ((line (int+ (Window top w) i)))
            (when (int< line (Page count (Window page w)))
              (%put-runs! screen r x (Page line (Window page w) line))))))
      (List range 0 (%preview-rows c)))))

(def %status
  (fn (_ c)
    (match
      ((not (null? (%get c 13))) (%get c 13))
      ((not (%folder-view? c)) "")
      ((null? (%folders c)) "No folders: this is not a Maildir with mail in it")
      (#t (let ((n (List length (%msgs c)))
                (unread (List length (List filter (fn (_ r) (not (List any? (fn (_ f) (eq? f (lit seen))) (List ref 2 (first r))))) (%msgs c)))))
            (Str8 str (Str8 join "/" (%open-folder c)) ": " n (if (int= n 1) " message, " " messages, ") unread " unread"))))))

(def %draw-status!
  (fn (_ c screen)
    (def row (int- (%rows c) 1))
    (def right (if (if (%folder-view? c) (not (null? (%msgs c))) #f)
                 (Str8 str (int+ 1 (%get c 8)) "/" (List length (%msgs c))) ""))
    (Screen fill screen row 0 (%cols c) 0)
    (Screen put screen row 0 (%cut (%status c) (int- (%cols c) (int+ 1 (Str8 length right)))) (if (null? (%get c 13)) 0 %bold))
    (Screen put screen row (int- (%cols c) (Str8 length right)) right 0)))

(def client-draw!
  (fn (_ c screen)
    (match
      ((%folder-view? c)
        (do (Tabs draw-bar (%tabs c) screen 0)
            (when (%get c 11) (%draw-folders! c screen))
            (%draw-list! c screen)
            (%draw-preview! c screen)))
      (#t (Tabs draw (%tabs c) screen 0 (int- (%rows c) 1))))
    (%draw-status! c screen)
    screen))

(provide mail-client/client client-make client-key! client-resize! client-draw! client-quit? client-repaint? client-message)
