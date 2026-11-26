# The command line
# @weight 1

mail-client/cli: which Maildir is opened, and a path that is not one.

## the Maildir

### the operand, else $MAILDIR, else ~/Maildir

```x
(import mail-client/cli client-root)
(list (client-root (list "/m")) (str? (client-root ())))
```
---
    ("/m" #t)

### a Maildir has cur, new and tmp; anything else is not one, and nothing is made

```x
(import x/sys/file)
(import mail-client/cli client-maildir?)
(def root (spec-maildir))
(def r (list (client-maildir? root) (client-maildir? (Str8 append root "/none")) (File type (Str8 append root "/none"))))
(spec-rm root)
r
```
---
    (#t #f ())

### -h prints the help, -V the version, an unknown option the usage

```x
(import mail-client/cli client-main)
(list (client-main (list "-V")) (client-main (list "--nope")) (client-main (list "/no/such/maildir")))
```
---
    (0 2 1)
