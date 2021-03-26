import regexes
import unittest
import options
import tables
import vartypes
import env

proc newMatcherDict(length: Natural, groups: varargs[string]): VarsDict =
    result["len"] = newValue(length)
    for ix, group in groups:
      result["g" & $ix] = newValue(group)

proc testMatchRegex(str: string, pattern: string, start: Natural = 0,
    eVarsDictO: Option[VarsDict] = none(VarsDict)): bool =
  ## Test matchRegex
  let varsDictO = matchRegex(str, pattern, start)
  if not expectedItem("varsDictO", varsDictO, eVarsDictO):
    result = false
  else:
    result = true

suite "regexes.nim":
  test "startPointer":
    check startPointer(0) == "^0"
    check startPointer(1) == " ^1"
    check startPointer(2) == "  ^2"
    check startPointer(101) == "101"

  test "checkMatcher":
    # Uncomment to test output for cases the don't match.

    # var abcMatcher = newMatcher(r"(abc)\s+", 1)
    # check checkMatcher(abcMatcher, " abc   def", 0, @["abc"], 6)
    # check checkMatcher(abcMatcher, "abc   def", 0, @["abe"], 6)
    # check checkMatcher(abcMatcher, "abc   def", 0, @["abc"], 7)
    # var matcher = newMatcher(r"(abc)(\s+)", 2)
    # check checkMatcher(matcher, "abc   def", 0, @["abc", "1"], 7)
    # check checkMatcher(matcher, "abc   def", 3, @["abc", "1"], 7)
    discard

  test "no groups":
    var versionMatcher = newMatcher(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)
    check checkMatcher(versionMatcher, "0.1.0", 0, @[], 5)
    check checkMatcher(versionMatcher, "0.12.345", 0, @[], 8)
    check checkMatcher(versionMatcher, "999.888.777", 0, @[], 11)

  test "no match":
    var matcher = newMatcher(r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", 0)
    check not getMatches(matcher, "0.1", 0).isSome
    check not getMatches(matcher, "0.1.3456", 0).isSome
    check not getMatches(matcher, "0.1.a", 0).isSome

  test "getMatches1":
    let matcher = newMatcher(r".*abc$", 0)
    check checkMatcher(matcher, "123 abc", 0, @[], 7)

  test "getMatches no match":
    let matcher = newMatcher(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$", 3)
    check not getMatches(matcher, "b.67.8").isSome

  test "one group":
    let matcher = newMatcher(r"^.*(def)$", 1)
    let matchesO = getMatches(matcher, "  abc asdfasdfdef def", 0)
    check matchesO.isSome
    let one = matchesO.get().getGroup()
    check one == "def"

  test "two groups":
    let matcher = newMatcher(r"(abc).*(def)$", 2)
    check checkMatcher(matcher, "  abc asdfasdfdef def", 2, @["abc", "def"], 19)

    let matchesO = getMatches(matcher, "  abc asdfasdfdef def", 2)
    check matchesO.isSome
    let (one, two) = matchesO.get().get2Groups()
    check one == "abc"
    check two == "def"

  test "three groups":
    let versionMatcher = newMatcher(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$", 3)
    check checkMatcher(versionMatcher, "999.888.777", 0, @["999", "888", "777"], 11)
    check checkMatcher(versionMatcher, "5.67.8", 0, @["5", "67", "8"], 6)
    let matchesO = getMatches(versionMatcher, "5.67.8", 0)
    check matchesO.isSome
    let (one, two, three) = matchesO.get().get3Groups()
    check one == "5"
    check two == "67"
    check three == "8"

  test "start not zero":
    # Using ^ to anchor doesn't work as I expect when start is not 0.
    # let matcher = newMatcher(r"^(abc)", 1)

    let matcher = newMatcher(r"(abc)", 1)
    check checkMatcher(matcher, "  abc asdfasdfdef def", 2, @["abc"], 3)

  test "matchRegex":
    let eVarsDictO = some(newMatcherDict(12, "o", "testing"))
    check testMatchRegex("hellotesting", r".*ll(o)(testing)*", 0, eVarsDictO = eVarsDictO)

  test "matchRegex one match":
    let eVarsDictO = some(newMatcherDict(7))
    check testMatchRegex("nomatch", ".*match", 0, eVarsDictO = eVarsDictO)

  test "matchRegex one group":
    let eVarsDictO = some(newMatcherDict(7, "match"))
    check testMatchRegex("nomatch", ".*(match)", 0, eVarsDictO = eVarsDictO)

  test "matchRegex two groups":
    let eVarsDictO = some(newMatcherDict(8, "yes", "match"))
    check testMatchRegex("yesmatch", "(yes)(match)", 0, eVarsDictO = eVarsDictO)

  test "matchRegex 10 groups":
    let eVarsDictO = some(newMatcherDict(10, "y", "e", "s", "m", "a", "t", "c", "h", "e", "s"))
    check testMatchRegex("yesmatches", "(y)(e)(s)(m)(a)(t)(c)(h)(e)(s)", 0, eVarsDictO = eVarsDictO)

  test "matchRegex length":
    let eVarsDictO = some(newMatcherDict(10, "match"))
    check testMatchRegex("   match = ", ".*(match) =", 0, eVarsDictO = eVarsDictO)

  test "matchRegex start":
    let eVarsDictO = some(newMatcherDict(7, "match"))
    check testMatchRegex("   match = ", ".*(match) =", 3, eVarsDictO = eVarsDictO)

  test "matchRegex anchor":
    let eVarsDictO = some(newMatcherDict(5))
    check testMatchRegex("match = asdf", "^match", 0, eVarsDictO = eVarsDictO)

  test "matchRegex start anchor":
    # This behaves this way because nim sets the anchor option.
    check testMatchRegex(" match = asdf", "^match", 1, eVarsDictO = none(VarsDict))

  test "matchRegex no match":
    check testMatchRegex("nomatch", "he(ll)o", 0)
    check testMatchRegex("hellotesting", "ll(o8)(testing)*", 0)
    check testMatchRegex("nomatch", ".*match3", 0)
    check testMatchRegex("nomattchtjj", ".*match", 0)
    check testMatchRegex("nomatch", ".*(match) ", 0)
    check testMatchRegex("yesmatch", "(yes)7(match)", 0)
    check testMatchRegex("yesmatches", "(y)(s)(m)(a)(t)(c)(h)(e)(s)")
    check testMatchRegex("   match = ", "(match) =", 0)
    check testMatchRegex("   match = ", "(match) 7", 3)
    check testMatchRegex(" match = asdf", "^match", 0)
