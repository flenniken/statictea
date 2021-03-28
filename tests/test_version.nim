
import unittest
import version
import options

suite "version.nim":

  test "test version string":
    let matchesO = matchVersion(staticteaVersion)
    if not matchesO.isSome:
      echo "Invalid StaticTea version number: " & staticteaVersion
      fail
