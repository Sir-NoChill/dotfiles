#!/usr/bin/env bash
# chezmoi: run_once_install-gitbutler.sh
# Installs the `but` binary from the GitButler install script.
# Runs whenever this file changes.

# ---------------------------------------------------------------------------
# Globals / pretty-print helpers
# ---------------------------------------------------------------------------

GITBUTLER_INSTALL_URL="https://gitbutler.com/install.sh"

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
# Installation
# ---------------------------------------------------------------------------

install_via_bootstrap() {
    log_step "Downloading and running GitButler install script"

    local tmpfile
    tmpfile="$(mktemp /tmp/gitbutler-install.XXXXXX.sh)"

    if command -v curl &>/dev/null; then
        log_info "Fetching ${GITBUTLER_INSTALL_URL} with curl…"
        curl --fail --silent --show-error --location \
            --output "${tmpfile}" \
            "${GITBUTLER_INSTALL_URL}" || {
            log_warn "curl fetch failed"
            rm -f "${tmpfile}"
            return 1
        }
    elif command -v wget &>/dev/null; then
        log_info "Fetching ${GITBUTLER_INSTALL_URL} with wget…"
        wget --quiet \
            --output-document "${tmpfile}" \
            "${GITBUTLER_INSTALL_URL}" || {
            log_warn "wget fetch failed"
            rm -f "${tmpfile}"
            return 1
        }
    else
        log_warn "Neither curl nor wget found; cannot fetch GitButler installer"
        rm -f "${tmpfile}"
        return 1
    fi

    chmod +x "${tmpfile}"

    log_info "Running GitButler install script…"
    if sh "${tmpfile}" 2>&1 \
            | while IFS= read -r line; do log_info "install.sh: ${line}"; done; then
        rm -f "${tmpfile}"
        log_ok "GitButler install script completed successfully"
        return 0
    else
        log_warn "GitButler install script exited with an error"
        rm -f "${tmpfile}"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BOLD}=== GitButler install script (chezmoi run_once) ===${RESET}"
    echo ""

    # 1. Check for an existing `but` binary in PATH
    if command -v but &>/dev/null; then
        local sys_but version
        sys_but="$(command -v but)"
        version="$(but --version 2>/dev/null || echo 'unknown')"
        log_ok "but found in PATH at ${sys_but} (${version}) — skipping install."
        echo ""
        exit 0
    fi

    # 2. Common non-PATH install locations the upstream script may use
    local candidate
    for candidate in \
        "${HOME}/.local/bin/but" \
        "${HOME}/.bin/but" \
        "/usr/local/bin/but" \
        "/opt/gitbutler/but"
    do
        if [[ -x "${candidate}" ]]; then
            local version
            version="$("${candidate}" --version 2>/dev/null || echo 'unknown')"
            log_ok "but already present at ${candidate} (${version}) — skipping install."
            echo ""
            exit 0
        fi
    done

    log_info "but not found — starting GitButler installation…"
    echo ""

    # 3. Install via the official bootstrap script
    if install_via_bootstrap; then
        # Re-check PATH and known locations after install
        if command -v but &>/dev/null; then
            echo ""
            log_ok "GitButler is ready: $(but --version 2>/dev/null || echo 'unknown')"
            echo ""
            exit 0
        fi

        for candidate in \
            "${HOME}/.local/bin/but" \
            "${HOME}/.bin/but" \
            "/usr/local/bin/but" \
            "/opt/gitbutler/but"
        do
            if [[ -x "${candidate}" ]]; then
                echo ""
                log_ok "GitButler is ready: $("${candidate}" --version 2>/dev/null || echo 'unknown')"
                log_info "NOTE: ${candidate} may not be on your PATH yet."
                log_info "      Ensure your shell rc includes its parent directory."
                echo ""
                exit 0
            fi
        done

        # Script claimed success but we can't find the binary
        log_error "Install script reported success but 'but' could not be located."
        log_error "Check the install script output above for the installation path."
        echo ""
        exit 1
    fi

    # 4. Installation failed
    echo ""
    log_error "GitButler installation failed."
    log_error "Please install manually: curl -fsSL ${GITBUTLER_INSTALL_URL} | sh"
    log_error "Or visit: https://gitbutler.com"
    echo ""
    exit 1
}

main "$@"
