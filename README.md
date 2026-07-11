dotfiles
========

## What this is for

This repo centralizes my configuration files (dotfiles) and automates their
installation as symlinks, instead of copy-pasting them by hand on every
machine.

## How it works

- Each application lives in its own subfolder, at the root of the repo
  (max depth 2).
- The config file to install is named `<target-name>.symlink`
  (e.g. `vim/vimrc.symlink` maps to `~/.vimrc`).
- The `manage-symlinks.sh` script walks all `*.symlink` files and
  creates (or removes) the matching symlink in `$HOME`, as
  `~/.<target-name>` (the `.symlink` extension is stripped).
- A symlink is only created if `~/.<target-name>` doesn't already exist,
  so an existing config on the machine is never overwritten.

## Usage

Install the symlinks:

```
./manage-symlinks.sh -i
```

Remove the symlinks:

```
./manage-symlinks.sh -d
```

## Adding support for a new application

1. Create a subfolder at the root, named after the application
   (e.g. `zsh/`, `ssh/`, `tmux/`).
2. Add the config file in it, renamed to `<target-name>.symlink`
   (e.g. `zshrc.symlink` will be linked as `~/.zshrc`).
3. Commit the file, then run `./manage-symlinks.sh -i` to create
   the symlink.

To drop support for an application: run `-d` (or remove the symlink
manually) then delete the corresponding folder.

See `sample/sample.symlink` as an empty template.
