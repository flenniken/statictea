## See utf8project for tests and source code.

import std/unittest
import utf8decoder

suite "utf8decoder.nim":

  test "tests in project utf8tests":
    check 1 == 1

  test "utf8CharString":
    check utf8CharString("abc", 0) == "a"

