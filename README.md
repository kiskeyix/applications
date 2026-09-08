# Applications

Personal dotfiles and configuration management for shell, vim, mutt, and
other tools — deployable to any Unix-like system (Linux, macOS, BSD,
Cygwin) and syncable to remote hosts over SSH.

## Install

```sh
cd ~/
git clone https://github.com/kiskeyix/applications.git Applications
./Applications/scripts/update-host --local
```

`update-host` symlinks the configs into your home directory, e.g.:

```
~/.bashrc        -> Applications/share/shell/bashrc
~/.bash_profile  -> Applications/share/shell/bash_profile
~/.dir_colors    -> Applications/share/shell/dir_colors
~/.inputrc       -> Applications/share/shell/inputrc
```

Any pre-existing files are preserved with a `.bak` extension.

Check whether a machine still matches what `--local` would produce, without
changing anything:

```sh
update-host --verify
```

## Disabling a feature

Remove the corresponding symlink:

```sh
cd ~/
rm .vim   # don't use ~/Applications/share/vim
rm .mutt  # don't use ~/Applications/share/mutt
```

## Local overrides

Make host-specific changes in a separate file rather than editing the
shared configs directly:

```sh
touch ~/.bashrc-`hostname`
touch ~/.vimrc-`hostname`
touch ~/.muttrc-`hostname`
touch ~/.profile-`hostname`
touch ~/.alias.setup
touch ~/.path.setup
```

These are sourced automatically by the corresponding main config file.

## Syncing to remote hosts

```sh
update-host --send-key server1 server2   # one-time: push your SSH pubkey to each host
update-host                              # updates every host in ~/.remote-hosts
update-host server1 server2 ... serverN  # or update just these hosts
```

`--send-key` copies your public key to each remote host's
`~/.ssh/authorized_keys`. `update-host` (no `--local`) builds a tarball of
this repo, ships it to each host over SSH/SCP in parallel (with a live
per-host progress bar), unpacks it under `~/Applications`, and relinks
configs there too.

## Testing

```sh
bundle exec rake test
```

## Contributing

1. Fork the repository on GitHub
2. Create a feature branch
3. Make your changes
4. Open a Pull Request

---
Created: 2007-06-07
