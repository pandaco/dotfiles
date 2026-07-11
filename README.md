dotfiles
========

## What this is for

Config files usually live in `$HOME` (`~/.vimrc`, `~/.tmux.conf`...),
un-versioned, and get copy-pasted by hand onto every new machine. This
repo flips that around: the real files live *here*, in the repo, and
`$HOME` just holds a **symlink** — a shortcut — pointing back to them.

```
~/.vimrc  ────(symlink)───▶  <this repo>/vim/vimrc.symlink
```

They're the same file. Edit `~/.vimrc`, and you're editing the tracked
file in the repo directly — `git status` sees the change, `git push`
ships it, and any other machine with this repo cloned gets the update
by re-running one script. One source of truth instead of N out-of-sync
copies.

## Quick start

`~/dotfiles` below is just an example — clone this repo wherever you
want, the script only cares about being run from its own root:

```
git clone <this repo's url> ~/dotfiles
cd ~/dotfiles
./manage-symlinks.sh -i
```

That's it — every config already in the repo is now symlinked into
`$HOME`.

## How it works

Each application gets its own subfolder at the root of the repo (max
depth 2, e.g. `vim/`, `tmux/`). Inside it, whatever you want linked into
`$HOME` is named `<target-name>.symlink`. Running `./manage-symlinks.sh
-i` finds every `*.symlink` path in the repo and links it to
`~/.<target-name>` — the `.symlink` suffix is just dropped.

This works the same whether `<target-name>.symlink` is a **file** or a
whole **directory** — a symlink points at either just as well:

| In the repo               | Kind      | Linked to      |
|----------------------------|-----------|----------------|
| `vim/vimrc.symlink`        | file      | `~/.vimrc`     |
| `vim/vim.symlink/`         | directory | `~/.vim`       |
| `tmux/tmux.conf.symlink`   | file      | `~/.tmux.conf` |

A symlink is only created if `~/.<target-name>` doesn't already exist.
An existing symlink is skipped (and reported) unless `-f/--force` is
passed; a real file or directory already at that path is never
overwritten, even with `--force`.

## Usage

Run these from the root of the repo (where `manage-symlinks.sh` lives):

Install the symlinks:

```
./manage-symlinks.sh -i
```

Remove the symlinks:

```
./manage-symlinks.sh -d
```

Preview what would happen without touching the filesystem, with
`-n/--dry-run`:

```
./manage-symlinks.sh -i -n
```

Overwrite symlinks that already exist, with `-f/--force`:

```
./manage-symlinks.sh -i -f
```

## Adding a new application

Walkthrough: you want to version your `zsh` setup, made of one file
(`~/.zshrc`) and one directory (`~/.oh-my-zsh`).

1. Go to the root of the repo (wherever you cloned it) and create a
   subfolder named after the application:

   ```
   cd ~/dotfiles      # the root of this repo — adjust to where you cloned it
   mkdir zsh
   ```

2. From that same root folder, move your existing config *into* it,
   renaming each one to `<target-name>.symlink`:

   ```
   mv ~/.zshrc zsh/zshrc.symlink
   mv ~/.oh-my-zsh zsh/oh-my-zsh.symlink
   ```

   (`mv` both removes the original from `$HOME` and gives the script
   something to link back — the script won't overwrite a real file, see
   above.)

3. Still from the repo root, commit `zsh/`, then re-create the symlinks
   the `mv` just removed:

   ```
   ./manage-symlinks.sh -i
   ```

   This creates `~/.zshrc -> zsh/zshrc.symlink` and
   `~/.oh-my-zsh -> zsh/oh-my-zsh.symlink`.

On any other machine, cloning this repo and running
`./manage-symlinks.sh -i` from its root reproduces the exact same setup.

To drop support for an application: run `-d` (or remove the symlink
manually), then delete the corresponding folder.

See `sample/sample.symlink` as an empty template.
