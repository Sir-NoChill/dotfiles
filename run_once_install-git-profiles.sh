#!/usr/bin/env bash
# chezmoi: run_once_install-git-profile.sh
# Installs the `git-profile` binary (https://github.com/dotzero/git-profile).
# Strategy: prefer `go install` (needs go + git for VCS resolution), then fall
# back to downloading a GitHub release tarball.  Runs once per chezmoi apply.
# ---------------------------------------------------------------------------
# Globals / pretty-print helpers
# ---------------------------------------------------------------------------
GIT_PROFILE_MODULE="github.com/dotzero/git-profile"
GIT_PROFILE_REPO_URL="https://github.com/dotzero/git-profile.git"
# Where the tarball fallback drops the binary. `go install` uses GOBIN/GOPATH.
GIT_PROFILE_BIN="${GIT_PROFILE_BIN:-${HOME}/.local/bin/git-profile}"

# Set by get_latest_version()
GIT_PROFILE_TAG=""
GIT_PROFILE_VERSION=""
GITHUB_RELEASE_BASE=""
# Set by whichever strategy succeeds
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
# Map uname output to the goreleaser asset platform token "<OS>-<arch>".
# Naming derives from the project's .goreleaser.yml archive name_template:
#   git-profile_<version>_<OS>-<arch>.tar.gz
# where OS is "Linux" or "macOS", Linux arch is amd64/arm64, and macOS ships a
# single universal binary tagged "all" (universal_binaries.replace: true).
detect_asset_platform() {
    local arch os os_tok arch_tok
    arch="$(uname -m)"
    os="$(uname -s)"
    case "${os}" in
        Linux)  os_tok="Linux" ;;
        Darwin) os_tok="macOS" ;;
        *)
            log_error "Unsupported OS: ${os}"
            return 1
            ;;
    esac
    if [[ "${os_tok}" == "macOS" ]]; then
        arch_tok="all"                       # universal binary, arch-independent
    else
        case "${arch}" in
            x86_64|amd64)  arch_tok="amd64" ;;
            aarch64|arm64) arch_tok="arm64" ;;
            *)
                log_error "Unsupported Linux architecture: ${arch}"
                return 1
                ;;
        esac
    fi
    echo "${os_tok}-${arch_tok}"
}

# Resolve the currently-usable git-profile path, if any.
resolve_installed() {
    command -v git-profile 2>/dev/null || { [[ -x "${GIT_PROFILE_BIN}" ]] && echo "${GIT_PROFILE_BIN}"; }
}
# ---------------------------------------------------------------------------
# Version resolution (git)
# ---------------------------------------------------------------------------
# Ask the remote for its tags without cloning a working tree, pick the highest
# semver tag, and derive the release download base.  Handles both "v1.2.3" and
# "1.2.3" tag styles (the asset name always uses the version without the "v").
get_latest_version() {
    log_step "Resolving latest git-profile release tag from git"
    if ! command -v git &>/dev/null; then
        log_warn "git not found; cannot resolve latest version"
        return 1
    fi
    local tags latest_tag
    if ! tags="$(git ls-remote --tags --refs "${GIT_PROFILE_REPO_URL}" 2>/dev/null)"; then
        log_warn "git ls-remote failed against ${GIT_PROFILE_REPO_URL}"
        return 1
    fi
    # awk -F/ '{print $NF}': strip refs/tags/ prefix -> bare tag name.
    # sort -V: version sort so 1.10.0 > 1.9.0. tail -n1: highest.
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
    GIT_PROFILE_TAG="${latest_tag}"
    GIT_PROFILE_VERSION="${latest_tag#v}"
    GITHUB_RELEASE_BASE="https://github.com/dotzero/git-profile/releases/download/${GIT_PROFILE_TAG}"
    log_ok "Resolved latest version: ${GIT_PROFILE_VERSION} (tag ${GIT_PROFILE_TAG})"
}
# ---------------------------------------------------------------------------
# Installation strategies
# ---------------------------------------------------------------------------
install_via_go() {
    log_step "Attempting installation via 'go install'"
    if ! command -v go &>/dev/null; then
        log_warn "go not found; skipping go-based install"
        return 1
    fi
    if ! command -v git &>/dev/null; then
        log_warn "git not found; 'go install' cannot resolve the module via VCS"
        return 1
    fi
    log_info "$(go version 2>/dev/null)"
    local gobin
    gobin="$(go env GOBIN)"
    [[ -z "${gobin}" ]] && gobin="$(go env GOPATH)/bin"
    log_info "Running: go install ${GIT_PROFILE_MODULE}@latest (GOBIN=${gobin})"
    # PIPESTATUS[0] preserves go's exit code past the logging pipe; a bare
    # `if go install ... | while ...` would test the while loop instead.
    # https://www.gnu.org/software/bash/manual/bash.html#index-PIPESTATUS
    go install "${GIT_PROFILE_MODULE}@latest" 2>&1 \
        | while IFS= read -r line; do log_info "go: ${line}"; done
    local rc=${PIPESTATUS[0]}
    if (( rc != 0 )); then
        log_warn "go install failed (exit ${rc})"
        return 1
    fi
    local go_bin_path="${gobin}/git-profile"
    if [[ ! -x "${go_bin_path}" ]]; then
        log_warn "go install reported success but ${go_bin_path} is missing"
        return 1
    fi
    INSTALLED_BIN="${go_bin_path}"
    log_ok "Installed git-profile -> ${go_bin_path}"
    case ":${PATH}:" in
        *":${gobin}:"*) : ;;
        *) log_warn "${gobin} is not on your PATH; add it to use 'git-profile'." ;;
    esac
    return 0
}

