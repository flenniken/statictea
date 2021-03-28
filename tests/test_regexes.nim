import regexes
import unittest
import options

suite "regexes.nim":
  test "no groups":
    let pattern = r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    check testMatchRegex("0.1.0", pattern, 0, some(newMatches(5, 0)))
    check testMatchRegex("0.12.345", pattern, 0, some(newMatches(8, 0)))
    check testMatchRegex("999.888.777", pattern, 0, some(newMatches(11, 0)))

  test "no match":
    let pattern = r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    check testMatchRegex("0.1", pattern, 0)
    check testMatchRegex("0.1.3456", pattern, 0)
    check testMatchRegex("0.1.a", pattern, 0)

  test "one simple match":
    let pattern = r".*abc$"
    check testMatchRegex("123 abc", pattern, 0, some(newMatches(7, 0)))

  test "no match":
    let pattern = r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$"
    check testMatchRegex("b.67.8", pattern)

  test "one group":
    let pattern = r"^.*(def)$"
    let matchesO = matchRegex("  abc asdfasdfdef def", pattern, 0)
    check matchesO.isSome
    let one = matchesO.get().getGroup()
    check one == "def"

  test "two groups":
    let pattern = r"(abc).*(def)$"
    check testMatchRegex("  abc asdfasdfdef def", pattern, 2, some(newMatches(19, 2, "abc", "def")))

    let matchesO = matchRegex("  abc asdfasdfdef def", pattern, 2)
    check matchesO.isSome
    let (one, two) = matchesO.get().get2Groups()
    check one == "abc"
    check two == "def"

  test "three groups":
    let pattern = r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$"
    check testMatchRegex("999.888.777", pattern, 0, some(newMatches(11, 0, "999", "888", "777")))
    check testMatchRegex("5.67.8", pattern, 0, some(newMatches(6, 0, "5", "67", "8")))
    let matchesO = matchRegex("5.67.8", pattern, 0)
    check matchesO.isSome
    let (one, two, three) = matchesO.get().get3Groups()
    check one == "5"
    check two == "67"
    check three == "8"

  test "start not zero":
    # Using ^ to anchor doesn't work as I expect when start is not 0.
    # let matcher = newMatcher(r"^(abc)", 1)

    let pattern = r"(abc)"
    check testMatchRegex("  abc asdfasdfdef def", pattern, 2, some(newMatches(3, 2, "abc")))

  test "matchRegex":
    let pattern = r".*ll(o)(testing)*"
    check testMatchRegex("hellotesting", pattern, 0, some(newMatches(12, 0, "o", "testing")))

  test "matchRegex one match":
    check testMatchRegex("nomatch", ".*match", 0, some(newMatches(7, 0)))

  test "matchRegex one group":
    check testMatchRegex("nomatch", ".*(match)", 0, some(newMatches(7, 0, "match")))

  test "matchRegex two groups":
    check testMatchRegex("yesmatch", "(yes)(match)", 0, some(newMatches(8, 0, "yes", "match")))

  test "matchRegex 10 groups":
    let eMatchesO = some(newMatches(10, 0, "y", "e", "s", "m", "a", "t", "c", "h", "e", "s"))
    check testMatchRegex("yesmatches", "(y)(e)(s)(m)(a)(t)(c)(h)(e)(s)", 0, eMatchesO)

  test "matchRegex length":
    check testMatchRegex("   match = ", ".*(match) =", 0, some(newMatches(10, 0, "match")))

  test "matchRegex start":
    check testMatchRegex("   match = ", ".*(match) =", 3, some(newMatches(7, 3, "match")))

  test "matchRegex anchor":
    check testMatchRegex("match = asdf", "^match", 0, some(newMatches(5, 0)))

  test "matchRegex start anchor":
    # This doesn't match because nim sets the anchor option.
    check testMatchRegex(" match = asdf", "^match", 1)

  test "matchRegex no match":
    check testMatchRegex("nomatch", "he(ll)o")
    check testMatchRegex("hellotesting", "ll(o8)(testing)*")
    check testMatchRegex("nomatch", ".*match3")
    check testMatchRegex("nomattchtjj", ".*match")
    check testMatchRegex("nomatch", ".*(match) ")
    check testMatchRegex("yesmatch", "(yes)7(match)")
    check testMatchRegex("yesmatches", "(y)(s)(m)(a)(t)(c)(h)(e)(s)")
    check testMatchRegex("   match = ", "(match) =")
    check testMatchRegex("   match = ", "(match) 7", 3)
    check testMatchRegex(" match = asdf", "^match")
