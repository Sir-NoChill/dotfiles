#!/usr/bin/env bash
# chezmoi: run_onchange_install-difft.sh
# Installs the `difft` binary from the difftastic GitHub release,
# falling back to pacman on Arch Linux.  Runs whenever this file changes.

# ---------------------------------------------------------------------------
# Globals / pretty-print helpers
# ---------------------------------------------------------------------------

DIFFT_BIN="${HOME}/.bin/difft"
DIFFT_REPO="https://github.com/Wilfred/difftastic.git"
# DIFFT_VERSION and GITHUB_RELEASE_BASE are set dynamically by get_latest_version()
DIFFT_VERSION=""
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

# Detect the OS / distro
is_arch_linux() {
    [[ -f /etc/os-release ]] && grep -qi 'arch' /etc/os-release
}

# Map uname output to the asset suffix used by difftastic releases.
# Asset pattern: difft-<triple>.tar.gz
# Examples:
#   x86_64-unknown-linux-gnu
#   aarch64-unknown-linux-gnu
#   x86_64-apple-darwin
#   aarch64-apple-darwin
detect_asset_triple() {
    local arch os triple
    arch="$(uname -m)"
    os="$(uname -s)"

    case "${os}" in
        Linux)
            case "${arch}" in
                x86_64)  triple="x86_64-unknown-linux-gnu" ;;
                aarch64) triple="aarch64-unknown-linux-gnu" ;;
                armv7l)  triple="armv7-unknown-linux-gnueabihf" ;;
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

# Clone the difftastic repo into a temp dir, inspect its version tags, and
# set the DIFFT_VERSION / GITHUB_RELEASE_BASE globals.  The clone uses
# --no-checkout and --filter=blob:none so only the tag metadata is fetched —
# no source tree is transferred.
get_latest_version() {
    log_step "Resolving latest difftastic release tag from git"

    if ! command -v git &>/dev/null; then
        log_warn "git not found; cannot resolve latest version"
        return 1
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"
    log_info "Cloning (tags only) ${DIFFT_REPO} → ${tmpdir}"

    # Blobless partial clone — fetches commits + tags, skips all file content
    if ! git clone \
            --filter=blob:none \
            --no-checkout \
            --quiet \
            "${DIFFT_REPO}" \
            "${tmpdir}" 2>&1 | while IFS= read -r line; do log_info "git: ${line}"; done; then
        log_warn "git clone failed"
        rm -rf "${tmpdir}"
        return 1
    fi

    # List tags that look like semver (e.g. 0.68.0), sort by version, take the
    # highest one.  git tag -l inside the cloned repo is authoritative.
    local latest
    latest="$(
        git -C "${tmpdir}" tag -l \
        | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -n1
    )"

    rm -rf "${tmpdir}"

    if [[ -z "${latest}" ]]; then
        log_warn "Could not parse any semver tags from the repository"
        return 1
    fi

    DIFFT_VERSION="${latest}"
    GITHUB_RELEASE_BASE="https://github.com/Wilfred/difftastic/releases/download/${DIFFT_VERSION}"
    log_ok "Resolved latest version: ${DIFFT_VERSION}"
}

install_from_github() {
    # Resolve the version dynamically before doing anything else
    get_latest_version || return 1

    log_step "Attempting GitHub release download (v${DIFFT_VERSION})"

    local triple
    triple="$(detect_asset_triple)" || return 1

    local asset="difft-${triple}.tar.gz"
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

    # Locate the binary (it may be directly 'difft' or inside a sub-dir)
    local extracted_bin
    extracted_bin="$(find "${tmpdir}" -type f -name 'difft' | head -n1)"

    if [[ -z "${extracted_bin}" ]]; then
        log_warn "Could not find 'difft' binary inside the archive"
        rm -rf "${tmpdir}"
        return 1
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "${DIFFT_BIN}")"

    # Install
    mv "${extracted_bin}" "${DIFFT_BIN}"
    chmod +x "${DIFFT_BIN}"

    log_ok "Installed difft → ${DIFFT_BIN}"
    return 0
}

install_via_cargo() {
    log_step "Attempting installation via cargo"

    if ! command -v cargo &>/dev/null; then
        log_warn "cargo not found; skipping"
        return 1
    fi

    log_info "Running: cargo install difftastic"
    if cargo install difftastic 2>&1 | while IFS= read -r line; do log_info "cargo: ${line}"; done; then
        # cargo installs to ~/.cargo/bin/difft; symlink into DIFFT_BIN if needed
        local cargo_bin="${HOME}/.cargo/bin/difft"
        if [[ -x "${cargo_bin}" ]] && [[ ! -x "${DIFFT_BIN}" ]]; then
          log_ok "difft installed to ${cargo_bin}"
        fi
        log_ok "difftastic installed via cargo"
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
    echo -e "${BOLD}=== difft install script (chezmoi run_onchange) ===${RESET}"
    echo ""

    # 1. Check if binary already exists and is executable
    if [[ -x "${DIFFT_BIN}" ]]; then
        local version
        version="$("${DIFFT_BIN}" --version 2>/dev/null || echo 'unknown')"
        log_ok "difft already present at ${DIFFT_BIN} (${version}) — nothing to do."
        echo ""
        exit 0
    fi

    # Also honour a system-wide difft (e.g. installed by a previous pacman run)
    if command -v difft &>/dev/null; then
        local sys_difft version
        sys_difft="$(command -v difft)"
        version="$(difft --version 2>/dev/null || echo 'unknown')"
        log_ok "difft found in PATH at ${sys_difft} (${version}) — skipping install."
        echo ""
        exit 0
    fi

    log_info "difft not found — starting installation…"
    echo ""

    # 2. Try GitHub release first
    if install_from_github; then
        echo ""
        log_ok "difft is ready: $("${DIFFT_BIN}" --version 2>/dev/null || echo "${DIFFT_BIN}")"
        echo ""
        exit 0
    fi

    log_warn "GitHub release install failed."
    echo ""

    # 3. Try cargo
    if install_via_cargo; then
        echo ""
        log_ok "difft is ready: $("${DIFFT_BIN}" --version 2>/dev/null || echo "${DIFFT_BIN}")"
        echo ""
        exit 0
    fi

    log_warn "cargo install failed."
    echo ""

    # TODO: try system package manager?

    # 3. All installation strategies exhausted
    echo ""
    log_error "All installation methods failed for difft${DIFFT_VERSION:+ v${DIFFT_VERSION}}."
    log_error "Please install difftastic manually: https://github.com/Wilfred/difftastic/releases"
    echo ""
    exit 1
}

main "$@"
