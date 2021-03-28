
import regexes
import unittest
import version
import options

suite "version.nim":

  test "test version string":
    let matchesO = matchRegex(staticteaVersion, r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)
    if not matchesO.isSome:
      echo "Invalid version number: " & staticteaVersion
      fail
