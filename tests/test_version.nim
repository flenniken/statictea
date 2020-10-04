
import regex
import unittest
import version

suite "Test version.nim":

  test "test version string":
    let pattern = getPattern(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
    if not match(staticteaVersion, pattern):
      echo "Invalid version number: " & staticteaVersion
      fail
