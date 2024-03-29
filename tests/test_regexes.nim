import std/unittest
import std/options
import std/strutils
import regexes
import sharedtestcode

proc testMatchPattern*(str: string, pattern: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches),
    numGroups: Natural = 0): bool =
  ## Test matchPattern
  let matchesO = matchPattern(str, pattern, start, numGroups)
  var header = """
line: "$1"
start: $2
pattern: $3""" % [str, $start, pattern]
  if not expectedItem(header, matchesO, eMatchesO):
    result = false
    echo ""
  else:
    result = true

suite "regexes.nim":
  test "newMatches 0":
    let m = newMatches(6, 3)
    check m.length == 6
    check m.start == 3
    check m.numGroups == 0
    check m.groups.len == 0

  test "newMatches 1":
    let m = newMatches(6, 3, "abc")
    check m.length == 6
    check m.start == 3
    check m.numGroups == 1
    check m.groups.len == 1
    check m.groups[0] == "abc"

  test "newMatches 2":
    let m = newMatches(6, 3, "abc", "def")
    check m.length == 6
    check m.start == 3
    check m.numGroups == 2
    check m.groups.len == 2
    check m.groups[0] == "abc"
    check m.groups[1] == "def"

  test "newMatches 3":
    let m = newMatches(6, 3, @["abc", "def", "ghi"])
    check m.length == 6
    check m.start == 3
    check m.numGroups == 3
    check m.groups.len == 3
    check m.groups[0] == "abc"
    check m.groups[1] == "def"
    check m.groups[2] == "ghi"

  test "newMatches 4":
    let m = newMatches(6, 3, @["abc", "def", "ghi", "jkl"])
    check m.length == 6
    check m.start == 3
    check m.numGroups == 4
    check m.groups.len == 4
    check m.groups[0] == "abc"
    check m.groups[1] == "def"
    check m.groups[2] == "ghi"
    check m.groups[3] == "jkl"

  test "no groups":
    let pattern = r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    check testMatchPattern("0.1.0", pattern, 0, some(newMatches(5, 0)))
    check testMatchPattern("0.12.345", pattern, 0, some(newMatches(8, 0)))
    check testMatchPattern("999.888.777", pattern, 0, some(newMatches(11, 0)))

  test "no match":
    let pattern = r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    check testMatchPattern("0.1", pattern, 0)
    check testMatchPattern("0.1.3456", pattern, 0)
    check testMatchPattern("0.1.a", pattern, 0)

  test "one simple match":
    let pattern = r".*abc$"
    check testMatchPattern("123 abc", pattern, 0, some(newMatches(7, 0)))

  test "no match":
    let pattern = r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$"
    check testMatchPattern("b.67.8", pattern)

  test "one group":
    let pattern = r"^.*(def)$"
    let matchesO = matchPattern("  abc asdfasdfdef def", pattern, 0, 1)
    check matchesO.isSome
    let (one, length) = matchesO.getGroupLen()
    check one == "def"
    check length == 21

    let groups0 = getGroups(matchesO, 0)
    check groups0.len == 0
    let groups1 = getGroups(matchesO, 1)
    check groups1.len == 1
    check groups1[0] == "def"
    let groups2 = getGroups(matchesO, 2)
    check groups2.len == 2
    check groups2[0] == "def"
    check groups2[1] == ""

  test "one group and len":
    let pattern = r"(def)\s*"
    let matchesO = matchPattern("def  ab", pattern, 0, 1)
    check matchesO.isSome
    let (one, length) = matchesO.getGroupLen()
    check one == "def"
    check length == 5

  test "two groups":
    let pattern = r"(abc).*(def)$"
    check testMatchPattern("  abc asdfasdfdef def", pattern, 2, some(newMatches(19, 2, "abc", "def")), 2)

    let matchesO = matchPattern("  abc asdfasdfdef def", pattern, 2, 2)
    check matchesO.isSome
    let (one, two, length) = matchesO.get2GroupsLen()
    check one == "abc"
    check two == "def"
    check length == 19

    let groups0 = getGroups(matchesO, 0)
    check groups0.len == 0
    let groups1 = getGroups(matchesO, 1)
    check groups1.len == 1
    check groups1[0] == "abc"
    let groups2 = getGroups(matchesO, 2)
    check groups2.len == 2
    check groups2[0] == "abc"
    check groups2[1] == "def"
    let groups3 = getGroups(matchesO, 3)
    check groups3.len == 3
    check groups3[0] == "abc"
    check groups3[1] == "def"
    check groups3[2] == ""

  test "unpack two groups":
    let pattern = r"(abc).*(def)$"
    let matchesO = matchPattern("  abc asdfasdfdef def", pattern, 2, 2)
    check matchesO.isSome
    let (one, two, length) = matchesO.get2GroupsLen()
    check one == "abc"
    check two == "def"
    check length == 19

  test "groups":
    let pattern = r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$"
    check testMatchPattern("999.888.777", pattern, 0, some(newMatches(11, 0, @["999", "888", "777"])), 3)
    check testMatchPattern("5.67.8", pattern, 0, some(newMatches(6, 0, @["5", "67", "8"])), 3)
    let matchesO = matchPattern("5.67.8", pattern, 0, 3)
    check matchesO.isSome
    let groups = matchesO.getGroups(3)
    check groups[0] == "5"
    check groups[1] == "67"
    check groups[2] == "8"

  test "start not zero":
    # Using ^ to anchor doesn't work as I expect when start is not 0.
    # let matcher = newMatcher(r"^(abc)", 1)

    let pattern = r"(abc)"
    check testMatchPattern("  abc asdfasdfdef def", pattern, 2, some(newMatches(3, 2, "abc")), 1)

  test "matchPattern":
    let pattern = r".*ll(o)(testing)*"
    check testMatchPattern("hellotesting", pattern, 0, some(newMatches(12, 0, "o", "testing")), 2)

  test "matchPattern one match":
    check testMatchPattern("nomatch", ".*match", 0, some(newMatches(7, 0)))

  test "matchPattern one group":
    check testMatchPattern("nomatch", ".*(match)", 0, some(newMatches(7, 0, "match")), 1)

  test "matchPattern two groups":
    check testMatchPattern("yesmatch", "(yes)(match)", 0, some(newMatches(8, 0, "yes", "match")), 2)

  test "matchPattern 3 groups":
    let eMatchesO = some(newMatches(3, 0, @["y", "e", "s"]))
    check testMatchPattern("yesmatches", "(y)(e)(s)", 0, eMatchesO, 3)

  test "matchPattern length":
    check testMatchPattern("   match = ", ".*(match) =", 0, some(newMatches(10, 0, "match")), 1)

  test "matchPattern start":
    check testMatchPattern("   match = ", ".*(match) =", 3, some(newMatches(7, 3, "match")), 1)

  test "matchPattern anchor":
    check testMatchPattern("match = asdf", "^match", 0, some(newMatches(5, 0)))

  test "matchPattern start anchor":
    # This doesn't match because nim sets the anchor option.
    check testMatchPattern(" match = asdf", "^match", 1)

  test "matchPattern no match":
    check testMatchPattern("nomatch", "he(ll)o")
    check testMatchPattern("hellotesting", "ll(o8)(testing)*")
    check testMatchPattern("nomatch", ".*match3")
    check testMatchPattern("nomattchtjj", ".*match")
    check testMatchPattern("nomatch", ".*(match) ")
    check testMatchPattern("yesmatch", "(yes)7(match)")
    check testMatchPattern("yesmatches", "(y)(s)(m)(a)(t)(c)(h)(e)(s)")
    check testMatchPattern("   match = ", "(match) =")
    check testMatchPattern("   match = ", "(match) 7", 3)
    check testMatchPattern(" match = asdf", "^match")

  test "matchPattern exception":
    # The pattern has unmatched parentheses which generates an
    # expection in the compilePattern method.
    let pattern = r"^----------file: ([^\s]*)\s(\([^)]\)\s*$"
    let matchesO = matchPattern("line", pattern, 0, 0)
    check matchesO.isSome == false

  test "doc comment example":
    ## Match a string with "abc" in it.
    let line = "123abc456"
    let pattern = ".*abc"
    let matchesO = matchPattern(line, pattern, start=0, numGroups=0)
    check matchesO.isSome == true
    check matchesO.get().length == 6

  test "doc comment example 3":

    ## Replace the patterns in the string with their replacements.

    var replacements: seq[Replacement]
    replacements.add(newReplacement("abc", "456"))
    replacements.add(newReplacement("def", ""))

    let resultStringO = replaceMany("abcdefabc", replacements)
    check resultStringO.isSome
    check resultStringO.get() == "456456"
