
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
    check checkMatcher(matcher, "a = 5", 0, @["", "a"], 2)
    check checkMatcher(matcher, " a = 5 ", 0, @["", "a"], 3)
    check checkMatcher(matcher, "t.a = 5", 0, @["t.", "a"], 4)
    check checkMatcher(matcher, "abc = 5", 0, @["", "abc"], 4)
    check checkMatcher(matcher, "   a = 5", 0, @["", "a"], 5)
    check checkMatcher(matcher, "aBcD_t = 5", 0, @["", "aBcD_t"], 7)
    check checkMatcher(matcher, "t.server = 5", 0, @["t.", "server"], 9)
    check checkMatcher(matcher, "t.server =", 0, @["t.", "server"], 9)
    check checkMatcher(matcher, "   a =    5", 0, @["", "a"], 5)
    let longVar = "a23456789_123456789_123456789_123456789_123456789_123456789_1234"
    check checkMatcher(matcher, longVar, 0, @["", longVar], longVar.len)
    check checkMatcher(matcher, longVar & " = 5", 0, @["", longVar],
                                          longVar.len + 1)

    # These start with a variable but are not valid statements.
    check checkMatcher(matcher, "t. =", 0, @["", "t"], 1)
    check checkMatcher(matcher, "tt.a =", 0, @["", "tt"], 2)
    check checkMatcher(matcher, "abc() =", 0, @["", "abc"], 3)
    check checkMatcher(matcher, "abc", 0, @["", "abc"], 3)
    check checkMatcher(matcher, "t.1a", 0, @["", "t"], 1)
    # It matches up to 64 characters.
    let tooLong = "a23456789_123456789_123456789_123456789_123456789_123456789_12345"
    check checkMatcher(matcher, tooLong, 0, @["", longVar], longVar.len)

    check checkMatcherNot(matcher, ".a =", 0)
    check checkMatcherNot(matcher, "_a =", 0)
    check checkMatcherNot(matcher, "*a =", 0)
    check checkMatcherNot(matcher, "34r =", 0)
    check checkMatcherNot(matcher, "  2 =", 0)
    check checkMatcherNot(matcher, ". =", 0)

  test "get equal sign":
    var matcher = getEqualSignMatcher()
    check checkMatcher(matcher, "=5", 0, @["="], 1)
    check checkMatcher(matcher, "= 5", 0, @["="], 2)

    # Starts with equal sign but not valid statement.
    check checkMatcher(matcher, "==5", 0, @["="], 1)

    check checkMatcherNot(matcher, " =", 0)
    check checkMatcherNot(matcher, "2=", 0)
    check checkMatcherNot(matcher, "a", 0)

  test "getNumberMatcher":
    var matcher = getNumberMatcher()
    check checkMatcher(matcher, "5", start = 0, expectedStrings = @[""], expectedLength = 1)
    check checkMatcher(matcher, "-5", 0, @[""], 2)
    check checkMatcher(matcher, "-5.", 0, @["."], 3)
    check checkMatcher(matcher, "-5.6", 0, @["."], 4)
    check checkMatcher(matcher, "56789.654321", 0, @["."], 12)
    check checkMatcher(matcher, "4 ", 0, @[""], 2)
    check checkMatcher(matcher, "4_123_456.0 ", 0, @["."], 12)
    check checkMatcher(matcher, "4_123_456 ", 0, @[""], 10)

  test "getNumberMatcher with start":
    var matcher = getNumberMatcher()
    check checkMatcher(matcher, "a = 5", 4, @[""], 1)
    check checkMatcher(matcher, "a = 5 ", 4, @[""], 2)
    check checkMatcher(matcher, "a = -5.2", 4, @["."], 4)
    check checkMatcher(matcher, "a = 0.2", 4, @["."], 3)
    check checkMatcher(matcher, "a = 0.2   ", 4, @["."], 6)

    # Starts with a number but not a valid statement.
    check checkMatcher(matcher, "5a", 0, @[""], 1)
    check checkMatcher(matcher, "5.5.", 0, @["."], 3)
    check checkMatcher(matcher, "5.5.6", 0, @["."], 3)

  test "getNumberMatcherNot":
    var matcher = getNumberMatcher()
    check checkMatcherNot(matcher, "a = 5 abc")
    check checkMatcherNot(matcher, "a = -5.2abc")
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
    check checkMatcherNot(matcher, " 4")

  test "getCompiledMatchers":
    let compiledMatchers = getCompiledMatchers()
    check checkMatcher(compiledMatchers.numberMatcher, "a = 5", 4, @[""], 1)

  test "getStringMatcher":
    var matcher = getStringMatcher()
    check checkMatcher(matcher, "'hi'", start = 0, expectedStrings = @["hi", ""], expectedLength = 4)
    check checkMatcher(matcher, "'1234'", 0, @["1234", ""], 6)
    check checkMatcher(matcher, "'abc def' ", 0, @["abc def", ""], 10)
    check checkMatcher(matcher, """"string"""", 0, @["", "string"], 8)
    check checkMatcher(matcher, """"string"  """, 0, @["", "string"], 10)
    check checkMatcher(matcher, """'12"4'""", 0, @["12\"4", ""], 6)
    check checkMatcher(matcher, """"12'4"  """, 0, @["", "12'4"], 8)
    # todo: test utf-8

  test "getStringMatcher with start":
    var matcher = getStringMatcher()
    check checkMatcher(matcher, "a = 'hello'", 4, @["hello", ""], 7)
    check checkMatcher(matcher, "a = '   4 '  ", 4, @["   4 ", ""], 9)
    check checkMatcher(matcher, """a = "hello" """, 4, @["", "hello"], 8)
    check checkMatcher(matcher, """a = 'hel"lo' """, 4, @["hel\"lo", ""], 9)
    check checkMatcher(matcher, """a = "it's true"  """, 4, @["", "it's true"], 13)

  test "getStringMatcherNot":
    var matcher = getStringMatcher()
    check checkMatcherNot(matcher, "a = 'b' abc")
    check checkMatcherNot(matcher, "a = 'abc")
    check checkMatcherNot(matcher, """'a"bc """)
    check checkMatcherNot(matcher, "")
    check checkMatcherNot(matcher, ".")
