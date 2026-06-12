# MRS NIX Workspace

## Installing NIX

https://nixos.org/download/

### Linux

```bash
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

### Enabling experimental features (needed for flakes)

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Trusting binary caches (needed for downloading packages)

echo "substituters = https://cache.nixos.org/ https://ctu-mrs.cachix.org https://ros.cachix.org https://devenv.cachix.org" >> ~/.config/nix/nix.conf
echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ctu-mrs.cachix.org-1:dnw2ixFgGHfTb4bE1MWQTetAUJe9zqKUOBlrTjDuDMI= ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" >> ~/.config/nix/nix.conf

add `trusted-users = root your_user` to `/etc/nix/nix.conf`

Then restart the nix deamon:
```bash
sudo systemctl restart nix-daemon
```

### Running GUI Apps

Put
```
export NIXPKGS_ALLOW_UNFREE=1
```
to your .zshrc or .bashrc.
Then, open new terminal.

Install NixGL:
```bash
nix profile add github:guibou/nixGL --impure
```

## AutoActivation of the shell

### Direnv installation

https://direnv.net/docs/installation.html

### Ubuntu

```bash
sudo apt-get install direnv
```

Enabling direnv in a directory:
```
direnv allow
```

Disabling it:
```
direnv deny
```

Refreshing it:
```
direnv reload
```

Adding shell hook:

- For zshell: add `direnv` into your plugins lits.
- For bash: add `eval "$(direnv hook bash)"` into your .bashrc

## Upgrading ZSH prompt

Put the following code to your .zshrc.
```bash
# Function to dynamically update the prompt if inside a Nix environment
set_nix_prompt() {
    # 1. Determine which shell we are currently running
    local is_zsh=0
    local is_bash=0
    if [[ -n "$ZSH_VERSION" ]]; then
        is_zsh=1
    elif [[ -n "$BASH_VERSION" ]]; then
        is_bash=1
    fi

    # 2. Identify the environment name (if the variable is set)
    local env_name=""
    if [[ -n "$NIX_ENV_ROOT" ]]; then
        env_name="${NIX_ENV_ROOT##*/}"
    fi

    if [[ -n "$env_name" ]]; then
        # IN ENVIRONMENT: Prepend the tag if it isn't there already
        if [[ $is_zsh -eq 1 ]] && [[ "$PROMPT" != *"[${env_name}]"* ]]; then
            export ORIGINAL_PROMPT="$PROMPT"
            export PROMPT="[${env_name}] $PROMPT"
        elif [[ $is_bash -eq 1 ]] && [[ "$PS1" != *"[${env_name}]"* ]]; then
            export ORIGINAL_PS1="$PS1"
            export PS1="[${env_name}] $PS1"
        fi
    else
        # OUT OF ENVIRONMENT: Restore the standard prompt if we saved it
        if [[ $is_zsh -eq 1 ]] && [[ -n "$ORIGINAL_PROMPT" ]]; then
            export PROMPT="$ORIGINAL_PROMPT"
            unset ORIGINAL_PROMPT
        elif [[ $is_bash -eq 1 ]] && [[ -n "$ORIGINAL_PS1" ]]; then
            export PS1="$ORIGINAL_PS1"
            unset ORIGINAL_PS1
        fi
    fi
}

# Attach the hook using the correct method for the active shell
if [[ -n "$ZSH_VERSION" ]]; then
    # Zsh approach: precmd hook array
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd set_nix_prompt
elif [[ -n "$BASH_VERSION" ]]; then
    # Bash approach: PROMPT_COMMAND evaluation string
    if [[ "$PROMPT_COMMAND" != *"set_nix_prompt"* ]]; then
        export PROMPT_COMMAND="set_nix_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    fi
fi
```


## Updating the underlying overlays

```
nix develop --refresh --impure --accept-flake-config
```
