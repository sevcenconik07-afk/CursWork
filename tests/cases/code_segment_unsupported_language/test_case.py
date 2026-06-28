from tests.lib.assertions import (
    assert_build_failed,
    assert_log_contains,
    assert_log_not_contains,
    assert_pdf_contains,
    assert_pdf_not_contains,
)


def test_unsupported_code_segment_language_warns_clearly(build):
    assert_build_failed(build)
    assert_pdf_contains(build, "ATENȚIE: limbajul pentru segmentul de cod nu este suportat")
    assert_pdf_contains(build, "sql")
    assert_pdf_contains(build, "source.sql")
    assert_log_contains(
        build,
        "Package config Warning: Code segment language 'sql' is not supported for 'source.sql'",
    )
    assert_log_not_contains(build, "Code segment 'example' was not found in 'source.sql'")
    assert_pdf_not_contains(build, "segmentul de cod nu a fost găsit")
