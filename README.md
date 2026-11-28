# x-mail

A mail client for [x-lang](https://github.com/jonruttan/x-lang), written in x,
on the `mail` library ([x-lib-mail](https://github.com/jonruttan/x-lib-mail)).

x-mail holds the bundle `mail-client`. It reads a local Maildir in three panes:
the folders on the left, and on the right the folder's messages, newest first,
over the selected message. A message opened has a tab of its own. This first
version reads mail; it does not write, send or fetch it.

```sh
x -l mail-client -- ~/Maildir
```

The Maildir is the operand, else `$MAILDIR`, else `~/Maildir`. A path that is
not a Maildir (no `cur`, `new` and `tmp` in it) is reported and nothing is
made. Folders are Maildir++ dot folders.

## Keys

| Keys | |
|---|---|
| `j` `Down`, `k` `Up` | a line down, up, in the focused pane |
| `Space` `PgDn`, `b` `PgUp` | a page down, up |
| `g` `Home`, `G` `End` | the top, the bottom |
| `Tab` | the next of folders, list and preview |
| `F` | hide or show the folders |
| `Enter` | on a folder, its messages; on a message, open it in a tab |
| `J`, `K` | the next, the previous message |
| `Space` in the list | the preview a page on, then the next message |
| `]`, `[`, `1`-`9` | the next, the previous, that tab |
| `x` | close the tab (the folder view stays) |
| `?` | these keys |
| `Ctrl-L` | draw the screen again |
| `q` `Ctrl-C` | quit |

A message is marked seen when it is opened. The preview leaves it as it is.

## Using it

Installed under x's `bundles/` directory, with x-lib-mail installed the same
way:

```sh
make install
```

## Working on it

```sh
make check
make card
```

[docs/card.md](docs/card.md) is the card: the options, the panes and the keys
in tables, and the rows `make card` runs.

## Licence

MIT No Attribution.
