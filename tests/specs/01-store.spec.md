# The store
# @weight 1

mail-client/store: a Maildir's folders with their unread counts, a folder's
messages as rows newest first, dates read and shown, and a message as page
blocks.

## dates

### an RFC 5322 date as unix time, its zone taken off

```x
(import mail-client/store store-date store-when store-rows store-folders store-blocks)
(list (store-date "Tue, 25 Nov 2026 14:05:00 -0500")
      (store-date "25 Nov 2026 19:05:00 +0000")
      (store-date "25 Nov 2026 19:05 GMT")
      (store-date "not a date"))
```
---
    (1795633500 1795633500 1795633500 ())

### a time shown as the list shows it: the hour on today, else the day

```x
(import mail-client/store store-when)
(list (store-when 1795633000 1795633500) (store-when 1795500000 1795633500) (store-when 1767225600 1795633500))
```
---
    ("18:56" "24 Nov" "01 Jan")

## folders and rows

### the folders, INBOX first, with how many messages are not seen

```x
(import mail-client/store store-folders store-rows)
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S" (spec-message (list (pair "Subject" "a")) "a\n"))
(spec-put root (list "INBOX") "1795600000.2.h" () (spec-message (list (pair "Subject" "b")) "b\n"))
(spec-put root (list "INBOX") "1795550000.3.h" "F" (spec-message (list (pair "Subject" "c")) "c\n"))
(spec-put root (list "Archive") "1795000000.4.h" "S" (spec-message (list (pair "Subject" "d")) "d\n"))
(def r (store-folders root))
(spec-rm root)
r
```
---
    ((("INBOX") 2) (("Archive") 0))

### a folder's rows, newest first: the Date field's time, else the key's

```x
(import mail-client/store store-rows)
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "=?UTF-8?Q?Ren=C3=A9e?= <r@example.com>") (pair "To" "me@example.com")
                      (pair "Date" "Wed, 25 Nov 2026 18:40:00 +0000") (pair "Subject" "=?UTF-8?B?Q2Fmw6k=?=")) "a\n"))
(spec-put root (list "INBOX") "1795600000.2.h" () (spec-message (list (pair "From" "b@example.com")) "b\n"))
(def r (List map rest (store-rows root (list "INBOX"))))
(spec-rm root)
r
```
---
    ((1795632000 "Renée" "me@example.com" "Café") (1795600000 "b@example.com" "" ""))

## a message shown

### a multipart message: its fields, its plain part, its attachments named

```x
(import mail-client/store store-rows store-blocks)
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "From" "a@example.com") (pair "To" "b@example.com") (pair "Subject" "Files")
                      (pair "MIME-Version" "1.0") (pair "Content-Type" "multipart/mixed; boundary=\"zz\""))
    (Str8 join "\r\n" (list "--zz" "Content-Type: text/plain" "" "See the file." "Two lines." "" "--zz"
                            "Content-Type: application/pdf; name=\"a.pdf\"" "Content-Disposition: attachment; filename=\"a.pdf\""
                            "Content-Transfer-Encoding: base64" "" "AAAA" "--zz--" ""))))
(def r (store-blocks root (list "INBOX") (first (store-rows root (list "INBOX")))))
(spec-rm root)
r
```
---
    (('paragraph (('strong ("From: ")) "a@example.com" ('hardbreak) ('strong ("To: ")) "b@example.com" ('hardbreak) ('strong ("Subject: ")) "Files")) ('paragraph ("See the file." ('hardbreak) "Two lines.")) ('paragraph (('strong ("Attachments: ")) "a.pdf")))

### an HTML message is read as x/codec/html reads it

```x
(import mail-client/store store-rows store-blocks)
(def root (spec-maildir))
(spec-put root (list "INBOX") "1795500000.1.h" "S"
  (spec-message (list (pair "Subject" "H") (pair "Content-Type" "text/html; charset=utf-8"))
    "<p>Hello <b>you</b></p>"))
(def r (rest (store-blocks root (list "INBOX") (first (store-rows root (list "INBOX"))))))
(spec-rm root)
r
```
---
    (('paragraph ("Hello " ('strong ("you")))))
