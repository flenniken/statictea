import std/unittest
import std/os
import opresult
import sharedtestcode
import comparelines

proc testCompareFilesEqual(content1: string, content2: string): bool =

  let f1 = "f1.txt"
  let f2 = "f2.txt"

  createFile(f1, content1)
  createFile(f2, content2)

  result = true
  let stringOp = compareFiles(f1, f2)
  if stringOp.isValue:
    if stringOp.value != "":
      echo "got:"
      echo stringOp.value
      echo "expected message: ''"
      echo "---"
      result = false
  else:
    echo "got: " & stringOp.message
    result = false

  discard tryRemoveFile(f1)
  discard tryRemoveFile(f2)

proc testCompareFilesDifferent(content1: string, content2: string, expected: string): bool =

  let f1 = "f1.txt"
  let f2 = "f2.txt"

  createFile(f1, content1)
  createFile(f2, content2)

  result = true
  let stringOp = compareFiles(f1, f2)
  if stringOp.isMessage:
    # Unable to compare the files.
    if expected != stringOp.message:
      echo "Unable to compare the files."
      echo "     got: " & stringOp.message
      echo "expected: " & expected
      result = false
  else:
    # Able to compare and differences in the value.
    if expected != stringOp.value:
      echo "     got-----------"
      echo stringOp.value
      echo "expected-----------"
      echo expected
      result = false

  discard tryRemoveFile(f1)
  discard tryRemoveFile(f2)

proc testLinesSideBySide(content1: string, content2: string,
    expected: string): bool =
  ## Test linesSideBySide.

  let str = linesSideBySide(content1, content2)
  if str != expected:
    echo "got:"
    echo str
    echo "expected:"
    echo expected
    result = false
  else:
    result = true


suite "comparelines.nim":

  test "showTabsAndLineEndings":
    check showTabsAndLineEndings("asdf") == "asdf"
    check showTabsAndLineEndings("asdf\n") == "asdf␊"
    check showTabsAndLineEndings("asdf\r\n") == "asdf␍␊"
    check showTabsAndLineEndings("	asdf") == "␉asdf"
    check showTabsAndLineEndings(" 	 asdf") == " ␉ asdf"

  test "showTabsAndLineEndings others":
    check showTabsAndLineEndings("abc\0def") == "abc\x00def"
    check showTabsAndLineEndings("abc\1def") == "abc\x01def"
    check showTabsAndLineEndings("abc\2def") == "abc\x02def"
    check showTabsAndLineEndings("abc\3def") == "abc\x03def"
    check showTabsAndLineEndings("abc\4def") == "abc\x04def"
    check showTabsAndLineEndings("abc\5def") == "abc\x05def"
    check showTabsAndLineEndings("abc\6def") == "abc\x06def"
    check showTabsAndLineEndings("abc\7def") == "abc\x07def"

  test "linesSideBySide empty":
    let content1 = ""
    let content2 = ""
    let expected = "both empty"
    check testLinesSideBySide(content1, content2, expected)

  test "linesSideBySide1":
    let content1 = """
my expected line
"""
    let content2 = """
what I got
"""
    let expected = """
1      got: my expected line␊
1 expected: what I got␊"""
    check testLinesSideBySide(content1, content2, expected)

  test "linesSideBySide2":
    let content1 = """
my expected line
my second line
"""
    let content2 = """
my expected line
what I got
"""
    let expected = """
1     same: my expected line␊
2      got: my second line␊
2 expected: what I got␊"""
    check testLinesSideBySide(content1, content2, expected)

  test "linesSideBySide3":
    let content1 = """
my expected line
middle
my last line
"""
    let content2 = """
my expected line
  the center
my last line
"""
    let expected = """
1     same: my expected line␊
2      got: middle␊
2 expected:   the center␊
3     same: my last line␊"""
    check testLinesSideBySide(content1, content2, expected)


  test "compareFiles":
    check testCompareFilesEqual("test file", "test file")
    check testCompareFilesEqual("", "")
    check testCompareFilesEqual("""
""","""
""")
    check testCompareFilesEqual("""
multi line file
test
123 5
""","""
multi line file
test
123 5
""")

  test "compareFiles different 1":
    let f1 = """
test file
"""
    let f2 = """
hello there
"""
    let expected = """

Difference: f1.txt (got) != f2.txt (expected)
1      got: test file␊
1 expected: hello there␊
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 2":
    let f1 = """
test line
different line
"""
    let f2 = """
test line
wow we
"""
    let expected = """

Difference: f1.txt (got) != f2.txt (expected)
1     same: test line␊
2      got: different line␊
2 expected: wow we␊
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 3":
    let f1 = """
test line
third line
more
"""
    let f2 = """
test line
something else
more
"""
    let expected = """

Difference: f1.txt (got) != f2.txt (expected)
1     same: test line␊
2      got: third line␊
2 expected: something else␊
3     same: more␊
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 4":
    let f1 = ""
    let f2 = """
test line
something else
more
"""
    let expected = """

Difference: f1.txt != f2.txt
            f1.txt is empty
f2.txt───────────────────⤵
test line
something else
more
───────────────────⤴
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 5":
    let f1 = """
test line
something else
more
"""
    let f2 = ""

    let expected = """

Difference: f1.txt != f2.txt
            f2.txt is empty
f1.txt───────────────────⤵
test line
something else
more
───────────────────⤴
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles no file":
    let rcOp = compareFiles("f1", "f2")
    check rcOp.isMessage
    check rcOp.message == "Error: cannot open: f1"
