#!/usr/bin/env bash

# =============================================================================
# diary.sh — daily note manager
# =============================================================================


# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Opens today's diary note in \$EDITOR, creating a new one from the template
if the current note is outdated or missing.

Daily notes are stored in: ~/.diary/YYYY/MM/DD.md
Active note:               ~/.diary/today.md
Template:                  ~/.diary/daily_note.template

Options:
  -h, --help      Show this help message and exit

Notes:
  - \$EDITOR must be set. Falls back to \$VISUAL, then 'vi'.
  - The template file must exist at ~/.diary/daily_note.template
  - Year/month archive directories are created automatically.

EOF
}

# Resolve which editor to use, in order of preference.
resolve_editor() {
    if [[ -n "$EDITOR" ]]; then
        echo "$EDITOR"
    elif [[ -n "$VISUAL" ]]; then
        echo "$VISUAL"
    else
        echo "vi"
    fi
}

# Extract the 'date' field from the YAML frontmatter of a given file.
# Returns an empty string if the file doesn't exist or has no date field.
get_note_date() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi
    # Match 'date: YYYY-MM-DD' inside the opening frontmatter block
    awk '/^---/{found++; next} found==1 && /^date:/{print $2; exit}' "$file"
}

# Archive today.md into the dated directory structure, then create a fresh note
# from the template.
rotate_note() {
    local today_file="$1"
    local template="$2"
    local archive_dir="$3"
    local archive_file="$4"

    if [[ -f "$today_file" ]]; then
        mkdir -p "$archive_dir" || {
            echo "Error: could not create archive directory '$archive_dir'." >&2
            exit 1
        }
        cp "$today_file" "$archive_file" || {
            echo "Error: could not archive '$today_file' to '$archive_file'." >&2
            exit 1
        }
        echo "Archived previous note → $archive_file"
    fi

    cp "$template" "$today_file" || {
        echo "Error: could not copy template to '$today_file'." >&2
        exit 1
    }
    echo "Created new note from template."
}

# Open the given file in the resolved editor.
open_in_editor() {
    local file="$1"
    local editor
    editor="$(resolve_editor)"
    exec "$editor" "$file"
}


# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

DIARY_DIR="$HOME/.diary"
TODAY_FILE="$DIARY_DIR/today.md"
TEMPLATE_FILE="$DIARY_DIR/daily_note.template"

CURRENT_DATE="$(date +%F)"          # YYYY-MM-DD
YEAR="$(date +%Y)"
MONTH="$(date +%m)"
DAY="$(date +%d)"

ARCHIVE_DIR="$DIARY_DIR/$YEAR/$MONTH"
ARCHIVE_FILE="$ARCHIVE_DIR/$DAY.md"


# -----------------------------------------------------------------------------
# OPTIONS
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done


# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

# Validate that the template exists before doing anything else.
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: template not found at '$TEMPLATE_FILE'." >&2
    exit 1
fi

note_date="$(get_note_date "$TODAY_FILE")"

if [[ "$note_date" == "$CURRENT_DATE" ]]; then
    # today.md is already today's note — just open it.
    echo "Opening today's note ($CURRENT_DATE)."
else
    # today.md is stale or missing — rotate and create a fresh note.
    if [[ -z "$note_date" ]]; then
        echo "No existing note found. Creating a new note for $CURRENT_DATE."
    else
        echo "Note date ($note_date) does not match today ($CURRENT_DATE). Rotating."
    fi
    rotate_note "$TODAY_FILE" "$TEMPLATE_FILE" "$ARCHIVE_DIR" "$ARCHIVE_FILE"
fi

open_in_editor "$TODAY_FILE"
