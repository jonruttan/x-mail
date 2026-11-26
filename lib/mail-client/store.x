; # x-mail -- a mail client on x-lang
;
; ## lib/mail-client/store.x -- a Maildir as the client shows it
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; A folder row is (FOLDER UNREAD): the folder as Maildir names it and how many
; of its messages are not seen.  A message row is (ENTRY TIME FROM TO SUBJECT):
; the Maildir entry, the unix time it was sent (its Date field, else the time
; its key begins with), and who it is from and to and its subject as text,
; encoded words decoded.  A folder's rows come newest first.
;
; A message is shown as blocks for x/tui/page: its From, To, Date and Subject,
; then its body: the first text/plain part, else the first text/html part as
; x/codec/html reads it, then the file names of its attachments.
(module mail-client/store)

(import x/core/doors int* int+ int- int/ int< int=)
(import x/sys/date)
(import x/codec/html)
(import mail/message)
(import mail/mime)
(import mail/maildir)

(def %to-int-prim (prim-ref (lit convert) (lit to)))
(def %integer (Type named INTEGER))
(def %to-int (fn (_ s) (guard (_ ()) (%to-int-prim s %integer 10))))

(def %unread? (fn (_ entry) (not (List any? (fn (_ f) (eq? f (lit seen))) (List ref 2 entry)))))

(def store-folders
  (fn (_ root)
    (List map
      (fn (_ folder)
        (list folder (List length (List filter %unread? (Maildir messages root folder)))))
      (Maildir folders root))))

; --- Dates ---

