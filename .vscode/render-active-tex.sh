#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'VS Code thesis render: %s\n' "$*" >&2
    exit 1
}

file_uri() {
    python3 - "$1" <<'PY'
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve().as_uri())
PY
}

is_wsl() {
    grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

windows_file_uri() {
    local windows_path
    windows_path="$(wslpath -w "$1")"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$windows_path" <<'PY'
from pathlib import PureWindowsPath
import sys
from urllib.parse import quote

path = PureWindowsPath(sys.argv[1])
parts = [quote(part, safe='') for part in path.parts[1:]]

if path.drive.startswith('\\\\'):
    host, share = path.drive.lstrip('\\').split('\\', 1)
    print(f"file://{host}/{quote(share, safe='')}/{'/'.join(parts)}")
elif path.drive:
    drive = path.drive.rstrip(':')
    print(f"file:///{drive}:/{'/'.join(parts)}")
else:
    print('file:///' + '/'.join(quote(part, safe='') for part in path.parts))
PY
        return 0
    fi

    printf 'file:///%s\n' "${windows_path//\\//}"
}

open_pdf_in_browser() {
    local pdf_path=$1
    local uri

    if is_wsl && command -v wslpath >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
        uri="$(windows_file_uri "$pdf_path")"
        cmd.exe /C start "" "$uri" >/dev/null 2>&1 &
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        uri="$(file_uri "$pdf_path")"
        if python3 - "$uri" <<'PY'
import sys
import webbrowser

raise SystemExit(0 if webbrowser.open_new_tab(sys.argv[1]) else 1)
PY
        then
            return 0
        fi
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$pdf_path" >/dev/null 2>&1 &
        return 0
    fi

    if command -v open >/dev/null 2>&1; then
        open "$pdf_path" >/dev/null 2>&1 &
        return 0
    fi

    printf 'Built PDF: %s\n' "$pdf_path"
    printf 'No browser opener was found. Open the PDF manually.\n' >&2
}

active_file=${1:-}
[ -n "$active_file" ] || die "open a .tex file inside thesis/ and press F5."
[ -f "$active_file" ] || die "active file does not exist: $active_file"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
workspace_dir="$(cd -- "$script_dir/.." && pwd -P)"
thesis_dir="$workspace_dir/thesis"

[ -d "$thesis_dir" ] || die "thesis directory not found: $thesis_dir"
[ -x "$thesis_dir/render.sh" ] || die "render script is not executable: $thesis_dir/render.sh"

active_file="$(realpath -- "$active_file")"
thesis_dir="$(realpath -- "$thesis_dir")"

case "$active_file" in
    *.tex) ;;
    *) die "active file is not a .tex file: $active_file" ;;
esac

relative_input="$(realpath --relative-to="$thesis_dir" "$active_file")"
case "$relative_input" in
    ..|../*|/*)
        die "active file must be inside $thesis_dir"
        ;;
esac

cd -- "$thesis_dir"
set +e
./render.sh --input "$relative_input"
render_status=$?
set -e

if [ "$render_status" -ne 0 ] && [ "$render_status" -ne 4 ]; then
    exit "$render_status"
fi

pdf_path="$thesis_dir/${relative_input%.tex}.pdf"
[ -f "$pdf_path" ] || die "render completed, but no PDF was found at $pdf_path"

printf 'Built PDF: %s\n' "$pdf_path"

if [ "${THESIS_VSCODE_NO_BROWSER:-}" = "1" ]; then
    exit "$render_status"
fi

open_pdf_in_browser "$pdf_path"
exit "$render_status"
