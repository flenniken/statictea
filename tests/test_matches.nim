
import unittest
import matches
import tables
import options
import regexes
import env

proc testMatchCommand(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  ## Test MatchCommand.
  let matchesO = matchCommand(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchLastPart(line: string, start: Natural, prefix: string,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  ## Test MatchCommand.
  let matchesO = matchLastPart(line, start, prefix)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchAllSpaceTab(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchAllSpaceTab(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchTabSpace(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchTabSpace(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchPrefix(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =

  let prepostTable = getDefaultPrepostTable()
  let matchesO = matchPrefix(line, start, prepostTable)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testLeftParentheses(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchLeftParentheses(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

suite "matches.nim":

  test "prepost table":
    var prepostTable = getDefaultPrepostTable()
    check prepostTable.len == 7
    for prefix, postfix in prepostTable.pairs:
      check prefix.len > 0
      # echo "$1 nextline $2" % [prefix, postfix]
    check prepostTable["<!--$"] == "-->"

  test "matchPrefix tests":

    check testMatchPrefix("<!--$ nextline -->", 0, some(newMatches(6, 0, "<!--$")))
    check testMatchPrefix("#$ nextline", 0, some(newMatches(3, 0, "#$")))
    check testMatchPrefix(";$ nextline", 0, some(newMatches(3, 0, ";$")))
    check testMatchPrefix("//$ nextline", 0, some(newMatches(4, 0, "//$")))
    check testMatchPrefix("/*$ nextline */", 0, some(newMatches(4, 0, "/*$")))
    check testMatchPrefix("&lt;!--$ nextline --&gt;", 0, some(newMatches(9, 0, "&lt;!--$")))
    check testMatchPrefix("$$ nextline", 0, some(newMatches(3, 0, "$$")))
    check testMatchPrefix("<!--$ : -->", 0, some(newMatches(6, 0, "<!--$")))
    check testMatchPrefix("<!--$         nextline -->", 0, some(newMatches(14, 0, "<!--$")))
    check testMatchPrefix("<!--$\tnextline -->", 0, some(newMatches(6, 0, "<!--$")))
    check testMatchPrefix("#$ nextline\n", 0, some(newMatches(3, 0, "#$")))
    check testMatchPrefix("#$ nextline   \n", 0, some(newMatches(3, 0, "#$")))
    check testMatchPrefix("#$ nextline   \\\n", 0, some(newMatches(3, 0, "#$")))

    check testMatchPrefix("#$", 0, some(newMatches(2, 0, "#$")))
    check testMatchPrefix("#$ ", 0, some(newMatches(3, 0, "#$")))
    check testMatchPrefix("#$    ", 0, some(newMatches(6, 0, "#$")))
    check testMatchPrefix("#$nextline", 0, some(newMatches(2, 0, "#$")))
    check testMatchPrefix("#$ nextline", 0, some(newMatches(3, 0, "#$")))
    check testMatchPrefix("#$  nextline", 0, some(newMatches(4, 0, "#$")))
    check testMatchPrefix("#$\n", 0, some(newMatches(3, 0, "#$")))
    check testMatchPrefix("<!--$", 0, some(newMatches(5, 0, "<!--$")))
    check testMatchPrefix("<!--$ ", 0, some(newMatches(6, 0, "<!--$")))
    check testMatchPrefix("$$ ", 0, some(newMatches(3, 0, "$$")))

    check testMatchPrefix("<--$ nextline -->", 0)

  test "getUserPrepostTable user prefix":
    var prepostList = @[("abc", "def")]
    var prepostTable = getUserPrepostTable(prepostList)
    check prepostTable.len == 1
    check prepostTable["abc"] == "def"

  test "long prefix":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    var prepostTable = getUserPrepostTable(prepostList)
    check prepostTable.len == 1
    check prepostTable[prefix] == "post"

  test "command matcher":
    check testMatchCommand("<!--$ nextline -->", 6, some(newMatches(8, 6, "nextline")))

    check testMatchCommand("<!--$ block    -->", 6, some(newMatches(5, 6, "block")))
    check testMatchCommand("<!--$ replace  -->", 6, some(newMatches(7, 6, "replace")))
    check testMatchCommand("<!--$ endblock -->", 6, some(newMatches(8, 6, "endblock")))
    check testMatchCommand("<!--$ endreplace  -->", 6, some(newMatches(10, 6, "endreplace")))
    check testMatchCommand("<!--$ #  -->", 6, some(newMatches(1, 6, "#")))
    check testMatchCommand("<!--$ :  -->", 6, some(newMatches(1, 6, ":")))
    check testMatchCommand("  nextline ", 2, some(newMatches(8, 2, "nextline")))

    check testMatchCommand("<!--$nextline-->", 5, some(newMatches(8, 5, "nextline")))
    check testMatchCommand("<!--$nextline-->\n", 5, some(newMatches(8, 5, "nextline")))
    check testMatchCommand("#$nextline", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline ", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline  ", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand(r"#$nextline\", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\\", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\\\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\r\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\\\r\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline \\\r\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$#", 2, some(newMatches(1, 2, "#")))
    check testMatchCommand("#$#a", 2, some(newMatches(1, 2, "#")))

    check testMatchCommand(" nextlin", 2)
    check testMatchCommand(" coment ", 2)

  test "last part matcher":
    check testMatchLastPart("<!--$ nextline -->", 15, "-->", some(newMatches(3, 15)))
    check testMatchLastPart("<!--$ nextline -->\n", 15, "-->", some(newMatches(4, 15, "", "\n")))
    check testMatchLastPart("<!--$ nextline -->\r\n", 15, "-->", some(newMatches(5, 15, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline \-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->\n", 15, "-->", some(newMatches(5, 15, r"\", "\n")))
    check testMatchLastPart("<!--$ nextline \\-->\r\n", 15, "-->", some(newMatches(6, 15, r"\", "\r\n")))

  test "getLastPart":
    check testMatchLastPart("<!--$ nextline -->", 15, "-->", some(newMatches(3, 15)))
    check testMatchLastPart("<!--$ nextline -->\n", 15, "-->", some(newMatches(4, 15, "", "\n")))
    check testMatchLastPart("<!--$ nextline -->\r\n", 15, "-->", some(newMatches(5, 15, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline \-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->\n", 15, "-->", some(newMatches(5, 15, r"\", "\n")))
    check testMatchLastPart("<!--$ nextline \\-->\r\n", 15, "-->", some(newMatches(6, 15, r"\", "\r\n")))

  test "getLastPart blank postfix":
    check testMatchLastPart("<!--$ nextline a", 16, "", some(newMatches(0, 16)))
    check testMatchLastPart("<!--$ nextline a\n", 16, "", some(newMatches(1, 16, "", "\n")))
    check testMatchLastPart("<!--$ nextline a\r\n", 16, "", some(newMatches(2, 16, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline a\", 16, "", some(newMatches(1, 16, r"\")))
    check testMatchLastPart("<!--$ nextline a\\", 16, "", some(newMatches(1, 16, r"\")))
    check testMatchLastPart("<!--$ nextline a\\\n", 16, "", some(newMatches(2, 16, r"\", "\n")))
    check testMatchLastPart("<!--$ nextline a\\\r\n", 16, "", some(newMatches(3, 16, r"\", "\r\n")))
    check testMatchLastPart(r"#$ nextline \", 12, "", some(newMatches(1, 12, r"\")))

  test "get space tab":
    check testMatchAllSpaceTab("    ", 0, some(newMatches(4, 0)))
    check testMatchAllSpaceTab(" \t \t   ", 0, some(newMatches(7, 0)))
    check testMatchAllSpaceTab("    s   ", 0)

  test "get tab space":
    check testMatchTabSpace(" ", 0, some(newMatches(1, 0)))
    check testMatchTabSpace("\t", 0, some(newMatches(1, 0)))
    check testMatchTabSpace(" \t", 0, some(newMatches(2, 0)))
    check testMatchTabSpace("\t ", 0, some(newMatches(2, 0)))
    check testMatchTabSpace(" a", 0, some(newMatches(1, 0)))
    check testMatchTabSpace("  a", 0, some(newMatches(2, 0)))
    check testMatchTabSpace("  \n", 0, some(newMatches(2, 0)))
    check testMatchTabSpace("  \r", 0, some(newMatches(2, 0)))
    check testMatchTabSpace("a ", 1, some(newMatches(1, 1)))
    check testMatchTabSpace("ab   ", 2, some(newMatches(3, 2)))

    check testMatchTabSpace("a", 0)
    check testMatchTabSpace("\n", 0)
    check testMatchTabSpace("\r", 0)
    check testMatchTabSpace(" a ", 1)

  test "get variable":
    var matcher = getVariableMatcher()
    check checkMatcher(matcher, "a = 5", 0, @["", "", "a"], 2)
    check checkMatcher(matcher, " a = 5 ", 0, @[" ", "", "a"], 3)
    check checkMatcher(matcher, "t.a = 5", 0, @["", "t.", "a"], 4)
    check checkMatcher(matcher, "abc = 5", 0, @["", "", "abc"], 4)
    check checkMatcher(matcher, "   a = 5", 0, @["   ", "", "a"], 5)
    check checkMatcher(matcher, "aBcD_t = 5", 0, @["", "", "aBcD_t"], 7)
    check checkMatcher(matcher, "t.server = 5", 0, @["", "t.", "server"], 9)
    check checkMatcher(matcher, "t.server =", 0, @["", "t.", "server"], 9)
    check checkMatcher(matcher, "   a =    5", 0, @["   ", "", "a"], 5)
    let longVar = "a23456789_123456789_123456789_123456789_123456789_123456789_1234"
    check checkMatcher(matcher, longVar, 0, @["", "", longVar], longVar.len)
    check checkMatcher(matcher, longVar & " = 5", 0, @["", "", longVar],
                                          longVar.len + 1)

    # These start with a variable but are not valid statements.
    check checkMatcher(matcher, "t. =", 0, @["", "", "t"], 1)
    check checkMatcher(matcher, "tt.a =", 0, @["", "", "tt"], 2)
    check checkMatcher(matcher, "abc() =", 0, @["", "", "abc"], 3)
    check checkMatcher(matcher, "abc", 0, @["", "", "abc"], 3)
    check checkMatcher(matcher, "t.1a", 0, @["", "", "t"], 1)
    # It matches up to 64 characters.
    let tooLong = "a23456789_123456789_123456789_123456789_123456789_123456789_12345"
    check checkMatcher(matcher, tooLong, 0, @["", "", longVar], longVar.len)

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

  test "matchNumber":
    check matchNumber("a = 5", 4) == some(newMatches(1, 4))
    check matchNumber("a = 5.3", 4) == some(newMatches(3, 4, "."))

  test "getStringMatcher":
    var matcher = getStringMatcher()
    check checkMatcher(matcher, "'hi'", start = 0, expectedStrings = @["hi", ""], expectedLength = 4)
    check checkMatcher(matcher, "'1234'", 0, @["1234", ""], 6)
    check checkMatcher(matcher, "'abc def' ", 0, @["abc def", ""], 10)
    check checkMatcher(matcher, """"string"""", 0, @["", "string"], 8)
    check checkMatcher(matcher, """"string"  """, 0, @["", "string"], 10)
    check checkMatcher(matcher, """'12"4'""", 0, @["12\"4", ""], 6)
    check checkMatcher(matcher, """"12'4"  """, 0, @["", "12'4"], 8)

  test "getStringMatcher with start":
    var matcher = getStringMatcher()
    check checkMatcher(matcher, "a = 'hello'", 4, @["hello", ""], 7)
    check checkMatcher(matcher, "a = '   4 '  ", 4, @["   4 ", ""], 9)
    check checkMatcher(matcher, """a = "hello" """, 4, @["", "hello"], 8)
    check checkMatcher(matcher, """a = 'hel"lo' """, 4, @["hel\"lo", ""], 9)
    check checkMatcher(matcher, """a = "it's true"  """, 4, @["", "it's true"], 13)

  test "getStringMatcher extra text after":
    var matcher = getStringMatcher()
    check checkMatcher(matcher, "tea = 'Earl Grey' tea2 = 'Masala chai'", 6,
                       @["Earl Grey", ""], 12)

  test "getStringMatcherNot":
    var matcher = getStringMatcher()
    check checkMatcherNot(matcher, "a = 'b' abc")
    check checkMatcherNot(matcher, "a = 'abc")
    check checkMatcherNot(matcher, """'a"bc """)
    check checkMatcherNot(matcher, "")
    check checkMatcherNot(matcher, ".")

  test "getLeftParenthesesMatcher":
    check testLeftParentheses("(", 0, some(newMatches(1, 0)))
    check testLeftParentheses("( ", 0, some(newMatches(2, 0)))
    check testLeftParentheses("( 5", 0, some(newMatches(2, 0)))
    check testLeftParentheses("( 'abc'", 0, some(newMatches(2, 0)))

    check testLeftParentheses(", (", 0)
    check testLeftParentheses("2(", 0)
    check testLeftParentheses("abc(", 0)
    check testLeftParentheses(" (", 0)

  test "getCommaParenthesesMatcher":
    var matcher = getCommaParenthesesMatcher()
    check checkMatcher(matcher, ",", 0, @[","], 1)
    check checkMatcher(matcher, ")", 0, @[")"], 1)
    check checkMatcher(matcher, ", ", 0, @[","], 2)
    check checkMatcher(matcher, ") 5", 0, @[")"], 2)

    check checkMatcherNot(matcher, "( )", 0)
    check checkMatcherNot(matcher, "2,", 0)
    check checkMatcherNot(matcher, "abc)", 0)
    check checkMatcherNot(matcher, " ,", 0)

  test "getLeftBracketMatcher":
    var matcher = getLeftBracketMatcher()
    check checkMatcher(matcher, "{", 0, @[], 1)
    check checkMatcher(matcher, "{t}", 0, @[], 1)
    check checkMatcher(matcher, "asdf{tea}fdsa\r\n", 0, @[], 5)

    check checkMatcherNot(matcher, "", 0)
    check checkMatcherNot(matcher, "a", 0)
    check checkMatcherNot(matcher, "asdf", 0)
