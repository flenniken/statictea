import std/unittest
import std/options
import version

suite "version.nim":

  test "test version string":
    let matchesO = matchVersion(staticteaVersion)
    if not matchesO.isSome:
      echo "Invalid StaticTea version number: " & staticteaVersion
      fail
