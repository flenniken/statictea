import regexes
import unittest
import options
import strutils

suite "regexes.nim":

  test "match":
    let pattern = getPattern(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)

    check getMatches("0.1.0", pattern).get().length == 5
    check getMatches("0.12.345", pattern).get().length == 8
    check getMatches("999.888.777", pattern).get().length == 11

  test "no match":
    let pattern = getPattern(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)
    check not getMatches("0.1", pattern).isSome
    check not getMatches("0.1.3456", pattern).isSome
    check not getMatches("0.1.a", pattern).isSome

  test "getMatches":
    let pattern = getPattern(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$", 3)
    let matchesO = getMatches("5.67.8", pattern)
    check matchesO.isSome
    let matches = matchesO.get()
    let (g1, g2, g3) = get3Groups(matches)
    check matches.groups.len == 3
    check g1 == "5"
    check g2 == "67"
    check g3 == "8"

  test "getMatches1":
    let pattern = getPattern(r".*abc$", 0)
    let matchesO = getMatches("123 abc", pattern)
    check matchesO.isSome

  test "getMatches no match":
    let pattern = getPattern(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$", 3)
    check not getMatches("b.67.8", pattern).isSome

  test "lastPart":
    let pattern = getPattern(r"([^\\]*)([\\]{0,1})(\Q-->\E[\r]{0,1}\n)$", 3)
    var line = "<--$\t nextline " & $'\\' & "-->\n"
    var matchesO = getMatches(line, pattern)
    check matchesO.isSome
    let (a, b, c) = matchesO.get().get3Groups()
    echo line
    echo "a = ($1)'$2'" % [$a.len, a]
    echo "b = ($1)'$2'" % [$b.len, b]
    echo "c = ($1)'$2'" % [$c.len, c]
