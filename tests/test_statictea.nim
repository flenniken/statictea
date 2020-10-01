import unittest
import statictea

suite "Test statictea.nim":

  test "main":
    let rc = main()
    echo rc