install_from_github() {
    get_latest_version || return 1
    log_step "Attempting GitHub release download (${GIT_PROFILE_VERSION})"
    local platform
    platform="$(detect_asset_platform)" || return 1
    local asset="git-profile_${GIT_PROFILE_VERSION}_${platform}.tar.gz"
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
    # Locate the binary (archive root or a sub-dir)
    local extracted_bin
    extracted_bin="$(find "${tmpdir}" -type f -name 'git-profile' | head -n1)"
    if [[ -z "${extracted_bin}" ]]; then
        log_warn "Could not find 'git-profile' binary inside the archive"
        rm -rf "${tmpdir}"
        return 1
    fi
    mkdir -p "$(dirname "${GIT_PROFILE_BIN}")"
    mv "${extracted_bin}" "${GIT_PROFILE_BIN}"
    chmod +x "${GIT_PROFILE_BIN}"
    rm -rf "${tmpdir}"
    INSTALLED_BIN="${GIT_PROFILE_BIN}"
    log_ok "Installed git-profile -> ${GIT_PROFILE_BIN}"
    case ":${PATH}:" in
        *":$(dirname "${GIT_PROFILE_BIN}"):"*) : ;;
        *) log_warn "$(dirname "${GIT_PROFILE_BIN}") is not on your PATH; add it to use 'git-profile'." ;;
    esac
    return 0
}
# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BOLD}=== git-profile install script (chezmoi run_once) ===${RESET}"
    echo ""
    # 1. Already installed?
    local existing
    existing="$(resolve_installed)"
    if [[ -n "${existing}" ]]; then
        local version
        version="$("${existing}" --version 2>/dev/null || echo 'unknown')"
        log_ok "git-profile already present at ${existing} (${version}) — nothing to do."
        echo ""
        exit 0
    fi
    log_info "git-profile not found — starting installation..."
    echo ""
    # 2. Prefer go install
    if install_via_go; then
        echo ""
        log_ok "git-profile is ready: $("${INSTALLED_BIN}" --version 2>/dev/null || echo "${INSTALLED_BIN}")"
        echo ""
        exit 0
    fi
    log_warn "go-based install unavailable or failed."
    echo ""
    # 3. Fall back to GitHub release tarball
    if install_from_github; then
        echo ""
        log_ok "git-profile is ready: $("${INSTALLED_BIN}" --version 2>/dev/null || echo "${INSTALLED_BIN}")"
        echo ""
        exit 0
    fi
    log_warn "GitHub release install failed."
    echo ""
    # 4. Exhausted
    log_error "All installation methods failed for git-profile${GIT_PROFILE_VERSION:+ ${GIT_PROFILE_VERSION}}."
    log_error "Install manually: https://github.com/dotzero/git-profile/releases"
    echo ""
    exit 1
}
main "$@"
