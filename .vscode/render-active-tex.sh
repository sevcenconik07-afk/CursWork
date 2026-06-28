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

open_pdf_in_browser() {
    local pdf_path=$1
    local uri windows_path

    if is_wsl && command -v wslpath >/dev/null 2>&1 && command -v powershell.exe >/dev/null 2>&1; then
        windows_path="$(wslpath -w "$pdf_path")"
        if powershell.exe -NoProfile -Command "& { param([string]\$path) \$uri = [System.Uri]::new(\$path).AbsoluteUri; Start-Process \$uri }" "$windows_path" >/dev/null 2>&1; then
            return 0
        fi
    fi

    if is_wsl && command -v wslpath >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
        windows_path="$(wslpath -m "$pdf_path")"
        case "$windows_path" in
            //*|[[:alpha:]]:/*)
                uri="file:$windows_path"
                if [ "${windows_path:0:2}" != "//" ]; then
                    uri="file:///$windows_path"
                fi
                cmd.exe /C start "" "$uri" >/dev/null 2>&1 &
                return 0
                ;;
        esac
    fi

    if is_wsl && command -v wslpath >/dev/null 2>&1 && command -v explorer.exe >/dev/null 2>&1; then
        windows_path="$(wslpath -w "$pdf_path")"
        explorer.exe "$windows_path" >/dev/null 2>&1 &
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

render_args=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -f|--force)
            render_args+=(--force)
            shift
            ;;
        *)
            break
            ;;
    esac
done

active_file=${1:-}
[ -n "$active_file" ] || die "open a .tex file inside thesis/ and press F5."
[ -f "$active_file" ] || die "active file does not exist: $active_file"
if [ "$#" -gt 1 ]; then
    die "unexpected arguments after active file: ${*:2}"
fi

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
./render.sh "${render_args[@]}" --input "$relative_input"
render_status=$?
set -e

if [ "$render_status" -ne 0 ] && [ "$render_status" -ne 4 ]; then
    exit "$render_status"
fi

pdf_path="$thesis_dir/${relative_input%.tex}.pdf"
[ -f "$pdf_path" ] || die "render completed, but no PDF was found at $pdf_path"

printf 'Built PDF: %s\n' "$pdf_path"

if [ "${THESIS_VSCODE_NO_BROWSER:-}" = "1" ]; then
    if [ "$render_status" -eq 4 ]; then
        exit 0
    fi

    exit "$render_status"
fi

open_pdf_in_browser "$pdf_path"
if [ "$render_status" -eq 4 ]; then
    exit 0
fi

exit "$render_status"
