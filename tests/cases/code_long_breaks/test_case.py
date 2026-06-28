from pathlib import Path

import fitz

from tests.lib import pdf
from tests.lib.assertions import (
    assert_build_succeeded,
    assert_log_not_contains,
    assert_pdf_contains,
)
from tests.lib.latex import build_latex_case


def test_oversized_code_blocks_break_before_footer(tmp_path: Path):
    case_dir = tmp_path / "case"
    case_dir.mkdir()
    build_dir = tmp_path / "build"
    build_dir.mkdir()

    (case_dir / "long-source.txt").write_text(
        "\n".join(f"file-code-line-{line:03d}" for line in range(1, 141)) + "\n",
        encoding="utf-8",
    )
    direct_code = "\n".join(f"direct-code-line-{line:03d}" for line in range(1, 141))
    (case_dir / "main.tex").write_text(
        f"""\\documentclass[a4paper,12pt]{{report}}
\\usepackage[romanian,custom]{{config}}

\\begin{{document}}
\\chapter{{Long Code}}
Long file code reference: \\ref{{code:long-file}}.
Long direct code reference: \\ref{{code:long-direct}}.

\\insertCodeFile[code:long-file][linenos=false]{{text}}{{long-source.txt}}{{Long file listing}}

\\begin{{code}}[code:long-direct][linenos=false]{{text}}{{Long direct listing}}
{direct_code}
\\end{{code}}
\\end{{document}}
""",
        encoding="utf-8",
    )

    result = build_latex_case(case_dir, build_dir)

    assert_build_succeeded(result)
    assert_pdf_contains(result, "Long file code reference: 1.1.")
    assert_pdf_contains(result, "Long direct code reference: 1.2.")
    assert_pdf_contains(result, "file-code-line-001")
    assert_pdf_contains(result, "file-code-line-140")
    assert_pdf_contains(result, "direct-code-line-001")
    assert_pdf_contains(result, "direct-code-line-140")
    assert_log_not_contains(result, "Float too large")

    code_line_pages_by_prefix = {"file-code-line-": set(), "direct-code-line-": set()}
    text_bottom_tolerance = 5
    with fitz.open(result.pdf_path) as doc:
        for page_index, page in enumerate(doc):
            text_bottom = page.rect.height - 20 * 72 / 25.4 + text_bottom_tolerance
            for word in page.get_text("words"):
                matching_prefix = next(
                    (
                        prefix
                        for prefix in code_line_pages_by_prefix
                        if word[4].startswith(prefix)
                    ),
                    None,
                )
                if matching_prefix is None:
                    continue
                code_line_pages_by_prefix[matching_prefix].add(page_index)
                assert fitz.Rect(word[:4]).y1 <= text_bottom

    assert pdf.page_count(result.pdf_path) > 1
    assert all(len(pages) > 1 for pages in code_line_pages_by_prefix.values())
