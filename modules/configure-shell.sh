#!/usr/bin/env bash

################################################################################
# Shell Configuration Module
# Configures PATH and aliases for all supported shells
################################################################################

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/modules/common.sh"

configure_bash() {
    log "Configuring Bash..."

    local bash_configs=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    local configured=0

    local path_config='
# Added by Bazzite Dev Setup
export PATH="$HOME/.local/bin:$PATH"
'

    for config in "${bash_configs[@]}"; do
        # Create file if it doesn't exist
        touch "$config" 2>/dev/null || continue

        # Check if already configured
        if grep -q "Added by Bazzite Dev Setup" "$config" 2>/dev/null; then
            log "  $config already configured"
            continue
        fi

        # Add PATH configuration
        echo "$path_config" >> "$config"
        log_success "  Configured $config"
        ((configured++))
    done

    # Also add to /etc/profile.d for system-wide configuration
    local profile_d_config="/etc/profile.d/bazzite-dev-setup.sh"
    if [ -w "/etc/profile.d" ] 2>/dev/null || sudo -n true 2>/dev/null; then
        if [ ! -f "$profile_d_config" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' | sudo tee "$profile_d_config" > /dev/null 2>&1 && \
                log_success "  Configured system-wide profile"
        fi
    fi

    [ $configured -gt 0 ] && return 0 || return 0  # Don't fail if already configured
}

configure_zsh() {
    log "Configuring Zsh..."

    local zsh_configs=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv")
    local configured=0

    local path_config='
# Added by Bazzite Dev Setup
export PATH="$HOME/.local/bin:$PATH"
'

    for config in "${zsh_configs[@]}"; do
        # Create file if it doesn't exist
        touch "$config" 2>/dev/null || continue

        # Check if already configured
        if grep -q "Added by Bazzite Dev Setup" "$config" 2>/dev/null; then
            log "  $config already configured"
            continue
        fi

        # Add PATH configuration
        echo "$path_config" >> "$config"
        log_success "  Configured $config"
        ((configured++))
    done

    return 0
}

configure_fish() {
    log "Configuring Fish..."

    local fish_config="$HOME/.config/fish/config.fish"
    local fish_dir="$HOME/.config/fish"

    # Create fish config directory if it doesn't exist
    if [ ! -d "$fish_dir" ]; then
        mkdir -p "$fish_dir" 2>/dev/null || {
            log_warn "  Could not create Fish config directory"
            return 1
        }
    fi

    # Create config file if it doesn't exist
    touch "$fish_config" 2>/dev/null || {
        log_warn "  Could not create Fish config file"
        return 1
    }

    # Check if already configured
    if grep -q "Added by Bazzite Dev Setup" "$fish_config" 2>/dev/null; then
        log "  Fish already configured"
        return 0
    fi

    # Add PATH configuration (Fish syntax)
    local fish_path_config='
# Added by Bazzite Dev Setup
set -gx PATH $HOME/.local/bin $PATH
'

    echo "$fish_path_config" >> "$fish_config"
    log_success "  Configured Fish"

    return 0
}

configure_docker_aliases() {
    if [ "${SETUP_PODMAN_DOCKER:-false}" != true ]; then
        log "Skipping Docker/Podman aliases (not selected)"
        return 0
    fi

    log_step "Configuring Docker/Podman aliases..."

    # Bash aliases
    local bash_configs=("$HOME/.bashrc" "$HOME/.bash_aliases")
    local alias_config='
# Docker/Podman aliases - Added by Bazzite Dev Setup
alias docker="podman"
alias docker-compose="podman-compose"
'

    for config in "${bash_configs[@]}"; do
        if [ -f "$config" ]; then
            if ! grep -q "Docker/Podman aliases" "$config" 2>/dev/null; then
                echo "$alias_config" >> "$config"
                log_success "  Added aliases to $config"
            fi
        fi
    done

    # Zsh aliases
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "Docker/Podman aliases" "$HOME/.zshrc" 2>/dev/null; then
            echo "$alias_config" >> "$HOME/.zshrc"
            log_success "  Added aliases to ~/.zshrc"
        fi
    fi

    # Fish aliases
    local fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
        local fish_aliases='
# Docker/Podman aliases - Added by Bazzite Dev Setup
alias docker="podman"
alias docker-compose="podman-compose"
'
        if ! grep -q "Docker/Podman aliases" "$fish_config" 2>/dev/null; then
            echo "$fish_aliases" >> "$fish_config"
            log_success "  Added aliases to Fish config"
        fi
    fi

    # Check if podman-compose is available
    if ! command -v podman-compose &> /dev/null; then
        log_warn "podman-compose not found. Install with: pip install --user podman-compose"
    fi

    return 0
}

configure_all_shells() {
    log_step "Configuring shells..."

    local success=true

    # Fix permissions first
    log "Ensuring ~/.local/bin exists and has correct permissions..."
    mkdir -p "$HOME/.local/bin" 2>/dev/null
    chmod 755 "$HOME/.local/bin" 2>/dev/null
    # Note: Removed chown -R as it can hang on large directories and is unnecessary
    # Files created by the user should already have correct ownership

    # Configure each shell
    configure_bash || success=false
    configure_zsh || success=false
    configure_fish || success=false

    # Configure aliases if requested
    configure_docker_aliases || true  # Don't fail on alias configuration

    # Add NVM wrapper function for host-side use
    configure_nvm_wrapper

    # Add PATH to current session
    export PATH="$HOME/.local/bin:$PATH"
    log "PATH configured for current session"

    if [ "$success" = true ]; then
        log_success "All shells configured"

        echo ""
        log_warn "⚠️  IMPORTANT: Restart your terminal or run:"
        echo "  source ~/.bashrc    # for Bash"
        echo "  source ~/.zshrc     # for Zsh"
        echo ""
        return 0
    else
        log_warn "Some shell configurations had issues"
        return 1
    fi
}

configure_nvm_wrapper() {
    if [ "${INSTALL_NODEJS:-true}" != true ]; then
        return 0
    fi

    log "Adding NVM wrapper function for host-side use..."

    local nvm_wrapper='
# NVM wrapper - allows using NVM from host terminal
nvm() {
    distrobox-enter -n main-dev -- bash -lc "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"; nvm $*"
}
'

    # Add to bash configs
    for config in "$HOME/.bashrc" "$HOME/.bash_profile"; do
        if [ -f "$config" ]; then
            if ! grep -q "NVM wrapper" "$config" 2>/dev/null; then
                echo "$nvm_wrapper" >> "$config"
                log "  Added NVM wrapper to $config"
            fi
        fi
    done

    # Add to zsh config
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "NVM wrapper" "$HOME/.zshrc" 2>/dev/null; then
            echo "$nvm_wrapper" >> "$HOME/.zshrc"
            log "  Added NVM wrapper to ~/.zshrc"
        fi
    fi

    # Add to fish config (different syntax)
    local fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
        local fish_nvm_wrapper='
# NVM wrapper for Fish
function nvm
    distrobox-enter -n main-dev -- bash -lc "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"; nvm $argv"
end
'
        if ! grep -q "NVM wrapper" "$fish_config" 2>/dev/null; then
            echo "$fish_nvm_wrapper" >> "$fish_config"
            log "  Added NVM wrapper to Fish config"
        fi
    fi

    log_success "NVM wrapper configured - you can now use 'nvm' from host terminal"
}

verify_shell_configuration() {
    log_step "Verifying shell configuration..."

    # Check if PATH includes ~/.local/bin
    if echo "$PATH" | grep -q "$HOME/.local/bin"; then
        log_success "PATH is correctly configured in current session"
    else
        log_warn "PATH not yet configured (restart terminal needed)"
    fi

    # Check each shell config file
    local shells_configured=0
    local shells_total=0

    for config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
        ((shells_total++))
        if [ -f "$config" ] && grep -q "\.local/bin" "$config" 2>/dev/null; then
            ((shells_configured++))
        fi
    done

    log "Configured $shells_configured out of $shells_total shell config files"

    # Verify binaries are accessible
    if [ -d "$HOME/.local/bin" ] && [ "$(ls -A $HOME/.local/bin 2>/dev/null)" ]; then
        local binary_count
        binary_count=$(ls -1 "$HOME/.local/bin" | wc -l)
        log_success "Found $binary_count binaries in ~/.local/bin"
        return 0
    else
        log_warn "No binaries found in ~/.local/bin yet"
        return 1
    fi
}

# Export functions
export -f configure_bash configure_zsh configure_fish
export -f configure_docker_aliases configure_all_shells
export -f verify_shell_configuration
