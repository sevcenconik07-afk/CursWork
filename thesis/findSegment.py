import sys
import os

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


def main():
    filePath = sys.argv[1]
    segmentName = sys.argv[2]
    extraOptions = sys.argv[3].strip() if len(sys.argv) > 3 else ""
    language = os.path.splitext(filePath)[1].lstrip(".").lower()

    if language not in COMMENT_STYLES:
        print_warning(segmentName, filePath)
        return 0

    if not os.path.exists(filePath):
        print_warning(segmentName, filePath)
        return 0

    commentStringStart, commentStringEnd = COMMENT_STYLES[language]
    segmentBeginString = f"{commentStringStart} Segment {segmentName} begin{commentStringEnd}"
    segmentEndString = f"{commentStringStart} Segment {segmentName} end{commentStringEnd}"

    segmentBegin = -1
    segmentEnd = -1
    with open(filePath, "r", encoding="utf-8") as fp:
        for index, line in enumerate(fp):
            if segmentBeginString in line:
                segmentBegin = index
            if segmentEndString in line:
                segmentEnd = index

    if segmentBegin == -1 or segmentEnd == -1 or segmentEnd <= segmentBegin:
        print_warning(segmentName, filePath)
        return 0

    options = f"firstline={segmentBegin + 2},lastline={segmentEnd}"
    if extraOptions:
        options = f"{options},{extraOptions}"

    print(f"\\inputminted[{options}]{{{language}}}{{{filePath}}}", flush=True)
    return 0


try:
    raise SystemExit(main())
except BrokenPipeError:
    sys.stderr.close()
