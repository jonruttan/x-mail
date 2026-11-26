# The client
# @weight 1

mail-client/client driven by keys, as (Term key) decodes them, on a Maildir
made for the case; what it draws read back a row at a time: the tab bar, the
folders beside the list over the preview, and the status line.  The times are
UTC and "now" is 25 Nov 2026 19:05.

## the first screen

### INBOX open, the newest message selected and previewed

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 ()))
(def r (spec-screen c 14 60))
(spec-rm root)
(write r)
```
---
    (" 1 INBOX" " INBOX             1│● 18:40  bob@examp The build" " Lists/x           1│  24 Nov Ann Lee   Lunch" " Sent               │" "                    │" "                    ├───────────────────────────────────────" "                    │From: bob@example.com" "                    │To: me@example.com" "                    │Date: Wed, 25 Nov 2026 18:40:00 +0000" "                    │Subject: The build" "                    │" "                    │It is green." "                    │" "INBOX: 2 messages, 1 unread                              1/2")

## moving

### j selects the next message and the preview follows it

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 (list "j")))
(def r (spec-screen c 14 60))
(spec-rm root)
(write r)
```
---
    (" 1 INBOX" " INBOX             1│● 18:40  bob@examp The build" " Lists/x           1│  24 Nov Ann Lee   Lunch" " Sent               │" "                    │" "                    ├───────────────────────────────────────" "                    │From: Ann Lee <ann@example.com>" "                    │To: me@example.com" "                    │Date: Mon, 24 Nov 2026 06:20:00 +0000" "                    │Subject: Lunch" "                    │" "                    │Noon at the usual place?" "                    │" "INBOX: 2 messages, 1 unread                              2/2")

### Tab moves the focus to the preview, then the folders; j and Enter there open Sent, which shows who it went to

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 (list 'complete 'complete "j" "j" 'enter)))
(def r (spec-screen c 14 60))
(spec-rm root)
(write r)
```
---
    (" 1 Sent" " INBOX             1│  23 Nov Cy        Hello" " Lists/x           1│" " Sent               │" "                    │" "                    ├───────────────────────────────────────" "                    │From: me@example.com" "                    │To: Cy <cy@example.com>" "                    │Date: Sun, 23 Nov 2026 01:00:00 +0000" "                    │Subject: Hello" "                    │" "                    │Hi." "                    │" "Sent: 1 message, 0 unread                                1/1")

### F hides the folders

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 (list "F")))
(def r (spec-screen c 14 60))
(spec-rm root)
(write r)
```
---
    (" 1 INBOX" "● 18:40  bob@example.com The build" "  24 Nov Ann Lee         Lunch" "" "" "────────────────────────────────────────────────────────────" "From: bob@example.com" "To: me@example.com" "Date: Wed, 25 Nov 2026 18:40:00 +0000" "Subject: The build" "" "It is green." "" "INBOX: 2 messages, 1 unread                              1/2")

## opening

### Enter opens the message in a tab and marks it seen; the preview alone does not

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 (list 'enter)))
(def r (list (spec-screen c 14 60) (Maildir messages root (list "INBOX"))))
(spec-rm root)
(write r)
```
---
    ((" 1 INBOX                       2 The build" "From: bob@example.com" "To: me@example.com" "Date: Wed, 25 Nov 2026 18:40:00 +0000" "Subject: The build" "" "It is green." "" "Bob" "" "" "" "" "") (("1795500000.1.h" #f ('seen)) ("1795633000.2.h" #f ('seen))))

### x closes the tab; the folder view stays

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 (list 'enter "x" "x")))
(def r (list (spec-screen c 14 60) (client-message c)))
(spec-rm root)
(write r)
```
---
    ((" 1 INBOX" " INBOX              │  18:40  bob@examp The build" " Lists/x           1│  24 Nov Ann Lee   Lunch" " Sent               │" "                    │" "                    ├───────────────────────────────────────" "                    │From: bob@example.com" "                    │To: me@example.com" "                    │Date: Wed, 25 Nov 2026 18:40:00 +0000" "                    │Subject: The build" "                    │" "                    │It is green." "                    │" "the folder view stays open                               1/2") "the folder view stays open")

### ? shows the keys

```x
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "Ann Lee <ann@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Mon, 24 Nov 2026 06:20:00 +0000") (pair "Subject" "Lunch"))
                "Noon at the usual place?\n"))
(spec-put root (list "INBOX") "1795633000.2.h" ()
  (spec-message (list (pair "From" "bob@example.com") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "The build"))
                "It is green.\n\nBob\n"))
(spec-put root (list "Sent") "1795400000.3.h" "S"
  (spec-message (list (pair "From" "me@example.com") (pair "To" "Cy <cy@example.com>")
                      (pair "Date" "Sun, 23 Nov 2026 01:00:00 +0000") (pair "Subject" "Hello"))
                "Hi.\n"))
(spec-put root (list "Lists" "x") "1795000000.4.h" () (spec-message (list (pair "Subject" "x")) "x\n"))
(def c (spec-client 14 60 root 1795633500 (list "?")))
(def r (spec-screen c 14 60))
(spec-rm root)
(write r)
```
---
    (" 1 INBOX                       2 Keys" "mail-client" "" "The folders are on the left; on the right, the folder's" "messages, newest first, over the selected one. One of the" "three has the keys: its bar is bold. The bar at the top" "lists the tabs; the line at the bottom says where you are." "" "Moving" "" "• j Down: a line down; k Up: a line up" "• Space PgDn: a page down; b PgUp: a page up" "• g Home: the top; G End: the bottom" "")
