#!/usr/bin/env bash
# chezmoi: run_once_install-neovim.sh
# Installs Neovim from the latest tagged GitHub release (AppImage on Linux,
# pre-built tarball on macOS).  Falls back to a pre-built source-repo binary,
# and finally to a full compile-from-source.  Runs once.

# ---------------------------------------------------------------------------
# Globals / configuration
# ---------------------------------------------------------------------------

NVIM_BIN="${HOME}/.bin/nvim"
NVIM_REPO="https://github.com/neovim/neovim.git"
# NVIM_VERSION and GITHUB_RELEASE_BASE can be set dynamically by get_latest_version()
NVIM_VERSION="v0.12.0"
GITHUB_RELEASE_BASE="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}"

# Number of parallel jobs to use when compiling from source.
# Defaults to the number of logical CPUs, or 4 if nproc/sysctl are unavailable.
BUILD_JOBS="$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"

# ---------------------------------------------------------------------------
# Colours / pretty-print helpers
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2; }
log_step()  { echo -e "${BOLD}[....] $*${RESET}"; }

# ---------------------------------------------------------------------------
# OS / architecture detection helpers
# ---------------------------------------------------------------------------

# Succeeds when running on Arch Linux.
is_arch_linux() {
    [[ -f /etc/os-release ]] && grep -qi 'arch' /etc/os-release
}

# Succeeds when running on Debian / Ubuntu and family.
is_debian_like() {
    [[ -f /etc/os-release ]] && grep -qiE 'debian|ubuntu' /etc/os-release
}

# Print the current OS name ("Linux" or "Darwin").
get_os() { uname -s; }

# Print the current CPU architecture as reported by uname.
get_arch() { uname -m; }

# ---------------------------------------------------------------------------
# Version resolution
# ---------------------------------------------------------------------------

# Clone the Neovim repository (tags-only, no checkout, no blobs) into a
# temporary directory, find the highest stable semver tag, and populate the
# globals NVIM_VERSION and GITHUB_RELEASE_BASE.
#
# Stable releases are tagged as "vMAJOR.MINOR.PATCH" (e.g. v0.10.4).
# Nightly/dev tags such as "v0.10.0-dev-..." are intentionally excluded.
get_latest_version() {
    if [ ! -z NVIM_VERSION ]; then
        return 0
    fi

    log_step "Resolving latest Neovim stable release tag from git"

    if ! command -v git &>/dev/null; then
        log_warn "git not found; cannot resolve latest version"
        return 1
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"
    log_info "Cloning (tags only) ${NVIM_REPO} → ${tmpdir}"

    # Blobless partial clone — fetches commits + tags only, no source tree.
    if ! git clone \
            --filter=blob:none \
            --no-checkout \
            --quiet \
            "${NVIM_REPO}" \
            "${tmpdir}" 2>&1 \
        | while IFS= read -r line; do log_info "git: ${line}"; done
    then
        log_warn "git clone failed"
        rm -rf "${tmpdir}"
        return 1
    fi

    # List tags that look like stable semver with the leading 'v'
    # (e.g. v0.10.4).  Tags with a '-' suffix (nightly, rc) are excluded.
    local latest
    latest="$(
        git -C "${tmpdir}" tag -l \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -n1
    )"

    rm -rf "${tmpdir}"

    if [[ -z "${latest}" ]]; then
        log_warn "Could not parse any stable semver tags from the repository"
        return 1
    fi

    NVIM_VERSION="${latest}"
    GITHUB_RELEASE_BASE="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}"
    log_ok "Resolved latest stable version: ${NVIM_VERSION}"
}

# ---------------------------------------------------------------------------
# Strategy 1 — GitHub release (AppImage / tarball)
# ---------------------------------------------------------------------------

