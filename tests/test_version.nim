
import regexes
import unittest
import version
import options

suite "Test version.nim":

  test "test version string":
    let pattern = getPattern(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)
    let matchesO = getMatches(staticteaVersion, pattern)
    if not matchesO.isSome:
      echo "Invalid version number: " & staticteaVersion
      fail
