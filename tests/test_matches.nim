
import unittest
import matches
import tables
import options
import regexes
import strutils

proc checkGetLastPart(matcher: Matcher, line: string, expectedStart: Natural,
    expected: seq[string], expectedLength: Natural) =
  let matchesO = getLastPart(matcher, line)
  check checkMatches(matchesO, matcher, line, expectedStart,
    expected, expectedLength)

suite "matches.nim":

  test "prepost table":
    var prepostTable = getPrepostTable()
    check prepostTable.len == 6
    for prefix, postfix in prepostTable.pairs:
      check prefix.len > 0
      # echo "$1 nextline $2" % [prefix, postfix]
    check prepostTable["<--!$"] == "-->"

  test "prefixMatcher tests":
    var prefixMatcher = getPrefixMatcher(getPrepostTable())

    check checkMatcher(prefixMatcher, "<--!$ nextline -->", 0, @["<--!$"], 6)
    check checkMatcher(prefixMatcher, "#$ nextline", 0, @["#$"], 3)
    check checkMatcher(prefixMatcher, ";$ nextline", 0, @[";$"], 3)
    check checkMatcher(prefixMatcher, "//$ nextline", 0, @["//$"], 4)
    check checkMatcher(prefixMatcher, "/*$ nextline */", 0, @["/*$"], 4)
    check checkMatcher(prefixMatcher, "&lt;!--$ nextline --&gt;", 0, @["&lt;!--$"], 9)
    check checkMatcher(prefixMatcher, "<--!$ : -->", 0, @["<--!$"], 6)
    check checkMatcher(prefixMatcher, "<--!$         nextline -->", 0, @["<--!$"], 14)
    check checkMatcher(prefixMatcher, "<--!$\tnextline -->", 0, @["<--!$"], 6)
    check checkMatcher(prefixMatcher, "#$ nextline\n", 0, @["#$"], 3)
    check checkMatcher(prefixMatcher, "#$ nextline   \n", 0, @["#$"], 3)
    check checkMatcher(prefixMatcher, "#$ nextline   \\\n", 0, @["#$"], 3)

    check not prefixMatcher.getMatches("<--$ nextline -->", 0).isSome
    check not prefixMatcher.getMatches("<--!$nextline -->", 0).isSome

  test "add prefix":
    var prepostList = @[("abc", "def")]
    var prepostTable = getPrepostTable(prepostList)
    check prepostTable.len == 7
    check prepostTable["abc"] == "def"
    var prefixMatcher = getPrefixMatcher(prepostTable)
    check checkMatcher(prefixMatcher, "abc nextline def", 0, @["abc"], 4)

