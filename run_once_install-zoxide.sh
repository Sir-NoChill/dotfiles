#!/usr/bin/env bash
# chezmoi: run_once_install-zoxide.sh
# Installs the `zoxide` binary from the zoxide GitHub release,
# falling back to cargo on other platforms.  Runs whenever this file changes.

# ---------------------------------------------------------------------------
# Globals / pretty-print helpers
# ---------------------------------------------------------------------------

ZOXIDE_BIN="${HOME}/.bin/zoxide"
ZOXIDE_REPO="https://github.com/ajeetdsouza/zoxide.git"
# ZOXIDE_VERSION and GITHUB_RELEASE_BASE are set dynamically by get_latest_version()
ZOXIDE_VERSION=""
GITHUB_RELEASE_BASE=""

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

# Map uname output to the asset suffix used by zoxide releases.
# Asset pattern: zoxide-<version>-<triple>.tar.gz
# Examples:
#   x86_64-unknown-linux-musl
#   aarch64-unknown-linux-musl
#   x86_64-apple-darwin
#   aarch64-apple-darwin
detect_asset_triple() {
    local arch os triple
    arch="$(uname -m)"
    os="$(uname -s)"

    case "${os}" in
        Linux)
            case "${arch}" in
                x86_64)  triple="x86_64-unknown-linux-musl" ;;
                aarch64) triple="aarch64-unknown-linux-musl" ;;
                armv7l)  triple="armv7-unknown-linux-musleabihf" ;;
                *)
                    log_error "Unsupported Linux architecture: ${arch}"
                    return 1
                    ;;
            esac
            ;;
        Darwin)
            case "${arch}" in
                x86_64)  triple="x86_64-apple-darwin" ;;
                arm64)   triple="aarch64-apple-darwin" ;;
                *)
                    log_error "Unsupported macOS architecture: ${arch}"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Unsupported OS: ${os}"
            return 1
            ;;
    esac

    echo "${triple}"
}

# ---------------------------------------------------------------------------
# Installation strategies
# ---------------------------------------------------------------------------

# Clone the zoxide repo into a temp dir, inspect its version tags, and set
# the ZOXIDE_VERSION / GITHUB_RELEASE_BASE globals.  The clone uses
# --no-checkout and --filter=blob:none so only tag metadata is fetched —
# no source tree is transferred.
get_latest_version() {
    log_step "Resolving latest zoxide release tag from git"

    if ! command -v git &>/dev/null; then
        log_warn "git not found; cannot resolve latest version"
        return 1
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"
    log_info "Cloning (tags only) ${ZOXIDE_REPO} → ${tmpdir}"

    # Blobless partial clone — fetches commits + tags, skips all file content
    if ! git clone \
            --filter=blob:none \
            --no-checkout \
            --quiet \
            "${ZOXIDE_REPO}" \
            "${tmpdir}" 2>&1 | while IFS= read -r line; do log_info "git: ${line}"; done; then
        log_warn "git clone failed"
        rm -rf "${tmpdir}"
        return 1
    fi

    # zoxide tags are prefixed with 'v' (e.g. v0.9.4); strip the prefix after
    # sorting so the comparison is numeric.
    local latest
    latest="$(
        git -C "${tmpdir}" tag -l \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -n1
    )"

    rm -rf "${tmpdir}"

    if [[ -z "${latest}" ]]; then
        log_warn "Could not parse any semver tags from the repository"
        return 1
    fi

    ZOXIDE_VERSION="${latest}"   # e.g. "v0.9.4"
    GITHUB_RELEASE_BASE="https://github.com/ajeetdsouza/zoxide/releases/download/${ZOXIDE_VERSION}"
    log_ok "Resolved latest version: ${ZOXIDE_VERSION}"
}

install_from_github() {
    # Resolve the version dynamically before doing anything else
    get_latest_version || return 1

    log_step "Attempting GitHub release download (${ZOXIDE_VERSION})"

    local triple
    triple="$(detect_asset_triple)" || return 1

    # Strip the leading 'v' for the archive filename (e.g. zoxide-0.9.4-...)
    local ver_bare="${ZOXIDE_VERSION#v}"
    local asset="zoxide-${ver_bare}-${triple}.tar.gz"
    local url="${GITHUB_RELEASE_BASE}/${asset}"
    local tmpdir
    tmpdir="$(mktemp -d)"

    log_info "Asset URL: ${url}"
    log_info "Temp dir:  ${tmpdir}"

    # Download
    if command -v curl &>/dev/null; then
        log_info "Downloading with curl…"
        curl --fail --location --progress-bar \
            --output "${tmpdir}/${asset}" \
            "${url}" || { log_warn "curl download failed"; rm -rf "${tmpdir}"; return 1; }
    elif command -v wget &>/dev/null; then
        log_info "Downloading with wget…"
        wget --quiet --show-progress \
            --output-document "${tmpdir}/${asset}" \
            "${url}" || { log_warn "wget download failed"; rm -rf "${tmpdir}"; return 1; }
    else
        log_warn "Neither curl nor wget found; cannot download"
        rm -rf "${tmpdir}"
        return 1
    fi

    # Extract
    log_info "Extracting ${asset}…"
    tar -xzf "${tmpdir}/${asset}" -C "${tmpdir}" || {
        log_warn "Extraction failed"
        rm -rf "${tmpdir}"
        return 1
    }

    # Locate the binary (it may be directly 'zoxide' or inside a sub-dir)
    local extracted_bin
    extracted_bin="$(find "${tmpdir}" -type f -name 'zoxide' | head -n1)"

    if [[ -z "${extracted_bin}" ]]; then
        log_warn "Could not find 'zoxide' binary inside the archive"
        rm -rf "${tmpdir}"
        return 1
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "${ZOXIDE_BIN}")"

    # Install
    mv "${extracted_bin}" "${ZOXIDE_BIN}"
    chmod +x "${ZOXIDE_BIN}"

    rm -rf "${tmpdir}"
    log_ok "Installed zoxide → ${ZOXIDE_BIN}"
    return 0
}

