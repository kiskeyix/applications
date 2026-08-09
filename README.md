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
update-host --send-key   # one-time: push your SSH pubkey to hosts in ~/.remote-hosts
update-host --local server1 server2 ... serverN
```

`--send-key` copies your public key to each remote host's
`~/.ssh/authorized_keys`. Subsequent runs use `ssh-agent` so you aren't
re-prompted for passwords/passphrases.

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