# todo: prefix with newline in it!

  test "long prefix":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    var prepostTable = getPrepostTable(prepostList)
    var prefixMatcher = getPrefixMatcher(prepostTable)
    let line = "$1  nextline post" % prefix
    check checkMatcher(prefixMatcher, line, 0, @[prefix], 42)
    check prepostTable[prefix] == "post"

  test "command matcher":
    var commandMatcher = getCommandMatcher()

    check checkMatcher(commandMatcher, "<--!$ nextline -->", 6, @["nextline"], 9)
    check checkMatcher(commandMatcher, "<--!$ block    -->", 6, @["block"], 6)
    check checkMatcher(commandMatcher, "<--!$ replace  -->", 6, @["replace"], 8)
    check checkMatcher(commandMatcher, "<--!$ endblock -->", 6, @["endblock"], 9)
    check checkMatcher(commandMatcher, "<--!$ endreplace  -->", 6, @["endreplace"], 11)
    check checkMatcher(commandMatcher, "<--!$ #  -->", 6, @["#"], 2)
    check checkMatcher(commandMatcher, "<--!$ :  -->", 6, @[":"], 2)
    check checkMatcher(commandMatcher, "  nextline ", 2, @["nextline"], 9)

    check not commandMatcher.getMatches(" nextline", 2).isSome
    check not commandMatcher.getMatches(" comment ", 2).isSome

  test "last part matcher":
    var matcher = getLastPartMatcher("-->")

    check checkMatcher(matcher, "<--!$ nextline -->", 15, @["", ""], 3)
    check checkMatcher(matcher, "<--!$ nextline -->\n", 15, @["", "\n"], 4)
    check checkMatcher(matcher, "<--!$ nextline -->\r\n", 15, @["", "\r\n"], 5)
    check checkMatcher(matcher, r"<--!$ nextline \-->", 15, @[r"\", ""], 4)
    check checkMatcher(matcher, "<--!$ nextline \\-->", 15, @[r"\", ""], 4)
    check checkMatcher(matcher, "<--!$ nextline \\-->\n", 15, @[r"\", "\n"], 5)
    check checkMatcher(matcher, "<--!$ nextline \\-->\r\n", 15, @[r"\", "\r\n"], 6)

  test "getLastPart":
    var matcher = getLastPartMatcher("-->")

    checkGetLastPart(matcher, "<--!$ nextline -->", 15, @["", ""], 3)
    checkGetLastPart(matcher, "<--!$ nextline -->\n", 15, @["", "\n"], 4)
    checkGetLastPart(matcher, "<--!$ nextline -->\r\n", 15, @["", "\r\n"], 5)
    checkGetLastPart(matcher, r"<--!$ nextline \-->", 15, @[r"\", ""], 4)
    checkGetLastPart(matcher, "<--!$ nextline \\-->", 15, @[r"\", ""], 4)
    checkGetLastPart(matcher, "<--!$ nextline \\-->\n", 15, @[r"\", "\n"], 5)
    checkGetLastPart(matcher, "<--!$ nextline \\-->\r\n", 15, @[r"\", "\r\n"], 6)

  test "getLastPart blank postfix":
    var matcher = getLastPartMatcher("")
    checkGetLastPart(matcher, "<--!$ nextline a", 16, @["", ""], 0)
    checkGetLastPart(matcher, "<--!$ nextline a\n", 16, @["", "\n"], 1)
    checkGetLastPart(matcher, "<--!$ nextline a\r\n", 16, @["", "\r\n"], 2)
    checkGetLastPart(matcher, r"<--!$ nextline a\", 16, @[r"\", ""], 1)
    checkGetLastPart(matcher, "<--!$ nextline a\\", 16, @[r"\", ""], 1)
    checkGetLastPart(matcher, "<--!$ nextline a\\\n", 16, @[r"\", "\n"], 2)
    checkGetLastPart(matcher, "<--!$ nextline a\\\r\n", 16, @[r"\", "\r\n"], 3)


  test "get space tab":
    let matcher = getSpaceTabMatcher()
    check checkMatcher(matcher, "    ", 0, @[], 4)
    check checkMatcher(matcher, " \t \t   ", 0, @[], 7)
    check not matcher.getMatches("    s   ", 0).isSome

  test "get variable":
    var matcher = getVariableMatcher()
    check checkMatcher(matcher, "a = 5", 0, @["", "a"], 4)
    check checkMatcher(matcher, "t.a = 5", 0, @["t.", "a"], 6)
    check checkMatcher(matcher, "abc = 5", 0, @["", "abc"], 6)
    check checkMatcher(matcher, "   a = 5", 0, @["", "a"], 7)
    check checkMatcher(matcher, "aBcD_t = 5", 0, @["", "aBcD_t"], 9)
    check checkMatcher(matcher, "t.server = 5", 0, @["t.", "server"], 11)
    check checkMatcher(matcher, "t.server =", 0, @["t.", "server"], 10)
    check checkMatcher(matcher, "   a =    5", 0, @["", "a"], 10)

    check checkMatcherNot(matcher, "abc", 0)
    check checkMatcherNot(matcher, ".a =", 0)
    check checkMatcherNot(matcher, "tt.a =", 0)
    check checkMatcherNot(matcher, "_a =", 0)
    check checkMatcherNot(matcher, "*a =", 0)
    check checkMatcherNot(matcher, "34r =", 0)
    check checkMatcherNot(matcher, "  2 =", 0)
    check checkMatcherNot(matcher, "abc() =", 0)

  test "getNumberMatcher":
    var matcher = getNumberMatcher()
    check checkMatcher(matcher, "5", start = 0, expectedStrings = @[""], expectedLength = 1)

    check checkMatcher(matcher, "-5", 0, @[""], 2)
    check checkMatcher(matcher, "-5.", 0, @["."], 3)
    check checkMatcher(matcher, "-5.6", 0, @["."], 4)
    check checkMatcher(matcher, "56789.654321", 0, @["."], 12)
    check checkMatcher(matcher, "4a", 0, @[""], 1)
    check checkMatcher(matcher, "4 ", 0, @[""], 1)
    check checkMatcher(matcher, "4.abc ", 0, @["."], 2)
    check checkMatcher(matcher, "-4.abc ", 0, @["."], 3)
    check checkMatcher(matcher, "4_123_456.0 ", 0, @["."], 11)
    check checkMatcher(matcher, "4_123_456 ", 0, @[""], 9)

  test "getNumberMatcher":
    var matcher = getNumberMatcher()
    check checkMatcher(matcher, "a = 5", 4, @[""], 1)
    check checkMatcher(matcher, "a = -5.2", 4, @["."], 4)
    check checkMatcher(matcher, "a = -5.2abc", 4, @["."], 4)

  test "getNumberMatcherNot":
    var matcher = getNumberMatcher()
    check checkMatcherNot(matcher, "abc")
    check checkMatcherNot(matcher, "")
    check checkMatcherNot(matcher, ".")
    check checkMatcherNot(matcher, "+") # no plus signs
    check checkMatcherNot(matcher, "-")
    check checkMatcherNot(matcher, "_")
    check checkMatcherNot(matcher, "_4")
    check checkMatcherNot(matcher, "-a")
    check checkMatcherNot(matcher, ".1") # need a leading digit
    check checkMatcherNot(matcher, "-.1")

  test "getCompiledMatchers":
    let compiledMatchers = getCompiledMatchers()
    check checkMatcher(compiledMatchers.numberMatcher, "a = 5", 4, @[""], 1)