install_via_package_manager() {
    log_step "Attempting installation via system package manager"

    # Arch Linux / Manjaro
    if command -v pacman &>/dev/null; then
        log_info "Detected pacman; running: sudo pacman -S --noconfirm zoxide"
        if sudo pacman -S --noconfirm zoxide 2>&1 \
                | while IFS= read -r line; do log_info "pacman: ${line}"; done; then
            log_ok "zoxide installed via pacman"
            return 0
        else
            log_warn "pacman install failed"
        fi
    fi

    # Debian / Ubuntu
    if command -v apt-get &>/dev/null; then
        log_info "Detected apt-get; running: sudo apt-get install -y zoxide"
        if sudo apt-get install -y zoxide 2>&1 \
                | while IFS= read -r line; do log_info "apt: ${line}"; done; then
            log_ok "zoxide installed via apt-get"
            return 0
        else
            log_warn "apt-get install failed (package may not be available in this release)"
        fi
    fi

    # Fedora / RHEL / CentOS
    if command -v dnf &>/dev/null; then
        log_info "Detected dnf; running: sudo dnf install -y zoxide"
        if sudo dnf install -y zoxide 2>&1 \
                | while IFS= read -r line; do log_info "dnf: ${line}"; done; then
            log_ok "zoxide installed via dnf"
            return 0
        else
            log_warn "dnf install failed"
        fi
    fi

    # Homebrew (macOS / Linux)
    if command -v brew &>/dev/null; then
        log_info "Detected brew; running: brew install zoxide"
        if brew install zoxide 2>&1 \
                | while IFS= read -r line; do log_info "brew: ${line}"; done; then
            log_ok "zoxide installed via brew"
            return 0
        else
            log_warn "brew install failed"
        fi
    fi

    log_warn "No supported package manager found or all attempts failed"
    return 1
}

install_via_cargo() {
    log_step "Attempting installation via cargo"

    if ! command -v cargo &>/dev/null; then
        log_warn "cargo not found; skipping"
        return 1
    fi

    log_info "Running: cargo install zoxide --locked"
    if cargo install zoxide --locked 2>&1 \
            | while IFS= read -r line; do log_info "cargo: ${line}"; done; then
        local cargo_bin="${HOME}/.cargo/bin/zoxide"
        if [[ -x "${cargo_bin}" ]] && [[ ! -x "${ZOXIDE_BIN}" ]]; then
            log_ok "zoxide installed to ${cargo_bin}"
        fi
        log_ok "zoxide installed via cargo"
        return 0
    else
        log_warn "cargo install failed"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BOLD}=== zoxide install script (chezmoi run_once) ===${RESET}"
    echo ""

    # 1. Check if binary already exists and is executable
    if [[ -x "${ZOXIDE_BIN}" ]]; then
        local version
        version="$("${ZOXIDE_BIN}" --version 2>/dev/null || echo 'unknown')"
        log_ok "zoxide already present at ${ZOXIDE_BIN} (${version}) — nothing to do."
        echo ""
        exit 0
    fi

    # Also honour a system-wide zoxide (e.g. installed by a previous package-manager run)
    if command -v zoxide &>/dev/null; then
        local sys_zoxide version
        sys_zoxide="$(command -v zoxide)"
        version="$(zoxide --version 2>/dev/null || echo 'unknown')"
        log_ok "zoxide found in PATH at ${sys_zoxide} (${version}) — skipping install."
        echo ""
        exit 0
    fi

    log_info "zoxide not found — starting installation…"
    echo ""

    # 2. Try GitHub release first (fastest, no build required)
    if install_from_github; then
        echo ""
        log_ok "zoxide is ready: $("${ZOXIDE_BIN}" --version 2>/dev/null || echo "${ZOXIDE_BIN}")"
        echo ""
        exit 0
    fi

    log_warn "GitHub release install failed."
    echo ""

    # 4. Try cargo
    if install_via_cargo; then
        echo ""
        local resolved
        resolved="$(command -v zoxide || echo "${HOME}/.cargo/bin/zoxide")"
        log_ok "zoxide is ready: $(${resolved} --version 2>/dev/null || echo "${resolved}")"
        echo ""
        exit 0
    fi

    log_warn "cargo install failed."
    echo ""


    # 3. Try system package manager
    if install_via_package_manager; then
        echo ""
        # After a package-manager install the binary lands in PATH, not ZOXIDE_BIN
        local resolved
        resolved="$(command -v zoxide || echo 'zoxide')"
        log_ok "zoxide is ready: $(${resolved} --version 2>/dev/null || echo "${resolved}")"
        echo ""
        exit 0
    fi

    log_warn "Package manager install failed."
    echo ""

    # 5. All installation strategies exhausted
    echo ""
    log_error "All installation methods failed for zoxide${ZOXIDE_VERSION:+ ${ZOXIDE_VERSION}}."
    log_error "Please install zoxide manually: https://github.com/ajeetdsouza/zoxide#installation"
    echo ""
    exit 1
}

main "$@"
