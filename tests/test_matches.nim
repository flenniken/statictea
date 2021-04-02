
import unittest
import matches
import tables
import options
import regexes
import env
import strutils

proc testMatchCommand(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  ## Test MatchCommand.
  let matchesO = matchCommand(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchLastPart(line: string, start: Natural, postfix: string,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  ## Test MatchCommand.
  let matchesO = matchLastPart(line, postfix, start)
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

  let prepostTable = makeDefaultPrepostTable()
  let matchesO = matchPrefix(line, prepostTable, start)
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

proc testMatchVariable(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchVariable(line, start)
  if not expectedItem("matchesO: $1" % [line], matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchString(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchString(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchEqualSign(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchEqualSign(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchNumber(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchNumber(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchCommaParentheses(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchCommaParentheses(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchLeftBracket(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchLeftBracket(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

suite "matches.nim":

  test "prepost table":
    var prepostTable = makeDefaultPrepostTable()
    check prepostTable.len == 7
    for prefix, postfix in prepostTable.pairs:
      check prefix.len > 0
      # echo "$1 nextline $2" % [prefix, postfix]
    check prepostTable["<!--$"] == "-->"

  test "matchPrefix":
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

  test "makeUserPrepostTable user prefix":
    var prepostList = @[("abc", "def")]
    var prepostTable = makeUserPrepostTable(prepostList)
    check prepostTable.len == 1
    check prepostTable["abc"] == "def"

  test "long prefix":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    var prepostTable = makeUserPrepostTable(prepostList)
    check prepostTable.len == 1
    check prepostTable[prefix] == "post"

  test "matchCommand":
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

  test "matchLastPart":
    check testMatchLastPart("<!--$ nextline -->", 15, "-->", some(newMatches(3, 15)))
    check testMatchLastPart("<!--$ nextline -->\n", 15, "-->", some(newMatches(4, 15, "", "\n")))
    check testMatchLastPart("<!--$ nextline -->\r\n", 15, "-->", some(newMatches(5, 15, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline \-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->\n", 15, "-->", some(newMatches(5, 15, r"\", "\n")))
    check testMatchLastPart("<!--$ nextline \\-->\r\n", 15, "-->", some(newMatches(6, 15, r"\", "\r\n")))

    check testMatchLastPart("<!--$ nextline -->", 15, "-->", some(newMatches(3, 15)))
    check testMatchLastPart("<!--$ nextline -->\n", 15, "-->", some(newMatches(4, 15, "", "\n")))
    check testMatchLastPart("<!--$ nextline -->\r\n", 15, "-->", some(newMatches(5, 15, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline \-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->", 15, "-->", some(newMatches(4, 15, r"\")))
    check testMatchLastPart("<!--$ nextline \\-->\n", 15, "-->", some(newMatches(5, 15, r"\", "\n")))
    check testMatchLastPart("<!--$ nextline \\-->\r\n", 15, "-->", some(newMatches(6, 15, r"\", "\r\n")))

    check testMatchLastPart("<!--$ nextline a", 16, "", some(newMatches(0, 16)))
    check testMatchLastPart("<!--$ nextline a\n", 16, "", some(newMatches(1, 16, "", "\n")))
    check testMatchLastPart("<!--$ nextline a\r\n", 16, "", some(newMatches(2, 16, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline a\", 16, "", some(newMatches(1, 16, r"\")))
    check testMatchLastPart("<!--$ nextline a\\", 16, "", some(newMatches(1, 16, r"\")))
    check testMatchLastPart("<!--$ nextline a\\\n", 16, "", some(newMatches(2, 16, r"\", "\n")))
    check testMatchLastPart("<!--$ nextline a\\\r\n", 16, "", some(newMatches(3, 16, r"\", "\r\n")))
    check testMatchLastPart(r"#$ nextline \", 12, "", some(newMatches(1, 12, r"\")))

  test "matchAllSpaceTab":
    check testMatchAllSpaceTab("    ", 0, some(newMatches(4, 0)))
    check testMatchAllSpaceTab(" \t \t   ", 0, some(newMatches(7, 0)))
    check testMatchAllSpaceTab("    s   ", 0)

  test "matchTabSpace":
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

  test "matchVariable":
    check testMatchVariable("a = 5", 0, some(newMatches(2, 0, "", "", "a")))
    check testMatchVariable(" a = 5 ", 0, some(newMatches(3, 0, " ", "", "a")))
    check testMatchVariable("t.a = 5", 0, some(newMatches(4, 0, "", "t.", "a")))
    check testMatchVariable("abc = 5", 0, some(newMatches(4, 0, "", "", "abc")))
    check testMatchVariable("   a = 5", 0, some(newMatches(5, 0, "   ", "", "a")))
    check testMatchVariable("aBcD_t = 5", 0, some(newMatches(7, 0, "", "", "aBcD_t")))
    check testMatchVariable("t.server = 5", 0, some(newMatches(9, 0, "", "t.", "server")))
    check testMatchVariable("t.server =", 0, some(newMatches(9, 0, "", "t.", "server")))
    check testMatchVariable("   a =    5", 0, some(newMatches(5, 0, "   ", "", "a")))
    let longVar = "a23456789_123456789_123456789_123456789_123456789_123456789_1234"
    check testMatchVariable(longVar, 0, some(newMatches(64, 0, "", "", longVar)))
    check testMatchVariable(longVar & " = 5", 0, some(newMatches(65, 0, "", "", longVar)))
    check testMatchVariable(" t." & longVar & " = 5", 0, some(newMatches(68, 0, " ", "t.", longVar)))

    # These start with a variable but are not valid statements.
    check testMatchVariable("t. =", 0, some(newMatches(1, 0, "", "", "t")))
    check testMatchVariable("tt.a =", 0, some(newMatches(2, 0, "", "", "tt")))
    check testMatchVariable("abc() =", 0, some(newMatches(3, 0, "", "", "abc")))
    check testMatchVariable("abc", 0, some(newMatches(3, 0, "", "", "abc")))
    check testMatchVariable("t.1a", 0, some(newMatches(1, 0, "", "", "t")))
    # It matches up to 64 characters.
    let tooLong = "a23456789_123456789_123456789_123456789_123456789_123456789_12345"
    check testMatchVariable(tooLong, 0, some(newMatches(64, 0, "", "", longVar)))

    check testMatchVariable(".a =", 0)
    check testMatchVariable("_a =", 0)
    check testMatchVariable("*a =", 0)
    check testMatchVariable("34r =", 0)
    check testMatchVariable("  2 =", 0)
    check testMatchVariable(". =", 0)

  test "matchEqualSign":
    check testMatchEqualSign("=5", 0, some(newMatches(1, 0, "=")))
    check testMatchEqualSign("= 5", 0, some(newMatches(2, 0, "=")))

    # Starts with equal sign but not valid statement.
    check testMatchEqualSign("==5", 0, some(newMatches(1, 0, "=")))

    check testMatchEqualSign(" =", 0)
    check testMatchEqualSign("2=", 0)
    check testMatchEqualSign("a", 0)

  test "matchNumber":
    check testMatchNumber("5", 0, some(newMatches(1, 0)))
    check testMatchNumber("-5", 0, some(newMatches(2, 0)))
    check testMatchNumber("-5.", 0, some(newMatches(3, 0, ".")))
    check testMatchNumber("-5.6", 0, some(newMatches(4, 0, ".")))
    check testMatchNumber("56789.654321", 0, some(newMatches(12, 0, ".")))
    check testMatchNumber("4 ", 0, some(newMatches(2, 0)))
    check testMatchNumber("4_123_456.0 ", 0, some(newMatches(12, 0, ".")))
    check testMatchNumber("4_123_456 ", 0, some(newMatches(10, 0)))

  test "matchNumber with start":
    check testMatchNumber("a = 5", 4, some(newMatches(1, 4)))
    check testMatchNumber("a = 5 ", 4, some(newMatches(2, 4)))
    check testMatchNumber("a = -5.2", 4, some(newMatches(4, 4, ".")))
    check testMatchNumber("a = 0.2", 4, some(newMatches(3, 4, ".")))
    check testMatchNumber("a = 0.2   ", 4, some(newMatches(6, 4, ".")))

    # Starts with a number but not a valid statement.
    check testMatchNumber("5a", 0, some(newMatches(1, 0)))
    check testMatchNumber("5.5.", 0, some(newMatches(3, 0, ".")))
    check testMatchNumber("5.5.6", 0, some(newMatches(3, 0, ".")))

  test "matchNumber not number":
    check testMatchNumber("a = 5 abc")
    check testMatchNumber("a = -5.2abc")
    check testMatchNumber("abc")
    check testMatchNumber("")
    check testMatchNumber(".")
    check testMatchNumber("+") # no plus signs
    check testMatchNumber("-")
    check testMatchNumber("_")
    check testMatchNumber("_4")
    check testMatchNumber("-a")
    check testMatchNumber(".1") # need a leading digit
    check testMatchNumber("-.1")
    check testMatchNumber(" 4")

  test "matchNumber":
    check matchNumber("a = 5", 4) == some(newMatches(1, 4))
    check matchNumber("a = 5.3", 4) == some(newMatches(3, 4, "."))

  test "matchString":
    check testMatchString("'hi'", 0, some(newMatches(4, 0, "hi")))
    check testMatchString("'1234'", 0, some(newMatches(6, 0, "1234")))
    check testMatchString("'abc def' ", 0, some(newMatches(10, 0, "abc def")))
    check testMatchString(""""string"""", 0, some(newMatches(8, 0, "", "string")))
    check testMatchString(""""string"  """, 0, some(newMatches(10, 0, "", "string")))
    check testMatchString("""'12"4'""", 0, some(newMatches(6, 0, "12\"4")))
    check testMatchString(""""12'4"  """, 0, some(newMatches(8, 0, "", "12'4")))

    check testMatchString("a = 'hello'", 4, some(newMatches(7, 4, "hello")))
    check testMatchString("a = '   4 '  ", 4, some(newMatches(9, 4, "   4 ")))
    check testMatchString("""a = "hello" """, 4, some(newMatches(8, 4, "", "hello")))
    check testMatchString("""a = 'hel"lo' """, 4, some(newMatches(9, 4, "hel\"lo")))
    check testMatchString("""a = "it's true"  """, 4, some(newMatches(13, 4, "", "it's true")))

    check testMatchString("tea = 'Earl Grey' tea2 = 'Masala chai'", 6,
                       some(newMatches(12, 6, "Earl Grey")))

    check testMatchString("a = 'b' abc")
    check testMatchString("a = 'abc")
    check testMatchString("""'a"bc """)
    check testMatchString("")
    check testMatchString(".")

  test "matchLeftParentheses":
    check testLeftParentheses("(", 0, some(newMatches(1, 0)))
    check testLeftParentheses("( ", 0, some(newMatches(2, 0)))
    check testLeftParentheses("( 5", 0, some(newMatches(2, 0)))
    check testLeftParentheses("( 'abc'", 0, some(newMatches(2, 0)))

    check testLeftParentheses(", (", 0)
    check testLeftParentheses("2(", 0)
    check testLeftParentheses("abc(", 0)
    check testLeftParentheses(" (", 0)

  test "matchCommaParentheses":
    check testMatchCommaParentheses(",", 0, some(newMatches(1, 0, ",")))
    check testMatchCommaParentheses(")", 0, some(newMatches(1, 0, ")")))
    check testMatchCommaParentheses(", ", 0, some(newMatches(2, 0, ",")))
    check testMatchCommaParentheses(") 5", 0, some(newMatches(2, 0, ")")))

    check testMatchCommaParentheses("( )", 0)
    check testMatchCommaParentheses("2,", 0)
    check testMatchCommaParentheses("abc)", 0)
    check testMatchCommaParentheses(" ,", 0)

  test "matchLeftBracket":
    check testMatchLeftBracket("{", 0, some(newMatches(1, 0)))
    check testMatchLeftBracket("{t}", 0, some(newMatches(1, 0)))
    check testMatchLeftBracket("asdf{tea}fdsa\r\n", 0, some(newMatches(5, 0)))

    check testMatchLeftBracket("", 0)
    check testMatchLeftBracket("a", 0)
    check testMatchLeftBracket("asdf", 0)

  test "matchNumberNotCached":
    var matchO = matchNumberNotCached("123", 0)
    check matchO.isSome
    matchO = matchNumberNotCached("asdf", 0)
    check not matchO.isSome
