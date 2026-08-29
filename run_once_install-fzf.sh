#!/usr/bin/env bash
# chezmoi: run_once_install-fzf.sh
# Installs the `fzf` binary (https://github.com/junegunn/fzf) from a GitHub
# release tarball.  fzf ships prebuilt binaries, so no Go toolchain is needed.
# Runs once per chezmoi apply.
# ---------------------------------------------------------------------------
# Globals / pretty-print helpers
# ---------------------------------------------------------------------------
FZF_REPO_URL="https://github.com/junegunn/fzf.git"
# Where the binary lands. `go install` is intentionally not used here.
FZF_BIN="${FZF_BIN:-${HOME}/.local/bin/fzf}"

# Set by get_latest_version()
FZF_TAG=""
FZF_VERSION=""
GITHUB_RELEASE_BASE=""
# Set by the install strategy on success
INSTALLED_BIN=""

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
# Map uname output to the fzf asset platform token "<os>_<arch>".
# Naming and arch coverage mirror fzf's own installer:
# https://github.com/junegunn/fzf/blob/master/install
# Asset pattern: fzf-<version>-<os>_<arch>.tar.gz
detect_asset_platform() {
    local arch os os_tok arch_tok
    arch="$(uname -m)"
    os="$(uname -s)"
    case "${os}" in
        Linux)  os_tok="linux" ;;
        Darwin) os_tok="darwin" ;;
        *)
            log_error "Unsupported OS: ${os}"
            return 1
            ;;
    esac
    if [[ "${os_tok}" == "darwin" ]]; then
        case "${arch}" in
            x86_64|amd64)  arch_tok="amd64" ;;
            arm64|aarch64) arch_tok="arm64" ;;
            *)
                log_error "Unsupported macOS architecture: ${arch}"
                return 1
                ;;
        esac
    else
        case "${arch}" in
            x86_64|amd64)   arch_tok="amd64" ;;
            aarch64|arm64)  arch_tok="arm64" ;;
            armv7l)         arch_tok="armv7" ;;
            armv6l)         arch_tok="armv6" ;;
            armv5*)         arch_tok="armv5" ;;
            ppc64le)        arch_tok="ppc64le" ;;
            s390x)          arch_tok="s390x" ;;
            riscv64)        arch_tok="riscv64" ;;
            loongarch64)    arch_tok="loong64" ;;
            *)
                log_error "Unsupported Linux architecture: ${arch}"
                return 1
                ;;
        esac
    fi
    echo "${os_tok}_${arch_tok}"
}

