# MRS NIX Workspace

## Installing NIX

## AutoActivation of the shell

```
direnv allow
```

```
direnv deny
```

```
direnv reload
```

## Running GUI Apps

Put
```
export NIXPKGS_ALLOW_UNFREE=1
```
to your .zshrc or .bashrc.

## Upgrading ZSH prompt

Put the following code to your .zshrc.
```bash
# Function to dynamically update the prompt if inside a devenv
set_nix_prompt() {
    # Check if we are in the environment and the prompt doesn't already have the tag
    if [[ -n "$DEVENV_ROOT" ]] && [[ "$PROMPT" != *"[${DEVENV_ROOT##*/}]"* ]]; then
        # Save the original prompt so we can restore it later
        export ORIGINAL_PROMPT="$PROMPT"
        export PROMPT="[${DEVENV_ROOT##*/}]$PROMPT"
    elif [[ -z "$DEVENV_ROOT" ]] && [[ -n "$ORIGINAL_PROMPT" ]]; then
        # We left the directory, restore the standard prompt
        export PROMPT="$ORIGINAL_PROMPT"
        unset ORIGINAL_PROMPT
    fi
}

# Attach the function to the precmd hook (runs right before the prompt is drawn)
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_nix_prompt
```
