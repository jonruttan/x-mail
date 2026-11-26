; # x-mail -- a mail client on x-lang
;
; ## lib/mail-client/cli.x -- the command line, and the terminal
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
;   x -l mail-client -- [MAILDIR]
;
; The Maildir is the operand, else $MAILDIR, else ~/Maildir.  One that is
; not a Maildir (no cur, new and tmp in it) is reported, and nothing is made.
; The client takes the terminal: raw, on the alternate screen, the cursor
; hidden, given back as it was on the way out.  The size is asked again
; whenever no key comes for a quarter of a second.
(module mail-client/cli)

(import x/type/vector)
(import x/sys/posix)
(import x/sys/gc)
(import x/sys/file)
(import x/sys/opts)
(import x/repl/term)
(import x/tui/screen)
(import mail-client/client client-make client-key! client-resize! client-draw! client-quit? client-repaint?)

(def client-version "0.1.0")

(def client-options
  (Opts declare "x -l mail-client --" "[OPTIONS] [MAILDIR]"
    "A mail client on a Maildir: the folders, the messages, the message.\nThe Maildir is MAILDIR, else $MAILDIR, else ~/Maildir.  In the client, ? shows the keys."
    (list (Opts flag "-V" "--version" "Print the version and exit")
          (Opts flag "-h" "--help" "Print this help and exit"))
    (pair (lit help) #f)))

(def %say (fn (_ fd text) (Sys fd-write fd text)))

(def %env (fn (_ name) (guard (_ ()) (let ((v (Sys getenv name))) (if (if (str? v) (not (str=? v "")) #f) v ())))))

; The Maildir to open: OPERANDS' first, else $MAILDIR, else ~/Maildir.
(def client-root
  (fn (_ operands)
    (match
      ((not (null? operands)) (first operands))
      ((not (null? (%env "MAILDIR"))) (%env "MAILDIR"))
      ((not (null? (%env "HOME"))) (Str8 append (%env "HOME") "/Maildir"))
      (#t "Maildir"))))

(def %dir? (fn (_ path) (eq? (guard (_ ()) (File type path)) (lit dir))))

; Whether PATH is a Maildir: a directory with cur, new and tmp in it.
(def client-maildir?
  (fn (_ path) (List all? (fn (_ d) (%dir? (Str8 append path "/" d))) (list "" "cur" "new" "tmp"))))

(def %err-text (fn (_ e) (match ((Err err? e) (Err text e)) ((str? e) e) (#t "error"))))

; --- the terminal ---

; A byte reader over standard input, as (Term key) takes one, its bytes
; read 64 at a time: (reader) answers a byte or nil at the end, (reader #t)
; whether bytes read are not yet taken.
(def %reader
  (fn (_)
    (def box (Vector of ()))
    (fn (self . ask)
      (if (null? ask)
        (do (when (null? (Vector ref 0 box)) (Vector set! 0 (Sys fd-read 0 64) box))
            (if (null? (Vector ref 0 box)) ()
              ((fn (_ b) (Vector set! 0 (rest (Vector ref 0 box)) box) b) (first (Vector ref 0 box)))))
        (not (null? (Vector ref 0 box)))))))

(def %esc (fn (_ text) (Str8 append "\x1b" text)))

(def %show!
  (fn (_ c screen)
    (when (client-repaint? c) (Screen repaint screen))
    (client-draw! c screen)
    (Term emit 1 (Screen render screen))))

; The next key, the screen kept the terminal's size while it waits.
(def %key
  (fn (self c screen reader)
    (if (reader #t) (Term key reader)
      (if (null? (Sys poll (list (pair 0 (list (lit in)))) 250))
        (do (let ((size (Term window 0)))
              (unless (if (= (first size) (Screen cols screen)) (= (rest size) (Screen rows screen)) #f)
                (do (Screen resize screen (rest size) (first size))
                    (client-resize! c (rest size) (first size))
                    (%show! c screen))))
            (self c screen reader))
        (Term key reader)))))

(def %loop
  (fn (self c screen reader)
    (%show! c screen)
    (unless (client-quit? c)
      (let ((key (%key c screen reader)))
        (unless (null? key)
          (do (client-key! c key)
              (Heap collect)
              (self c screen reader)))))))

(def %run
  (fn (_ root)
    ; x.sh parks the user's terminal on fd 3 while the boot stream holds
    ; fd 0; it is taken back, as x-browse takes it.
    (guard (_ ()) (when (Sys isatty 3) (do (Sys dup2 3 0) (Sys close 3))))
    (if (not (if (Term tty? 0) (Sys isatty 1) #f))
      (do (%say 2 "mail-client: not a terminal\n") 1)
      (do
        (def size (Term window 0))
        (def c (client-make (rest size) (first size) root))
        (def screen (Screen make (rest size) (first size)))
        (def token (Term raw! 0))
        (Term emit 1 (Str8 append (%esc "[?1049h") (%esc "[?25l")))
        (def failed (guard (e e) (do (%loop c screen (%reader)) ())))
        (Term emit 1 (Str8 append (%esc "[0m") (%esc "[?25h") (%esc "[?1049l")))
        (Term restore! 0 token)
        (if (null? failed) 0
          (do (%say 2 (Str8 append "mail-client: " (%err-text failed) "\n")) 1))))))

; ARGS, the command line after the launcher's options: the exit status.
(def client-main
  (fn (_ args)
    (def opts (Opts parse client-options args))
    (def root (client-root (Opts operands opts)))
    (match
      ((not (null? (Opts unknown opts)))
        (do (%say 2 (Str8 append "mail-client: no such option: " (Opts unknown opts) "\n" (Opts usage client-options))) 2))
      ((Opts on? opts "-h") (do (%say 1 (Opts usage client-options)) 0))
      ((Opts on? opts "-V") (do (%say 1 (Str8 append "mail-client " client-version "\n")) 0))
      ((not (client-maildir? root)) (do (%say 2 (Str8 append "mail-client: not a Maildir: " root "\n")) 1))
      (#t (%run root)))))

(provide mail-client/cli client-main client-options client-version client-root client-maildir?)
