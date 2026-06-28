from tests.lib import pdf
from tests.lib.assertions import assert_build_succeeded, assert_log_not_contains, assert_pdf_contains


def _word_x(result, text):
    matches = []
    for page_index in range(pdf.page_count(result.pdf_path)):
        for word in pdf.page_words(result.pdf_path, page_index):
            if word["text"] == text:
                matches.append(word["bbox"].x0)

    assert len(matches) == 1, f"Expected one PDF word {text!r}, found {len(matches)}"
    return matches[0]


def test_code_segment_autogobble_removes_uniform_indent(build):
    assert_build_succeeded(build)
    assert_pdf_contains(build, "Top segment reference: 1.1.")
    assert_pdf_contains(build, "Indented segment reference: 1.2.")
    assert_log_not_contains(build, "Package config Warning")

    top_variable_x = _word_x(build, "top_level")
    inner_variable_x = _word_x(build, "inner_value")
    assert abs(top_variable_x - inner_variable_x) < 1.0