# Resolve the currently-usable fzf path, if any.
resolve_installed() {
    command -v fzf 2>/dev/null || { [[ -x "${FZF_BIN}" ]] && echo "${FZF_BIN}"; }
}
# ---------------------------------------------------------------------------
# Version resolution (git)
# ---------------------------------------------------------------------------
# Ask the remote for its tags without cloning a working tree, pick the highest
# semver tag, and derive the release download base.  fzf tags are "vX.Y.Z"; the
# asset name uses the version without the leading "v".
get_latest_version() {
    log_step "Resolving latest fzf release tag from git"
    if ! command -v git &>/dev/null; then
        log_warn "git not found; cannot resolve latest version"
        return 1
    fi
    local tags latest_tag
    if ! tags="$(git ls-remote --tags --refs "${FZF_REPO_URL}" 2>/dev/null)"; then
        log_warn "git ls-remote failed against ${FZF_REPO_URL}"
        return 1
    fi
    # awk -F/ '{print $NF}': strip refs/tags/ prefix -> bare tag name.
    # sort -V: version sort so 0.74.1 > 0.9.0. tail -n1: highest.
    latest_tag="$(
        echo "${tags}" \
        | awk -F/ '{print $NF}' \
        | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -V \
        | tail -n1
    )"
    if [[ -z "${latest_tag}" ]]; then
        log_warn "Could not parse any semver tags from the repository"
        return 1
    fi
    FZF_TAG="${latest_tag}"
    FZF_VERSION="${latest_tag#v}"
    GITHUB_RELEASE_BASE="https://github.com/junegunn/fzf/releases/download/${FZF_TAG}"
    log_ok "Resolved latest version: ${FZF_VERSION} (tag ${FZF_TAG})"
}
# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------
install_from_github() {
    get_latest_version || return 1
    log_step "Attempting GitHub release download (${FZF_VERSION})"
    local platform
    platform="$(detect_asset_platform)" || return 1
    local asset="fzf-${FZF_VERSION}-${platform}.tar.gz"
    local url="${GITHUB_RELEASE_BASE}/${asset}"
    local tmpdir
    tmpdir="$(mktemp -d)"
    log_info "Asset URL: ${url}"
    log_info "Temp dir:  ${tmpdir}"
    # Download
    if command -v curl &>/dev/null; then
        log_info "Downloading with curl..."
        curl --fail --location --progress-bar \
            --output "${tmpdir}/${asset}" \
            "${url}" || { log_warn "curl download failed"; rm -rf "${tmpdir}"; return 1; }
    elif command -v wget &>/dev/null; then
        log_info "Downloading with wget..."
        wget --quiet --show-progress \
            --output-document "${tmpdir}/${asset}" \
            "${url}" || { log_warn "wget download failed"; rm -rf "${tmpdir}"; return 1; }
    else
        log_warn "Neither curl nor wget found; cannot download"
        rm -rf "${tmpdir}"
        return 1
    fi
    # Extract
    log_info "Extracting ${asset}..."
    tar -xzf "${tmpdir}/${asset}" -C "${tmpdir}" || {
        log_warn "Extraction failed"
        rm -rf "${tmpdir}"
        return 1
    }
    # Locate the binary (fzf archives contain a bare 'fzf' at the root)
    local extracted_bin
    extracted_bin="$(find "${tmpdir}" -type f -name 'fzf' | head -n1)"
    if [[ -z "${extracted_bin}" ]]; then
        log_warn "Could not find 'fzf' binary inside the archive"
        rm -rf "${tmpdir}"
        return 1
    fi
    mkdir -p "$(dirname "${FZF_BIN}")"
    mv "${extracted_bin}" "${FZF_BIN}"
    chmod +x "${FZF_BIN}"
    rm -rf "${tmpdir}"
    INSTALLED_BIN="${FZF_BIN}"
    log_ok "Installed fzf -> ${FZF_BIN}"
    case ":${PATH}:" in
        *":$(dirname "${FZF_BIN}"):"*) : ;;
        *) log_warn "$(dirname "${FZF_BIN}") is not on your PATH; add it to use 'fzf'." ;;
    esac
    return 0
}
# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BOLD}=== fzf install script (chezmoi run_once) ===${RESET}"
    echo ""
    # 1. Already installed?
    local existing
    existing="$(resolve_installed)"
    if [[ -n "${existing}" ]]; then
        local version
        version="$("${existing}" --version 2>/dev/null || echo 'unknown')"
        log_ok "fzf already present at ${existing} (${version}) — nothing to do."
        echo ""
        exit 0
    fi
    log_info "fzf not found — starting installation..."
    echo ""
    # 2. GitHub release tarball (only strategy; no Go build)
    if install_from_github; then
        echo ""
        log_ok "fzf is ready: $("${INSTALLED_BIN}" --version 2>/dev/null || echo "${INSTALLED_BIN}")"
        echo ""
        exit 0
    fi
    log_warn "GitHub release install failed."
    echo ""
    # 3. Exhausted
    log_error "Installation failed for fzf${FZF_VERSION:+ ${FZF_VERSION}}."
    log_error "Install manually: https://github.com/junegunn/fzf/releases"
    echo ""
    exit 1
}
main "$@"