# Download a pre-built binary asset from the latest GitHub release.
#
# On Linux   → downloads the AppImage (self-contained, no extraction needed).
# On macOS   → downloads the pre-built tarball and extracts the binary from it.
#
# The binary is placed at NVIM_BIN and made executable.
install_from_github() {
    get_latest_version || return 1

    log_step "Attempting GitHub release download (${NVIM_VERSION})"

    local os arch
    os="$(get_os)"
    arch="$(get_arch)"

    local asset url tmpdir

    case "${os}" in
        # -----------------------------------------------------------------------
        Linux)
            case "${arch}" in
                x86_64)  asset="nvim-linux-x86_64.appimage" ;;
                aarch64) asset="nvim-linux-arm64.appimage"  ;;
                *)
                    log_warn "No AppImage available for Linux/${arch}"
                    return 1
                    ;;
            esac

            url="${GITHUB_RELEASE_BASE}/${asset}"
            tmpdir="$(mktemp -d)"
            log_info "Asset URL: ${url}"

            _download_file "${url}" "${tmpdir}/${asset}" || { rm -rf "${tmpdir}"; return 1; }

            # Make AppImage executable and move it straight to NVIM_BIN.
            chmod +x "${tmpdir}/${asset}"
            mkdir -p "$(dirname "${NVIM_BIN}")"
            mv "${tmpdir}/${asset}" "${NVIM_BIN}"
            rm -rf "${tmpdir}"
            ;;

        # -----------------------------------------------------------------------
        Darwin)
            log_warn "This is despicably untested"
            # The macOS release ships as a tarball containing a standard
            # Unix directory tree (bin/, share/, …).
            case "${arch}" in
                x86_64) asset="nvim-macos-x86_64.tar.gz" ;;
                arm64)  asset="nvim-macos-arm64.tar.gz"  ;;
                *)
                    log_warn "No pre-built macOS tarball available for ${arch}"
                    return 1
                    ;;
            esac

            url="${GITHUB_RELEASE_BASE}/${asset}"
            tmpdir="$(mktemp -d)"
            log_info "Asset URL: ${url}"

            _download_file "${url}" "${tmpdir}/${asset}" || { rm -rf "${tmpdir}"; return 1; }

            log_info "Extracting ${asset}…"
            tar -xzf "${tmpdir}/${asset}" -C "${tmpdir}" || {
                log_warn "Extraction failed"
                rm -rf "${tmpdir}"
                return 1
            }

            # Locate the nvim binary anywhere inside the extracted tree.
            local extracted_bin
            extracted_bin="$(find "${tmpdir}" -type f -name 'nvim' | head -n1)"

            if [[ -z "${extracted_bin}" ]]; then
                log_warn "Could not find 'nvim' binary inside the archive"
                rm -rf "${tmpdir}"
                return 1
            fi

            mkdir -p "$(dirname "${NVIM_BIN}")"
            mv "${extracted_bin}" "${NVIM_BIN}"
            chmod +x "${NVIM_BIN}"
            rm -rf "${tmpdir}"
            ;;

        # -----------------------------------------------------------------------
        *)
            log_warn "Unsupported OS for GitHub release: ${os}"
            return 1
            ;;
    esac

    log_ok "Installed nvim → ${NVIM_BIN}"
    return 0
}

# ---------------------------------------------------------------------------
# Strategy 2 — Pre-built tarball from the source repository
# ---------------------------------------------------------------------------

# Some CI / nightly builds publish a self-contained binary tarball directly in
# the neovim/neovim GitHub releases under the name "nvim-linux64.tar.gz" or
# similar.  This fallback tries that alternate asset naming scheme.
#
# This is distinct from the AppImage path because the asset names differ
# between stable and some older releases.
install_from_source_repo_binary() {
    # Reuse NVIM_VERSION if already set by a previous call; otherwise resolve.
    if [[ -z "${NVIM_VERSION}" ]]; then
        get_latest_version || return 1
    fi

    log_step "Attempting pre-built binary tarball from source repo (${NVIM_VERSION})"

    local os arch
    os="$(get_os)"
    arch="$(get_arch)"

    local asset url tmpdir

    case "${os}" in
        Linux)
            case "${arch}" in
                x86_64)  asset="nvim-linux64.tar.gz" ;;
                aarch64) asset="nvim-linux-arm64.tar.gz" ;;
                *)
                    log_warn "No pre-built source-repo binary for Linux/${arch}"
                    return 1
                    ;;
            esac
            ;;
        Darwin)
            # macOS tarball (same names, different content from the AppImage path)
            case "${arch}" in
                x86_64) asset="nvim-macos-x86_64.tar.gz" ;;
                arm64)  asset="nvim-macos-arm64.tar.gz"  ;;
                *)
                    log_warn "No pre-built source-repo binary for macOS/${arch}"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_warn "Unsupported OS for pre-built binary fallback: ${os}"
            return 1
            ;;
    esac

    url="${GITHUB_RELEASE_BASE}/${asset}"
    tmpdir="$(mktemp -d)"
    log_info "Asset URL: ${url}"

    _download_file "${url}" "${tmpdir}/${asset}" || { rm -rf "${tmpdir}"; return 1; }

    log_info "Extracting ${asset}…"
    tar -xzf "${tmpdir}/${asset}" -C "${tmpdir}" || {
        log_warn "Extraction failed"
        rm -rf "${tmpdir}"
        return 1
    }

    local extracted_bin
    extracted_bin="$(find "${tmpdir}" -type f -name 'nvim' | head -n1)"

    if [[ -z "${extracted_bin}" ]]; then
        log_warn "Could not find 'nvim' binary inside the archive"
        rm -rf "${tmpdir}"
        return 1
    fi

    mkdir -p "$(dirname "${NVIM_BIN}")"
    mv "${extracted_bin}" "${NVIM_BIN}"
    chmod +x "${NVIM_BIN}"
    rm -rf "${tmpdir}"

    log_ok "Installed nvim (pre-built tarball) → ${NVIM_BIN}"
    return 0
}

