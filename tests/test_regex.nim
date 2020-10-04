
import regex
import unittest

suite "regex.nim":

  test "match":
    let pattern = getPattern(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
    check match("0.1.0", pattern)
    check match("0.12.345", pattern)
    check match("999.888.777", pattern)

  test "no match":
    let pattern = getPattern(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
    check not match("0.1", pattern)
    check not match("0.1.3456", pattern)
    check not match("0.1.a", pattern)

  test "matches":
    let pattern = getPattern(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$")
    var groups: array[3, string]
    check matches("5.67.8", pattern, groups)
    check groups[0] == "5"
    check groups[1] == "67"
    check groups[2] == "8"

  test "no matches":
    let pattern = getPattern(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$")
    var groups: array[3, string]
    check not matches("a.67.8", pattern, groups)
