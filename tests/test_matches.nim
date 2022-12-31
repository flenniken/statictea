
import std/unittest
import std/strutils
import std/tables
import std/options
import matches
import regexes
import args
import sharedtestcode

proc newStrFromBuffer(buffer: openArray[uint8]): string =
  result = newStringOfCap(buffer.len)
  for ix in 0 ..< buffer.len:
    result.add((char)buffer[ix])

proc testParsePrepostGood(str: string, ePrefix: string, ePostfix: string = ""): bool =
  let prepostO = parsePrepost(str)
  if not isSome(prepostO):
    echo "'$1' is not a valid prepost." % str
    return false
  result = true
  let (prefix, postfix) = prepostO.get()
  if not expectedItem("prefix", prefix, ePrefix):
    result = false
  if not expectedItem("postfix", postfix, ePostfix):
    result = false

proc testParsePrepostBad(str: string): bool =
  let prepostO = parsePrepost(str)
  if isSome(prepostO):
    echo "'$1' is a valid prepost." % str
    return false
  result = true

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
  var prefixes = newSeq[string]()
  for key in prepostTable.keys():
    prefixes.add(key)
  let matchesO = matchPrefix(line, prefixes, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchDotNames(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchDotNames(line, start)
  if not expectedItem("matchesO: $1" % [line], matchesO, eMatchesO):
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

proc testMatchCommaOrSymbol(line: string, symbol: GroupSymbol, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchCommaOrSymbol(line, symbol, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchSymbol(line: string, symbol: GroupSymbol, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchSymbol(line, symbol, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testGetLastPart(line: string, postfix: string,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = getLastPart(line, postfix)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchUpToLeftBracket(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchUpToLeftBracket(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchNotOrParen(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchNotOrParen(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchBoolExprOperator(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchBoolExprOperator(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchCompareOperator(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchCompareOperator(line, start)
  if not expectedItem("matchesO", matchesO, eMatchesO):
    result = false
  else:
    result = true

proc testMatchReplCmd(line: string, start: Natural = 0,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchReplCmd(line, start)
  result = gotExpected($matchesO, $eMatchesO, line & ".")

proc testEmptyOrSpaces(line: string, start: Natural = 0, expected: bool): bool =
  let got = emptyOrSpaces(line, start)
  result = gotExpected($got, $expected, line & ".")

proc testMatchParameterType(paramTypeStr: string, eParamTypeStr: string = "",
    eLength: Natural = 0, eOptional: bool = false): bool =
  let matchO = matchParameterType(paramTypeStr, 0)
  if not isSome(matchO):
    echo "'$1' is not a valid parameter type." % paramTypeStr
    return false

  var expected = eParamTypeStr
  if eParamTypeStr == "":
    expected = paramTypeStr

  var expectedLen = eLength
  if eLength == 0:
    expectedLen = paramTypeStr.len

  let (optionalText, gotParamTypeStr, length) = matchO.get2GroupsLen()
  # debugEcho "optionalText = '$1'" % optionalText
  result = gotExpected(gotParamTypeStr, expected, "parameter type:")

  var optional: bool
  if optionalText.len > 0:
    optional = true
  gotExpectedResult($optional, $eOptional, "optional:")

  gotExpectedResult($length, $expectedLen, "length:")

proc testMatchParameterTypeBad(paramTypeStr: string): bool =
  let matchO = matchParameterType(paramTypeStr, 0)
  if isSome(matchO):
    echo "'$1' is a valid parameter type." % paramTypeStr
    return false
  result = true

proc testMatchDocComment(line: string, start: Natural,
    eMatchesO: Option[Matches] = none(Matches)): bool =
  let matchesO = matchDocComment(line, start)
  result = gotExpected($matchesO, $eMatchesO, line)

suite "matches.nim":

  test "prepost table":
    var prepostTable = makeDefaultPrepostTable()
    check prepostTable.len == 8
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
    check testMatchPrefix("#$ nextline   +\n", 0, some(newMatches(3, 0, "#$")))

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
    var prepostList = @[newPrepost("abc", "def")]
    var prepostTable = makeUserPrepostTable(prepostList)
    check prepostTable.len == 1
    check prepostTable["abc"] == "def"

  test "long prefix":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[newPrepost(prefix, "post")]
    var prepostTable = makeUserPrepostTable(prepostList)
    check prepostTable.len == 1
    check prepostTable[prefix] == "post"

  test "matchCommand":
    check testMatchCommand("<!--$ nextline -->", 6, some(newMatches(8, 6, "nextline")))
    check testMatchCommand("$$ nextline", 3, some(newMatches(8, 3, "nextline")))

    check testMatchCommand("<!--$ block    -->", 6, some(newMatches(5, 6, "block")))
    check testMatchCommand("<!--$ replace  -->", 6, some(newMatches(7, 6, "replace")))
    check testMatchCommand("<!--$ endblock -->", 6, some(newMatches(8, 6, "endblock")))
    check testMatchCommand("<!--$ #  -->", 6, some(newMatches(1, 6, "#")))
    check testMatchCommand("<!--$ :  -->", 6, some(newMatches(1, 6, ":")))
    check testMatchCommand("  nextline ", 2, some(newMatches(8, 2, "nextline")))

    check testMatchCommand("<!--$nextline-->", 5, some(newMatches(8, 5, "nextline")))
    check testMatchCommand("<!--$nextline-->\n", 5, some(newMatches(8, 5, "nextline")))
    check testMatchCommand("#$nextline", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline ", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline  ", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand(r"#$nextline+", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline+", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline+\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline\r\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline+\r\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$nextline +\r\n", 2, some(newMatches(8, 2, "nextline")))
    check testMatchCommand("#$#", 2, some(newMatches(1, 2, "#")))
    check testMatchCommand("#$#a", 2, some(newMatches(1, 2, "#")))

    check testMatchCommand(" nextlin", 2)
    check testMatchCommand(" coment ", 2)

  test "matchLastPart":
    check testMatchLastPart("<!--$ nextline -->", 15, "-->",
      some(newMatches(3, 15, "", "")))
    check testMatchLastPart("<!--$ nextline -->\n", 15, "-->",
      some(newMatches(4, 15, "", "\n")))
    check testMatchLastPart("<!--$ nextline -->\r\n", 15, "-->",
      some(newMatches(5, 15, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline +-->", 15, "-->",
      some(newMatches(4, 15, r"+", "")))
    check testMatchLastPart("<!--$ nextline +-->", 15, "-->",
      some(newMatches(4, 15, r"+", "")))
    check testMatchLastPart("<!--$ nextline +-->\n", 15, "-->",
      some(newMatches(5, 15, r"+", "\n")))
    check testMatchLastPart("<!--$ nextline +-->\r\n", 15, "-->",
      some(newMatches(6, 15, r"+", "\r\n")))

    check testMatchLastPart("<!--$ nextline -->", 15, "-->",
      some(newMatches(3, 15, "", "")))
    check testMatchLastPart("<!--$ nextline -->\n", 15, "-->",
      some(newMatches(4, 15, "", "\n")))
    check testMatchLastPart("<!--$ nextline -->\r\n", 15, "-->",
      some(newMatches(5, 15, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline +-->", 15, "-->",
      some(newMatches(4, 15, r"+", "")))
    check testMatchLastPart("<!--$ nextline +-->", 15, "-->",
      some(newMatches(4, 15, r"+", "")))
    check testMatchLastPart("<!--$ nextline +-->\n", 15, "-->",
      some(newMatches(5, 15, r"+", "\n")))
    check testMatchLastPart("<!--$ nextline +-->\r\n", 15, "-->",
      some(newMatches(6, 15, r"+", "\r\n")))

    check testMatchLastPart("<!--$ nextline a", 16, "",
      some(newMatches(0, 16, "", "")))
    check testMatchLastPart("<!--$ nextline a\n", 16, "",
      some(newMatches(1, 16, "", "\n")))
    check testMatchLastPart("<!--$ nextline a\r\n", 16, "",
      some(newMatches(2, 16, "", "\r\n")))
    check testMatchLastPart(r"<!--$ nextline a+", 16, "",
      some(newMatches(1, 16, r"+", "")))
    check testMatchLastPart("<!--$ nextline a+", 16, "",
      some(newMatches(1, 16, r"+", "")))
    check testMatchLastPart("<!--$ nextline a+\n", 16, "",
      some(newMatches(2, 16, r"+", "\n")))
    check testMatchLastPart("<!--$ nextline a+\r\n", 16, "",
      some(newMatches(3, 16, r"+", "\r\n")))
    check testMatchLastPart(r"#$ nextline +", 12, "",
      some(newMatches(1, 12, r"+", "")))

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
    check testMatchDotNames("a = 5", 0, some(newMatches(2, 0, "", "a", "")))
    check testMatchDotNames("a(4)", 0, some(newMatches(2, 0, "", "a", "(")))
    check testMatchDotNames("a[4]", 0, some(newMatches(2, 0, "", "a", "[")))
    check testMatchDotNames("a (4)", 0, some(newMatches(2, 0, "", "a", "")))
    check testMatchDotNames("a(  4)", 0, some(newMatches(4, 0, "", "a", "(")))
    check testMatchDotNames(" a = 5 ", 0, some(newMatches(3, 0, " ", "a", "")))
    check testMatchDotNames("t.a = 5", 0, some(newMatches(4, 0, "", "t.a", "")))
    check testMatchDotNames("abc = 5", 0, some(newMatches(4, 0, "", "abc", "")))
    check testMatchDotNames("   a = 5", 0, some(newMatches(5, 0, "   ", "a", "")))
    check testMatchDotNames("aBcD_t = 5", 0, some(newMatches(7, 0, "", "aBcD_t", "")))
    check testMatchDotNames("t.server = 5", 0, some(newMatches(9, 0, "", "t.server", "")))
    check testMatchDotNames("t.server =", 0, some(newMatches(9, 0, "", "t.server", "")))
    check testMatchDotNames("   a =    5", 0, some(newMatches(5, 0, "   ", "a", "")))
    let longVar = "a23456789_123456789_123456789_123456789_123456789_123456789_1234"
    check testMatchDotNames(longVar, 0, some(newMatches(64, 0, "", longVar, "")))
    check testMatchDotNames(longVar & " = 5", 0, some(newMatches(65, 0, "", longVar, "")))
    check testMatchDotNames(" t." & longVar & " = 5", 0, some(newMatches(68, 0, " ", "t." & longVar, "")))

    # These start with a variable but are not valid statements.
    check testMatchDotNames("t. =", 0, some(newMatches(1, 0, "", "t", "")))
    check testMatchDotNames("tt.a =", 0, some(newMatches(5, 0, "", "tt.a", "")))
    check testMatchDotNames("abc() =", 0, some(newMatches(4, 0, "", "abc", "(")))
    check testMatchDotNames("abc", 0, some(newMatches(3, 0, "", "abc", "")))
    check testMatchDotNames("t.1a", 0, some(newMatches(1, 0, "", "t", "")))
    # It matches up to 64 characters.
    let tooLong = "a23456789_123456789_123456789_123456789_123456789_123456789_12345"
    check testMatchDotNames(tooLong, 0, some(newMatches(64, 0, "", longVar, "")))

    check testMatchDotNames(".a =", 0)
    check testMatchDotNames("_a =", 0)
    check testMatchDotNames("*a =", 0)
    check testMatchDotNames("34r =", 0)
    check testMatchDotNames("  2 =", 0)
    check testMatchDotNames(". =", 0)

  test "matchEqualSign":
    check testMatchEqualSign("=5", 0, some(newMatches(1, 0, "=")))
    check testMatchEqualSign("= 5", 0, some(newMatches(2, 0, "=")))
    check testMatchEqualSign("&=5", 0, some(newMatches(2, 0, "&=")))
    check testMatchEqualSign("&= 5", 0, some(newMatches(3, 0, "&=")))

    check testMatchEqualSign("==5", 0, some(newMatches(1, 0, "=")))
    check testMatchEqualSign("&=&5", 0, some(newMatches(2, 0, "&=")))

    check testMatchEqualSign(" =", 0)
    check testMatchEqualSign("2=", 0)
    check testMatchEqualSign("a", 0)
    check testMatchEqualSign("&", 0)

  test "matchNumber":
    check testMatchNumber("5", 0, some(newMatches(1, 0, "")))
    check testMatchNumber("-5", 0, some(newMatches(2, 0, "")))
    check testMatchNumber("-5.", 0, some(newMatches(3, 0, ".")))
    check testMatchNumber("-5.6", 0, some(newMatches(4, 0, ".")))
    check testMatchNumber("56789.654321", 0, some(newMatches(12, 0, ".")))
    check testMatchNumber("4 ", 0, some(newMatches(2, 0, "")))
    check testMatchNumber("4_123_456.0 ", 0, some(newMatches(12, 0, ".")))
    check testMatchNumber("4_123_456 ", 0, some(newMatches(10, 0, "")))

  test "matchNumber with start":
    check testMatchNumber("a = 5", 4, some(newMatches(1, 4, "")))
    check testMatchNumber("a = 5 ", 4, some(newMatches(2, 4, "")))
    check testMatchNumber("a = -5.2", 4, some(newMatches(4, 4, ".")))
    check testMatchNumber("a = 0.2", 4, some(newMatches(3, 4, ".")))
    check testMatchNumber("a = 0.2   ", 4, some(newMatches(6, 4, ".")))

    # Starts with a number but not a valid statement.
    check testMatchNumber("5a", 0, some(newMatches(1, 0, "")))
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
    check matchNumber("a = 5", 4) == some(newMatches(1, 4, ""))
    check matchNumber("a = 5.3", 4) == some(newMatches(3, 4, "."))


  test "matchCommaParentheses":
    check testMatchCommaParentheses(",", 0, some(newMatches(1, 0, ",")))
    check testMatchCommaParentheses(")", 0, some(newMatches(1, 0, ")")))
    check testMatchCommaParentheses(", ", 0, some(newMatches(2, 0, ",")))
    check testMatchCommaParentheses(") 5", 0, some(newMatches(2, 0, ")")))

    check testMatchCommaParentheses("( )", 0)
    check testMatchCommaParentheses("2,", 0)
    check testMatchCommaParentheses("abc)", 0)
    check testMatchCommaParentheses(" ,", 0)

  test "matchCommaOrSymbol":
    check testMatchCommaOrSymbol(",", gRightParentheses, 0, some(newMatches(1, 0, ",")))
    check testMatchCommaOrSymbol(")", gRightParentheses, 0, some(newMatches(1, 0, ")")))
    check testMatchCommaOrSymbol(", ", gRightParentheses, 0, some(newMatches(2, 0, ",")))
    check testMatchCommaOrSymbol(") 5", gRightParentheses, 0, some(newMatches(2, 0, ")")))

    check testMatchCommaOrSymbol("(  ", gLeftParentheses, 0, some(newMatches(3, 0, "(")))
    check testMatchCommaOrSymbol("[  ", gLeftBracket, 0, some(newMatches(3, 0, "[")))
    check testMatchCommaOrSymbol("]  ", gRightBracket, 0, some(newMatches(3, 0, "]")))

    check testMatchCommaOrSymbol("]  x", gRightBracket, 0, some(newMatches(3, 0, "]")))

    check testMatchCommaOrSymbol("( )", gRightParentheses, 0)
    check testMatchCommaOrSymbol("2,", gRightParentheses, 0)
    check testMatchCommaOrSymbol("abc)", gRightParentheses, 0)
    check testMatchCommaOrSymbol(" ,", gRightParentheses, 0)
    check testMatchCommaOrSymbol("""a = func("test() int"""", gRightParentheses, 30)

  test "matchUpToLeftBracket":
    check testMatchUpToLeftBracket("{", 0, some(newMatches(1, 0)))
    check testMatchUpToLeftBracket("{t}", 0, some(newMatches(1, 0)))
    check testMatchUpToLeftBracket("asdf{tea}fdsa\r\n", 0, some(newMatches(5, 0)))

    check testMatchUpToLeftBracket("", 0)
    check testMatchUpToLeftBracket("a", 0)
    check testMatchUpToLeftBracket("asdf", 0)

  test "matchNumberNotCached":
    var matchO = matchNumberNotCached("123", 0)
    check matchO.isSome
    matchO = matchNumberNotCached("asdf", 0)
    check not matchO.isSome

  test "matchDotNames":
    check testMatchDotNames("t.maxLines = 5", 0, some(newMatches(11, 0, "", "t.maxLines", "")))

    check testMatchDotNames("a", 0, some(newMatches(1, 0, "", "a", "")))
    check testMatchDotNames("a.b", 0, some(newMatches(3, 0, "", "a.b", "")))
    check testMatchDotNames("a.b.c", 0, some(newMatches(5, 0, "", "a.b.c", "")))
    check testMatchDotNames("a.b.c.d", 0, some(newMatches(7, 0, "", "a.b.c.d", "")))
    check testMatchDotNames("a.b.c.d.e", 0, some(newMatches(9, 0, "", "a.b.c.d.e", "")))
    check testMatchDotNames("a.b.c.d.e.f", 0, some(newMatches(9, 0, "", "a.b.c.d.e", "")))

    check testMatchDotNames("a.b.", 0, some(newMatches(3, 0, "", "a.b", "")))
    check testMatchDotNames("a..b", 0, some(newMatches(1, 0, "", "a", "")))
    check testMatchDotNames("a#", 0, some(newMatches(1, 0, "", "a", "")))
    check testMatchDotNames("a#  ", 0, some(newMatches(1, 0, "", "a", "")))
    check testMatchDotNames("a$", 0, some(newMatches(1, 0, "", "a", "")))

    check testMatchDotNames("  a", 0, some(newMatches(3, 0, "  ", "a", "")))
    check testMatchDotNames("  a.bb", 0, some(newMatches(6, 0, "  ", "a.bb", "")))

    check testMatchDotNames("  a ", 0, some(newMatches(4, 0, "  ", "a", "")))
    check testMatchDotNames("  a  ", 0, some(newMatches(5, 0, "  ", "a", "")))
    check testMatchDotNames("  a.", 0, some(newMatches(3, 0, "  ", "a", "")))
    check testMatchDotNames("  a=", 0, some(newMatches(3, 0, "  ", "a", "")))
    check testMatchDotNames(" var = 5", 0, some(newMatches(5, 0, " ", "var", "")))

    check testMatchDotNames(" s.aZ_4 = b", 0, some(newMatches(8, 0, " ", "s.aZ_4", "")))
    check testMatchDotNames(" s.Ab_4 = b", 0, some(newMatches(8, 0, " ", "s.Ab_4", "")))
    check testMatchDotNames("a0123456789 = b", 0, some(newMatches(12, 0, "", "a0123456789", "")))

    let longName = "a23456789_123456789_123456789_123456789_123456789_123456789_1234"
    let statement = "$1= 333" % [longName]
    check testMatchDotNames(statement, 0, some(newMatches(64, 0, "", longName, "")))

    let statement2 = "$1e = 333" % [longName]
    check testMatchDotNames(statement2, 0, some(newMatches(64, 0, "", longName, "")))

    let twoVars = "$1.$1" % [longName]
    check testMatchDotNames(twoVars, 0, some(newMatches(129, 0, "", twoVars, "")))

  test "matchDotNames no match":
    check testMatchDotNames("", 0)
    check testMatchDotNames(" ", 0)
    check testMatchDotNames("  ", 0)
    check testMatchDotNames("4", 0)
    check testMatchDotNames("_", 0)
    check testMatchDotNames("_a", 0)
    check testMatchDotNames(".", 0)
    check testMatchDotNames(".a", 0)
    check testMatchDotNames(".a.b", 0)

  test "matchSymbol":
    check testMatchSymbol(")", gRightParentheses, 0, some(newMatches(1, 0)))
    check testMatchSymbol("(", gLeftParentheses, 0, some(newMatches(1, 0)))
    check testMatchSymbol("[", gLeftBracket, 0, some(newMatches(1, 0)))
    check testMatchSymbol("]", gRightBracket, 0, some(newMatches(1, 0)))
    check testMatchSymbol(":", gColon, 0, some(newMatches(1, 0)))

    check testMatchSymbol("  )", gRightParentheses, 2, some(newMatches(1, 2)))
    check testMatchSymbol("  (", gLeftParentheses, 2, some(newMatches(1, 2)))
    check testMatchSymbol("  [", gLeftBracket, 2, some(newMatches(1, 2)))
    check testMatchSymbol("  ]", gRightBracket, 2, some(newMatches(1, 2)))

    check testMatchSymbol("  )   ", gRightParentheses, 2, some(newMatches(4, 2)))
    check testMatchSymbol("  (   ", gLeftParentheses, 2, some(newMatches(4, 2)))
    check testMatchSymbol("  [   ", gLeftBracket, 2, some(newMatches(4, 2)))
    check testMatchSymbol("  ]   ", gRightBracket, 2, some(newMatches(4, 2)))
    check testMatchSymbol("  :   ", gColon, 2, some(newMatches(4, 2)))

  test "matchLastPart2":
    check testMatchLastPart("+", 0, "", some(newMatches(1, 0, "+", "")))
    check testMatchLastPart("+\n", 0, "", some(newMatches(2, 0, "+", "\n")))
    check testMatchLastPart("+\r\n", 0, "", some(newMatches(3, 0, "+", "\r\n")))

    check testMatchLastPart("+-->", 0, "-->", some(newMatches(4, 0, "+", "")))
    check testMatchLastPart("+-->\n", 0, "-->", some(newMatches(5, 0, "+", "\n")))
    check testMatchLastPart("+-->\r\n", 0, "-->", some(newMatches(6, 0, "+", "\r\n")))

  test "getLastPart":
    check testGetLastPart("0123 -->", "-->", some(newMatches(3, 5, "", "")))
    check testGetLastPart("0123 +-->", "-->", some(newMatches(4, 5, "+", "")))
    check testGetLastPart("0123 +-->\n", "-->", some(newMatches(5, 5, "+", "\n")))
    check testGetLastPart("0123 +-->\r\n", "-->", some(newMatches(6, 5, "+", "\r\n")))
    check testGetLastPart("0123 -->\n", "-->", some(newMatches(4, 5, "", "\n")))
    check testGetLastPart("0123 -->\r\n", "-->", some(newMatches(5, 5, "", "\r\n")))
    check testGetLastPart(" -->", "-->", some(newMatches(3, 1, "", "")))

    check testGetLastPart("-->", "-->", some(newMatches(3, 0, "", "")))
    check testGetLastPart("+-->", "-->", some(newMatches(4, 0, "+", "")))
    check testGetLastPart("+-->\n", "-->", some(newMatches(5, 0, "+", "\n")))
    check testGetLastPart("+-->\r\n", "-->", some(newMatches(6, 0, "+", "\r\n")))

    check testGetLastPart("+", "", some(newMatches(1, 0, "+", "")))
    check testGetLastPart("+\n", "", some(newMatches(2, 0, "+", "\n")))
    check testGetLastPart("+\r\n", "", some(newMatches(3, 0, "+", "\r\n")))

    check testGetLastPart("", "", some(newMatches(0, 0, "", "")))

  test "getLastPart 2":
    check testGetLastPart("", "-->")
    check testGetLastPart("-", "-->")
    check testGetLastPart("->", "-->")

  test "matchNotOrParen":
    check testMatchNotOrParen("")
    check testMatchNotOrParen("nothing here")
    check testMatchNotOrParen("not ", 0, some(newMatches(4, 0, "not ")))
    check testMatchNotOrParen("not  abc", 0, some(newMatches(5, 0, "not ")))
    check testMatchNotOrParen("not ", 1)
    check testMatchNotOrParen("(a < b) ", 0, some(newMatches(1, 0, "(")))
    check testMatchNotOrParen("(  a < b  ) ", 0, some(newMatches(3, 0, "(")))

  test "testMatchCondOperator":
    check testMatchBoolExprOperator("")
    check testMatchBoolExprOperator("no match")
    check testMatchBoolExprOperator("and")
    check testMatchBoolExprOperator("or")
    check testMatchBoolExprOperator(" and")
    check testMatchBoolExprOperator(" and ")

    check testMatchBoolExprOperator("and ", 0, some(newMatches(4, 0, "and")))
    check testMatchBoolExprOperator("or ", 0, some(newMatches(3, 0, "or")))
    check testMatchBoolExprOperator("==", 0, some(newMatches(2, 0, "==")))
    check testMatchBoolExprOperator("!=", 0, some(newMatches(2, 0, "!=")))
    check testMatchBoolExprOperator("<", 0, some(newMatches(1, 0, "<")))
    check testMatchBoolExprOperator(">", 0, some(newMatches(1, 0, ">")))
    check testMatchBoolExprOperator("<=", 0, some(newMatches(2, 0, "<=")))
    check testMatchBoolExprOperator(">=", 0, some(newMatches(2, 0, ">=")))

    check testMatchBoolExprOperator(" and ", 1, some(newMatches(4, 1, "and")))
    check testMatchBoolExprOperator(" or ", 1, some(newMatches(3, 1, "or")))
    check testMatchBoolExprOperator(" ==", 1, some(newMatches(2, 1, "==")))
    check testMatchBoolExprOperator(" !=", 1, some(newMatches(2, 1, "!=")))
    check testMatchBoolExprOperator(" <", 1, some(newMatches(1, 1, "<")))
    check testMatchBoolExprOperator(" >", 1, some(newMatches(1, 1, ">")))
    check testMatchBoolExprOperator(" <=", 1, some(newMatches(2, 1, "<=")))
    check testMatchBoolExprOperator(" >=", 1, some(newMatches(2, 1, ">=")))

    check testMatchBoolExprOperator("a == b", 2, some(newMatches(3, 2, "==")))

  test "testMatchCompareOperator":
    check testMatchCompareOperator("==", 0, some(newMatches(2, 0, "==")))
    check testMatchCompareOperator("!=", 0, some(newMatches(2, 0, "!=")))
    check testMatchCompareOperator("<", 0, some(newMatches(1, 0, "<")))
    check testMatchCompareOperator(">", 0, some(newMatches(1, 0, ">")))
    check testMatchCompareOperator("<=", 0, some(newMatches(2, 0, "<=")))
    check testMatchCompareOperator(">=", 0, some(newMatches(2, 0, ">=")))

  test "matchReplCmd":
    check testMatchReplCmd("v", 0, some(newMatches(1, 0, "v")))
    check testMatchReplCmd("q", 0, some(newMatches(1, 0, "q")))
    check testMatchReplCmd("h", 0, some(newMatches(1, 0, "h")))
    check testMatchReplCmd("v ", 0, some(newMatches(2, 0, "v")))
    check testMatchReplCmd("p", 0, some(newMatches(1, 0, "p")))
    check testMatchReplCmd("p ", 0, some(newMatches(2, 0, "p")))
    check testMatchReplCmd("pr ", 0, some(newMatches(3, 0, "pr")))
    check testMatchReplCmd("pj ", 0, some(newMatches(3, 0, "pj")))

  test "matchReplCmd":
    check testEmptyOrSpaces("", 0, true)
    check testEmptyOrSpaces(" ", 0, true)
    check testEmptyOrSpaces("  ", 0, true)
    check testEmptyOrSpaces("tea> ", 5, true)
    check testEmptyOrSpaces("tea> ", 6, true)
    check testEmptyOrSpaces("tea>  ", 5, true)
    check testEmptyOrSpaces("tea> ", 0, false)
    check testEmptyOrSpaces("a  ", 0, false)

  test "prepost string representation":
    var prepostList: seq[Prepost]

    prepostList = @[newPrepost("#$", "")]
    check($prepostList == "(#$, )")

    prepostList = @[newPrepost("<--$", "-->")]
    check($prepostList == "(<--$, -->)")

    prepostList = @[newPrepost("<--$", "-->"), newPrepost("#$", "")]
    check($prepostList == "(<--$, -->), (#$, )")

  test "parsePrepost":
    check testParsePrepostGood("a,b", "a", ePostfix = "b")
    check testParsePrepostGood("a,b", "a", "b")
    check testParsePrepostGood("a", "a", "")
    check testParsePrepostGood("<--$,-->", "<--$", "-->")
    check testParsePrepostGood("$$", "$$", "")
    check testParsePrepostGood("1234567890123456789$,2234567890123456789$",
                               "1234567890123456789$", "2234567890123456789$")
    check testParsePrepostGood("# ", "# ", "")
    check testParsePrepostGood(" ", " ", "")
    check testParsePrepostGood("  ", "  ", "")
    check testParsePrepostGood("   ", "   ", "")
    check testParsePrepostGood("   ,   ", "   ", "   ")
    check testParsePrepostGood("[[$,]]", "[[$", "]]")
    check testParsePrepostGood("$$", "$$")

  test "testOrgModePrefix":
    check testParsePrepostGood("# $", "# $", "")

  test "testParsePrepostBad":
    check testParsePrepostBad("")
    check testParsePrepostBad(",")
    check testParsePrepostBad("a,")
    check testParsePrepostBad(",asdf")
    check testParsePrepostBad("a,b,")
    check testParsePrepostBad("123456789 123456789 1,b")
    check testParsePrepostBad("b,123456789 123456789 1")
    check testParsePrepostBad("añyóng")
    check testParsePrepostBad(newStrFromBuffer([0x08u8, 0x12]))
    check testParsePrepostBad(newStrFromBuffer([0x31u8, 0x2c, 0x12]))

  test "matchParameterType":
    check testMatchParameterType("bool")
    check testMatchParameterType("int")
    check testMatchParameterType("float")
    check testMatchParameterType("string")
    check testMatchParameterType("list")
    check testMatchParameterType("dict")
    check testMatchParameterType("func")
    check testMatchParameterType("any")

    check testMatchParameterType("optional bool", eParamTypeStr="bool", eOptional=true)
    check testMatchParameterType("optional int", eParamTypeStr="int", eOptional=true)
    check testMatchParameterType("optional   int  ", eParamTypeStr="int", eOptional=true)

    check testMatchParameterType("any ", "any", 4)
    check testMatchParameterType("any  ", "any", 5)
    check testMatchParameterType("any   ab", "any", 6)

    check testMatchParameterType("boolean", "bool", 4)

  test "matchParameterType bad":
    check testMatchParameterTypeBad("dic")
    check testMatchParameterTypeBad("abc")
    check testMatchParameterTypeBad("optional")
    check testMatchParameterTypeBad("optional num")

  test "matchDocComment":
    check testMatchDocComment("", 0)
    check testMatchDocComment("##", 0, some(newMatches(2, 0)))
    check testMatchDocComment(" ##", 0, some(newMatches(3, 0)))
    check testMatchDocComment("  ##", 0, some(newMatches(4, 0)))
    check testMatchDocComment("## comment", 0, some(newMatches(2, 0)))
    check testMatchDocComment("  ## comment", 0, some(newMatches(4, 0)))
