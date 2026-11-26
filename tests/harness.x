; # x-mail -- a mail client on x-lang
;
; ## tests/harness.x -- what the spec harness adds to the dialect
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; The bundle kit's generator writes tests/lib/harness.gen.x: the dialect
; bundle.xon declares, the bundle's lib/ and the mail library's on the import
; path, then this file.  What is added here is a Maildir under /tmp for a spec
; to fill and remove, and the client driven by keys and read back as text.

(import x/sys/file)
(import x/tui/screen)
(import mail/maildir)
(import mail-client/client client-make client-key! client-draw! client-message)

; A new Maildir: its root, with INBOX made.
(def spec-maildir
  (fn (_)
    (def t (File temp "/tmp/x-mail-"))
    (File close (first t))
    (File unlink (rest t))
    (File mkdir (rest t) 448)
    (Maildir create! (rest t) (list "INBOX"))
    (rest t)))

; A message of these fields and body, as text.
(def spec-message
  (fn (_ fields body)
    (Str8 append (Str8 join "" (List map (fn (_ f) (Str8 append (first f) ": " (rest f) "\r\n")) fields)) "\r\n" body)))

; A message put in FOLDER under KEY, its flags in its name: its entry.
(def spec-put
  (fn (_ root folder key flags text)
    (Maildir create! root folder)
    (def dir (if (null? (rest folder))
               (if (str=? (first folder) "INBOX") root (Str8 append root "/." (first folder)))
               (Str8 append root "/." (Str8 join "." folder))))
    (def name (if (null? flags) (Str8 append dir "/new/" key) (Str8 append dir "/cur/" key ":2," flags)))
    (File write-all name text)
    key))

; Remove PATH and everything under it.
(def spec-rm
  (fn (self path)
    (match
      ((eq? (File ltype path) (lit dir))
        (do (List for-each (fn (_ name) (self (Str8 append path "/" name))) (File list-dir path))
            (File rmdir path)))
      (#t (File unlink path)))))

; A ROWS by COLS client on ROOT at unix time NOW, each of KEYS taken.  The heap
; is collected first: x collects only when asked, and a spec file's cases run
; in one process.
(def spec-client
  (fn (_ rows cols root now keys)
    (Heap collect)
    (def c (client-make rows cols root now))
    (List for-each (fn (_ k) (client-key! c k)) keys)
    c))

; What C draws, row by row, the trailing blanks dropped.
(def spec-screen
  (fn (_ c rows cols)
    (def s (client-draw! c (Screen make rows cols)))
    (List map (fn (_ r) (Str8 trim-right (Screen row-text s r))) (List range 0 rows))))
