#!/usr/bin/env bash
# chezmoi: run_once_install-rust.sh
# Installs Rust and cargo via rustup (https://rustup.rs).
# Runs whenever this file changes.

# ---------------------------------------------------------------------------
# Globals / pretty-print helpers
# ---------------------------------------------------------------------------

RUSTUP_INIT_URL="https://sh.rustup.rs"
CARGO_BIN="${HOME}/.cargo/bin/cargo"
RUSTUP_BIN="${HOME}/.cargo/bin/rustup"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Pretty-print functions
log_info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2; }
log_step()    { echo -e "${BOLD}[....] $*${RESET}"; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Source the cargo env file so that cargo/rustup land in PATH for the
# remainder of this script, without requiring a new shell session.
source_cargo_env() {
    local env_file="${HOME}/.cargo/env"
    if [[ -f "${env_file}" ]]; then
        # shellcheck source=/dev/null
        source "${env_file}"
        log_info "Sourced ${env_file}"
    fi
}

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------

install_via_rustup() {
    log_step "Downloading and running rustup installer"

    local tmpfile
    tmpfile="$(mktemp /tmp/rustup-init.XXXXXX.sh)"

    if command -v curl &>/dev/null; then
        log_info "Fetching ${RUSTUP_INIT_URL} with curl…"
        curl --fail --location --silent --show-error \
            --output "${tmpfile}" \
            "${RUSTUP_INIT_URL}" || {
            log_warn "curl fetch failed"
            rm -f "${tmpfile}"
            return 1
        }
    elif command -v wget &>/dev/null; then
        log_info "Fetching ${RUSTUP_INIT_URL} with wget…"
        wget --quiet \
            --output-document "${tmpfile}" \
            "${RUSTUP_INIT_URL}" || {
            log_warn "wget fetch failed"
            rm -f "${tmpfile}"
            return 1
        }
    else
        log_warn "Neither curl nor wget found; cannot fetch rustup installer"
        rm -f "${tmpfile}"
        return 1
    fi

    chmod +x "${tmpfile}"

    log_info "Running rustup-init…"
    # -y          : non-interactive, accept defaults
    # --no-modify-path : chezmoi manages shell config; we source the env file ourselves
    if "${tmpfile}" -y --no-modify-path 2>&1 \
            | while IFS= read -r line; do log_info "rustup-init: ${line}"; done; then
        rm -f "${tmpfile}"
        log_ok "rustup-init completed successfully"
        return 0
    else
        log_warn "rustup-init exited with an error"
        rm -f "${tmpfile}"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BOLD}=== Rust / cargo install script (chezmoi run_once) ===${RESET}"
    echo ""

    # 1. Check for an existing rustup-managed installation
    if [[ -x "${RUSTUP_BIN}" ]]; then
        source_cargo_env
        local rust_version
        rust_version="$(rustc --version 2>/dev/null || echo 'unknown')"
        log_ok "rustup already present at ${RUSTUP_BIN} (${rust_version}) — nothing to do."
        echo ""
        exit 0
    fi

    # 2. Check for cargo anywhere in PATH (e.g. installed by a package manager)
    if command -v cargo &>/dev/null; then
        local sys_cargo rust_version
        sys_cargo="$(command -v cargo)"
        rust_version="$(rustc --version 2>/dev/null || echo 'unknown')"
        log_ok "cargo found in PATH at ${sys_cargo} (${rust_version}) — skipping install."
        echo ""
        exit 0
    fi

    log_info "Rust / cargo not found — starting installation via rustup…"
    echo ""

    # 3. Install via the official rustup script
    if install_via_rustup; then
        source_cargo_env

        # Verify the installation landed correctly
        if command -v cargo &>/dev/null; then
            echo ""
            log_ok "Rust is ready: $(rustc --version 2>/dev/null || echo 'unknown')"
            log_ok "cargo is ready: $(cargo --version 2>/dev/null || echo 'unknown')"
            echo ""
            log_info "NOTE: New shell sessions will pick up cargo automatically via ~/.cargo/env."
            log_info "      If your shell rc does not already source it, add:"
            log_info "        . \"\${HOME}/.cargo/env\""
            echo ""
            exit 0
        else
            log_error "rustup-init reported success but cargo is still not found in PATH."
            log_error "Try opening a new shell or running: source \"\${HOME}/.cargo/env\""
            echo ""
            exit 1
        fi
    fi

    # 4. Installation failed
    echo ""
    log_error "rustup installation failed."
    log_error "Please install Rust manually: ${RUSTUP_INIT_URL}"
    echo ""
    exit 1
}

main "$@"
