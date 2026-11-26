; # x-mail -- a mail client on x-lang
;
; ## lib/mail-client/run.x -- the entry, the module mail-client/run
;
; @description `x -l mail-client -- [OPTIONS] [MAILDIR]`.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; Importing it sets the session up and starts nothing; main opens the
; client.
(module mail-client/run)
(import mail-client/cli client-main)

(set! %lang-name "mail-client")
(set! %repl-prompt "mail-client> ")

; The operands: what follows the "--" after the launcher's own options.
; x-os's launcher passes the engine's own flags ahead of them, with no "--"
; between; they are left out.
(def %engine-flag?
  (fn (_ a) (List any? (fn (_ f) (str=? a f)) (list "--batch" "--quiet" "--no-color"))))
(def %operands
  (fn (self l) (if (if (null? l) #f (%engine-flag? (first l))) (self (rest l)) l)))

(def main
  (fn (_) (Sys exit (client-main (%operands (rest (Sys args (lit program))))))))

(provide mail-client/run main)