# ---------------------------------------------------------------------------
# Internal utilities
# ---------------------------------------------------------------------------

# Download a URL to a local path using curl or wget, whichever is available.
# Usage: _download_file <url> <destination>
_download_file() {
    local url="$1"
    local dest="$2"

    if command -v curl &>/dev/null; then
        log_info "Downloading with curl…"
        curl --fail --location --progress-bar \
            --output "${dest}" \
            "${url}" \
        || { log_warn "curl download failed for ${url}"; return 1; }

    elif command -v wget &>/dev/null; then
        log_info "Downloading with wget…"
        wget --quiet --show-progress \
            --output-document "${dest}" \
            "${url}" \
        || { log_warn "wget download failed for ${url}"; return 1; }

    else
        log_warn "Neither curl nor wget found; cannot download"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BOLD}=== Neovim install script (chezmoi run_once) ===${RESET}"
    echo ""

    # 1. Check if our managed binary already exists and is executable.
    if [[ -x "${NVIM_BIN}" ]]; then
        local version
        version="$("${NVIM_BIN}" --version 2>/dev/null | head -n1 || echo 'unknown')"
        log_ok "nvim already present at ${NVIM_BIN} (${version}) — nothing to do."
        echo ""
        exit 0
    fi

    # 2. Also honour a system-wide nvim (e.g. installed by a package manager).
    if command -v nvim &>/dev/null; then
        local sys_nvim version
        sys_nvim="$(command -v nvim)"
        version="$(nvim --version 2>/dev/null | head -n1 || echo 'unknown')"
        log_ok "nvim found in PATH at ${sys_nvim} (${version}) — skipping install."
        echo ""
        exit 0
    fi

    log_info "nvim not found — starting installation…"
    echo ""

    # ---------------------------------------------------------------------------
    # Strategy 1: GitHub release AppImage / pre-built tarball
    # ---------------------------------------------------------------------------
    if install_from_github; then
        echo ""
        log_ok "nvim is ready: $("${NVIM_BIN}" --version 2>/dev/null | head -n1 || echo "${NVIM_BIN}")"
        echo ""
        exit 0
    fi

    log_warn "GitHub release install failed; trying pre-built binary tarball…"
    echo ""

    # ---------------------------------------------------------------------------
    # Strategy 2: Pre-built binary tarball from the source repository releases
    # ---------------------------------------------------------------------------
    if install_from_source_repo_binary; then
        echo ""
        log_ok "nvim is ready: $("${NVIM_BIN}" --version 2>/dev/null | head -n1 || echo "${NVIM_BIN}")"
        echo ""
        exit 0
    fi

    log_warn "Pre-built binary install failed; falling back to compile-from-source…"
    echo ""

    # ---------------------------------------------------------------------------
    # All strategies exhausted
    # ---------------------------------------------------------------------------
    echo ""
    log_error "All installation methods failed for Neovim${NVIM_VERSION:+ ${NVIM_VERSION}}."
    log_error "Please install Neovim manually: https://github.com/neovim/neovim/releases"
    echo ""
    exit 1
}

main "$@"
