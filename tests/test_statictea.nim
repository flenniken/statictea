import unittest
import statictea
# import version
# import streams

suite "Test statictea.nim":

  test "main":
    let rc = main(@["-v"])
    check rc == 0

    # check output.len == 1
    # check output[0] == $staticteaVersion
