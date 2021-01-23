
import regexes
import unittest
import version
import options

suite "version.nim":

  test "test version string":
    var matcher = newMatcher(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)
    let matchesO = matcher.getMatches(staticteaVersion, 0)
    if not matchesO.isSome:
      echo "Invalid version number: " & staticteaVersion
      fail
