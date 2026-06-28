import sys
import os
import hashlib
from pathlib import Path

COMMENT_STYLES = {
    "zig": ("//", ""),
    "js": ("//", ""),
    "cpp": ("//", ""),
    "c": ("//", ""),
    "cs": ("//", ""),
    "java": ("//", ""),
    "go": ("//", ""),
    "bash": ("#", ""),
    "py": ("#", ""),
    "lua": ("%", ""),
}


def latex_escape(value):
    replacements = {
        "\\": r"\textbackslash{}",
        "{": r"\{",
        "}": r"\}",
        "#": r"\#",
        "$": r"\$",
        "%": r"\%",
        "&": r"\&",
        "_": r"\_",
        "^": r"\textasciicircum{}",
        "~": r"\textasciitilde{}",
    }
    return "".join(replacements.get(char, char) for char in value)


def print_warning(segment_name, file_path):
    print(
        "\\codeSegmentWarning"
        f"{{{latex_escape(segment_name)}}}"
        f"{{{latex_escape(file_path)}}}",
        flush=True,
    )


def print_unsupported_language_warning(language, file_path):
    print(
        "\\codeSegmentUnsupportedLanguageWarning"
        f"{{{latex_escape(language)}}}"
        f"{{{latex_escape(file_path)}}}",
        flush=True,
    )


def generated_segment_path(file_path, segment_name, language):
    cache_key = f"{Path(file_path).resolve()}\0{segment_name}".encode("utf-8")
    file_hash = hashlib.sha256(cache_key).hexdigest()[:16]
    segment_dir = Path("generated-code-segments")
    segment_dir.mkdir(exist_ok=True)
    return segment_dir / f"{file_hash}.{language}"


def main():
    filePath = sys.argv[1]
    segmentName = sys.argv[2]
    extraOptions = sys.argv[3].strip() if len(sys.argv) > 3 else ""
    language = os.path.splitext(filePath)[1].lstrip(".").lower()

    if language not in COMMENT_STYLES:
        print_unsupported_language_warning(language or "unknown", filePath)
        return 0

    if not os.path.exists(filePath):
        print_warning(segmentName, filePath)
        return 0

    commentStringStart, commentStringEnd = COMMENT_STYLES[language]
    segmentBeginString = f"{commentStringStart} Segment {segmentName} begin{commentStringEnd}"
    segmentEndString = f"{commentStringStart} Segment {segmentName} end{commentStringEnd}"

    segmentBegin = -1
    segmentEnd = -1
    lines = []
    with open(filePath, "r", encoding="utf-8") as fp:
        lines = fp.readlines()
        for index, line in enumerate(lines):
            if segmentBeginString in line:
                segmentBegin = index
            if segmentEndString in line:
                segmentEnd = index

    if segmentBegin == -1 or segmentEnd == -1 or segmentEnd <= segmentBegin:
        print_warning(segmentName, filePath)
        return 0

    segment_path = generated_segment_path(filePath, segmentName, language)
    segment_path.write_text("".join(lines[segmentBegin + 1 : segmentEnd]), encoding="utf-8")

    options = f"firstnumber={segmentBegin + 2}"
    if extraOptions:
        options = f"{options},{extraOptions}"

    print(f"\\inputminted[{options}]{{{language}}}{{{segment_path}}}", flush=True)
    return 0


try:
    raise SystemExit(main())
except BrokenPipeError:
    sys.stderr.close()
