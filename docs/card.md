# mail-client card

## Run

```sh
x -l mail-client -- MAILDIR               # the client on that Maildir
x -l mail-client --                       # on $MAILDIR, else ~/Maildir
x -l mail-client -- -V -> mail-client 0.1.0
x -l mail-client -- -h | grep -c '^Usage: x -l mail-client --' -> 1
x -l mail-client -- /no 2>&1 | tail -1 -> mail-client: not a Maildir: /no
x -l mail-client -- /nosuch 2>/dev/null; echo $? -> 1
x -l mail-client -- --nope 2>/dev/null; echo $? -> 2
MAILDIR=/n x -l mail-client -- 2>&1 | tail -1 -> mail-client: not a Maildir: /n
```

| Option                 | Is                                               |
|------------------------|--------------------------------------------------|
| `MAILDIR`              | the Maildir: `cur`, `new` and `tmp` in it        |
| `-V` `--version`       | print the version and exit                       |
| `-h` `--help`          | print the help and exit                          |

| Status                 | Is                                               |
|------------------------|--------------------------------------------------|
| `0`                    | quit                                             |
| `1`                    | not a Maildir, not a terminal, or an error       |
| `2`                    | no such option                                   |

## Screen

| Pane                   | Is                                               |
|------------------------|--------------------------------------------------|
| left                   | the folders: Maildir++ dot folders               |
| right, top             | the folder's messages, newest first              |
| right, below           | the selected message                             |
| a tab                  | a message opened                                 |

## Keys

| Key                    | Does                                             |
|------------------------|--------------------------------------------------|
| `j` `Down`, `k` `Up`   | a line down, up, in the focused pane             |
| `Space` `PgDn`         | a page down                                      |
| `b` `PgUp`             | a page up                                        |
| `g` `Home`, `G` `End`  | the top, the bottom                              |
| `Tab`                  | the next of folders, list and preview            |
| `F`                    | hide or show the folders                         |
| `Enter`                | a folder's messages; a message in a tab          |
| `J`, `K`               | the next, the previous message                   |
| `Space` in the list    | the preview a page on, then the next message     |
| `]`, `[`, `1`-`9`      | the next, the previous, that tab                 |
| `x`                    | close the tab; the folder view stays             |
| `?`                    | the keys                                         |
| `Ctrl-L`               | draw the screen again                            |
| `q` `Ctrl-C`           | quit                                             |

| Message                | Is                                               |
|------------------------|--------------------------------------------------|
| opened                 | marked seen                                      |
| in the preview         | left as it is                                    |

## Differs

| From a mail client     | The README's                                     |
|------------------------|--------------------------------------------------|
| writing a message      | not yet                                          |
| sending, fetching      | not yet: a local Maildir only                    |

## More

| Where                  | What                                             |
|------------------------|--------------------------------------------------|
| `README.md`            | install and the keys                             |
| `lib/mail-client/`     | the client, the store, the command line          |
| x-lib-mail             | the `mail` library: messages, MIME, Maildir      |