(def %months (list "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))

(def %month-of
  (fn (_ name)
    (let go ((l %months) (k 1))
      (match
        ((null? l) ())
        ((Str8 ci=? (first l) name) k)
        (#t (go (rest l) (int+ k 1)))))))

(def %words (fn (_ s) (List filter (fn (_ w) (not (str=? w ""))) (Str8 split " " s))))

; "+hhmm" or "-hhmm" as seconds east of UTC; anything else, 0.
(def %zone
  (fn (_ z)
    (def n (if (int= (Str8 length z) 5) (%to-int (Str8 sub 1 4 z)) ()))
    (match
      ((null? n) 0)
      (#t (let ((secs (int+ (int* (int/ n 100) 3600) (int* (int- n (int* (int/ n 100) 100)) 60))))
            (if (str=? (Str8 sub 0 1 z) "-") (int- 0 secs) secs))))))

; An RFC 5322 date, "Tue, 25 Nov 2026 14:05:00 -0500", as unix time, or nil.
(def store-date
  (fn (_ text)
    (def comma (Str8 index-of "," text))
    (def w (%words (if (null? comma) text (Str8 sub (int+ comma 1) (int- (Str8 length text) (int+ comma 1)) text))))
    (match
      ((int< (List length w) 4) ())
      (#t
        (let ((day (%to-int (List ref 0 w))) (month (%month-of (List ref 1 w))) (year (%to-int (List ref 2 w)))
              (hms (List map %to-int (Str8 split ":" (List ref 3 w))))
              (zone (if (int< 4 (List length w)) (%zone (List ref 4 w)) 0)))
          (match
            ((if (null? day) #t (if (null? month) #t (null? year))) ())
            ((if (int< (List length hms) 2) #t (List any? null? hms)) ())
            (#t (int- (Date to-unix (list (pair (lit year) year) (pair (lit month) month) (pair (lit day) day)
                                           (pair (lit hour) (first hms)) (pair (lit minute) (List ref 1 hms))
                                           (pair (lit second) (if (int< 2 (List length hms)) (List ref 2 hms) 0))))
                      zone))))))))

(def %two (fn (_ n) (if (int< n 10) (Str8 str "0" n) (Str8 str n))))

; TIME as a list shows it: "14:05" on NOW's day, else "25 Nov", in local time.
(def store-when
  (fn (_ time now)
    (def t (Date local time))
    (def d (Date local now))
    (def same (fn (_ k) (int= (Assoc get k t) (Assoc get k d))))
    (if (if (same (lit year)) (if (same (lit month)) (same (lit day)) #f) #f)
      (Str8 str (%two (Assoc get (lit hour) t)) ":" (%two (Assoc get (lit minute) t)))
      (Str8 str (%two (Assoc get (lit day) t)) " " (List ref (int- (Assoc get (lit month) t) 1) %months)))))

; --- Message rows ---

; The first address of a field as text: its display name, else the address.
(def %person
  (fn (_ value)
    (def all (if (null? value) () (Message addresses value)))
    (match
      ((null? all) "")
      ((str=? (first (first all)) "") (rest (first all)))
      (#t (Message decode-words (first (first all)))))))

(def %key-time
  (fn (_ key)
    (def dot (Str8 index-of "." key))
    (def n (if (null? dot) () (%to-int (Str8 sub 0 dot key))))
    (if (null? n) 0 n)))

(def %row
  (fn (_ root folder entry)
    (def m (Message parse (Maildir read root folder entry)))
    (def date (Message field m "Date"))
    (def time (if (null? date) () (store-date date)))
    (def subject (Message field m "Subject"))
    (list entry (if (null? time) (%key-time (first entry)) time)
          (%person (Message field m "From")) (%person (Message field m "To"))
          (if (null? subject) "" (Message decode-words subject)))))

; The folder's message rows, newest first.  Each message is read whole; the
; heap is collected every 50, since x collects only when asked.
(def store-rows
  (fn (_ root folder)
    (def rows
      (let go ((l (Maildir messages root folder)) (k 0) (acc ()))
        (match
          ((null? l) acc)
          ((int= k 50) (do (Heap collect) (go l 0 acc)))
          (#t (go (rest l) (int+ k 1) (pair (%row root folder (first l)) acc))))))
    (List sort (fn (_ a b) (int< (List ref 1 b) (List ref 1 a))) rows)))

; The row with ENTRY in place of its entry.
(def store-with-entry (fn (_ row entry) (pair entry (rest row))))

; --- A message shown ---

; Lists of inlines as one paragraph, a hard break between each two.
(def %lines-block
  (fn (_ lines)
    (list (lit paragraph)
      (rest (List flat-map (fn (_ l) (pair (list (lit hardbreak)) l)) lines)))))

(def %field-inlines
  (fn (_ name value) (list (list (lit strong) (list (Str8 append name ": "))) value)))

(def %field-block (fn (_ name value) (list (lit paragraph) (%field-inlines name value))))

; Fields as one paragraph, a field to a line.
(def %fields-block
  (fn (_ fields) (%lines-block (List map (fn (_ f) (%field-inlines (first f) (rest f))) fields))))

; Text as paragraphs, a paragraph to each run of lines between blank ones, a
; line end kept as a hard break.
(def %text-blocks
  (fn (_ text)
    (def lines (Str8 split "\n" (Str8 replace "\r" "" text)))
    (def para (fn (_ ls) (%lines-block (List map (fn (_ s) (list s)) (List reverse ls)))))
    (let go ((l lines) (cur ()) (acc ()))
      (match
        ((null? l) (List reverse (if (null? cur) acc (pair (para cur) acc))))
        ((str=? (Str8 trim (first l)) "") (go (rest l) () (if (null? cur) acc (pair (para cur) acc))))
        (#t (go (rest l) (pair (first l) cur) acc))))))

; Every leaf part of M, in order: M itself when it is not multipart.
(def %leaves
  (fn (self m)
    (if (Str8 starts? "multipart/" (Mime type m))
      (List flat-map self (guard (_ (list m)) (Mime parts m)))
      (list m))))

(def %find-type (fn (_ parts type) (List find (fn (_ p) (str=? (Mime type p) type)) parts)))

(def %body-blocks
  (fn (_ m)
    (def parts (%leaves m))
    (def plain (%find-type parts "text/plain"))
    (def html (if (null? plain) (%find-type parts "text/html") ()))
    (def files (List filter (fn (_ n) (not (null? n))) (List map (fn (_ p) (Mime filename p)) parts)))
    (List append
      (match
        ((not (null? plain)) (%text-blocks (guard (_ (Message body plain)) (Mime decode plain))))
        ((not (null? html)) (Html parse (guard (_ (Message body html)) (Mime decode html))))
        (#t ()))
      (if (null? files) ()
        (list (%field-block "Attachments" (Str8 join ", " files)))))))

; Field NAME of M as text, its encoded words decoded: "" when M has none.
(def %text-field
  (fn (_ m name)
    (let ((v (Message field m name))) (if (null? v) "" (Message decode-words v)))))

; The message ROW stands for, read from ROOT's FOLDER, as page blocks: the
; fields it has of From, To, Date and Subject, then its body.
(def store-blocks
  (fn (_ root folder row)
    (def m (Message parse (Maildir read root folder (first row))))
    (List append
      (list (%fields-block (List filter (fn (_ f) (not (str=? (rest f) ""))) (List map (fn (_ n) (pair n (%text-field m n))) (list "From" "To" "Date" "Subject")))))
      (%body-blocks m))))

(provide mail-client/store store-folders store-rows store-date store-when store-with-entry store-blocks)
