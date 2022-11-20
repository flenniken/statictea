import std/unittest
import std/options
import std/tables
import env
import replacement
import matches
import linebuffer
import variables
import sharedtestcode
import opresult
import vartypes
import warnings
import messages
import unicodes
import compareLines

proc testTempSegments(replacmentBlock: string,
    variables: Variables = emptyVariables(),
    eResultLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
  ): bool =
  ## Test the TempSegments procedures.

  var env = openEnvTest("_testTempSegments.log")

  let startLineNum = 1
  var tempSegmentsO = allocTempSegments(env, startLineNum)
  var tempSegments = tempSegmentsO.get()

  let lines = splitNewLines(replacmentBlock)
  for line in lines:
    storeLineSegments(env, tempSegments, line)

  writeTempSegments(env, tempSegments, startLineNum, variables)
  tempSegments.closeDeleteTempSegments()

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines, eResultLines)

proc testLineToSegments(line: string, eSegments: seq[string]): bool =
  return expectedItems(visibleControl(line), lineToSegments(line), eSegments)

proc testFormatString(str: string, eStr: string,
    variables = emptyVariables()): bool =
  let stringOr = formatString(variables, str)
  if stringOr.isMessage:
    echo stringOr
    return false
  result = gotExpected(stringOr.value, eStr)

proc testFormatStringWarn(str: string, eWarningData: WarningData,
    variables = emptyVariables()): bool =
  let stringOr = formatString(variables, str)
  if stringOr.isValue:
    echo stringOr
    return false
  let warningData = stringOr.message
  result = gotExpected($warningData, $eWarningData)
  if not result:
    echo str
    echo getWarningLine("", 0, warningData.warning, warningData.p1)

proc testYieldReplacementLine(
    firstReplaceLine: string,
    replaceContent: string,
    command: string = "block",
    maxLines: Natural = 5,
    eErrLines: seq[string] = @[],
    eYieldLines: seq[ReplaceLine] = @[],
  ): bool =
  ## Test the yieldReplacementLine.

  var env = openEnvTest("_yieldReplacementLine.log", replaceContent)

  var lineBufferO = newLineBuffer(env.templateStream, filename = "testStream")
  if not lineBufferO.isSome:
    return false
  var lb = lineBufferO.get()
  let prepostTable = makeDefaultPrepostTable()

  var yieldLines = newSeq[ReplaceLine]()
  for replaceLine in yieldReplacementLine(env, firstReplaceLine, lb, prepostTable, command, maxLines):
    yieldLines.add(replaceLine)

  result = env.readCloseDeleteCompare(eErrLines = eErrLines)

  if not expectedItem("yieldLines", yieldLines, eYieldLines):
    result = false

suite "replacement":

  # s.test = "hello"
  # h.test = "there"
  # five = 5
  # t.five = 5
  # g.aboutfive = 5.11

  test "stringSegment":
    check stringSegment("", false) == "0,\n"
    check stringSegment("", true) == "3,\n"

    check stringSegment("a", false) == "0,a\n"
    check stringSegment("a", true) == "3,a\n"
    check stringSegment("\n", true) == "1,\n"

    check stringSegment("abc", false) == "0,abc\n"
    check stringSegment("abc", true) == "3,abc\n"
    check stringSegment("abc\n", true) == "1,abc\n"

  test "varSegment":
    check varSegment("", false) == "2,{}\n"
    check varSegment("", true) == "4,{}\n"

    check varSegment("a", false) == "2,{a}\n"
    check varSegment("a", true) == "4,{a}\n"

    check varSegment("abc", false) == "2,{abc}\n"
    check varSegment("abc", true) == "4,{abc}\n"

    check varSegment("s.abc", false) == "2,{s.abc}\n"
    check varSegment("s.abc", true) == "4,{s.abc}\n"

  test "lineToSegments":
    check testLineToSegments("test\n", @["1,test\n"])
    check testLineToSegments("test", @["3,test\n"])
    check testLineToSegments("{name}\n", @["2,{name}\n", "1,\n"])
    check testLineToSegments("{name}", @["4,{name}\n"])
    check testLineToSegments("test}", @["3,test}\n"])

    check testLineToSegments("te{1st", @["3,te{1st\n"])
    check testLineToSegments("abc {{ test {s.name} line\n", @["0,abc { test \n",
      "2,{s.name}\n", "1, line\n"])
    check testLineToSegments("abc {test {s.name} line\n", @[
      "0,abc {test \n",
      "2,{s.name}\n",
      "1, line\n",
    ])
    check testLineToSegments("abc { s.name } line\n", @[
      "1,abc { s.name } line\n",
    ])
    check testLineToSegments("abc { {s.name} line\n", @[
      "0,abc { \n",
      "2,{s.name}\n",
      "1, line\n",
    ])

  test "lineToSegments2":
    check testLineToSegments("te{st( ", @["3,te{st( \n"])
    check testLineToSegments("te{st(", @["3,te{st(\n"])

  test "lineToSegments3":
    check testLineToSegments("{var}", @["4,{var}\n"])
    check testLineToSegments("test\n", @["1,test\n"])
    check testLineToSegments("{var}\n", @["2,{var}\n", "1,\n"])

    check testLineToSegments("before{var}after\n", @[
      "0,before\n",
      "2,{var}\n",
      "1,after\n",
    ])

    check testLineToSegments("before{var}after{endingvar}", @[
      "0,before\n",
      "2,{var}\n",
      "0,after\n",
      "4,{endingvar}\n",
    ])

    check testLineToSegments("before {s.name} after {h.header}{a}end\n", @[
      "0,before \n",
      "2,{s.name}\n",
      "0, after \n",
      "2,{h.header}\n",
      "2,{a}\n",
      "1,end\n",
    ])

    check testLineToSegments(
      "{t.row}before {s.name} {{}after {h.header}{a}end\n", @[
      "2,{t.row}\n",
      "0,before \n",
      "2,{s.name}\n",
      "0, {}after \n",
      "2,{h.header}\n",
      "2,{a}\n",
      "1,end\n",
    ])

  test "varSegmentDotName":
    check varSegmentDotName("2,{n}\n") == "n"
    check varSegmentDotName("2,{t.n}\n") == "t.n"
    check varSegmentDotName("2,{s.name}\n") == "s.name"
    check varSegmentDotName("2,{a.b.c.d.e}\n") == "a.b.c.d.e"

  test "yieldReplacementLine nextline":
    let firstReplaceLine = "replacement block\n"
    let replaceContent = """
line 2
more text
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, firstReplaceLine)
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent, "nextline",
      eYieldLines = eYieldLines)

  test "yieldReplacementLine nextline fake block":
    let firstReplaceLine = "#$ endblock\n"
    let replaceContent = """
line 2
more text
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, firstReplaceLine)
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent, "nextline",
      eYieldLines = eYieldLines)

  test "yieldReplacementLine block":
    let firstReplaceLine = "replacement block\n"
    let replaceContent = """
line 2
more text
<!--$ endblock -->
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, "replacement block\n"),
      newReplaceLine(rlReplaceLine, "line 2\n"),
      newReplaceLine(rlReplaceLine, "more text\n"),
      newReplaceLine(rlEndblockLine, "<!--$ endblock -->\n"),
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent, eYieldLines = eYieldLines)

  test "yieldReplacementLine block max":
    let firstReplaceLine = "replacement block\n"
    let replaceContent = """
line 2
<!--$ endblock -->
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, "replacement block\n"),
      newReplaceLine(rlReplaceLine, "line 2\n"),
      newReplaceLine(rlEndblockLine, "<!--$ endblock -->\n"),
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent,
      eYieldLines = eYieldLines, maxLines = 2)

  test "yieldReplacementLine block max + 1":
    let firstReplaceLine = "replacement block\n"
    let replaceContent = """
line 2
line 3
<!--$ endblock -->
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, "replacement block\n"),
      newReplaceLine(rlReplaceLine, "line 2\n"),
      newReplaceLine(rlNormalLine, "line 3\n"),
    ]
    var eErrLines = @[
      "testStream(2): w60: Read t.maxLines replacement block lines without finding the endblock.\n"
    ]

    check testYieldReplacementLine(firstReplaceLine, replaceContent,
      eYieldLines = eYieldLines, maxLines = 2, eErrLines = eErrLines)

    check testYieldReplacementLine(firstReplaceLine, replaceContent,
      eYieldLines = eYieldLines, maxLines = 2, eErrLines = eErrLines)

  test "yieldReplacementLine exceed maxLines":
    let firstReplaceLine = "one\n"
    let replaceContent = """
two
three
four
five
six
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, "one\n"),
      newReplaceLine(rlReplaceLine, "two\n"),
      newReplaceLine(rlReplaceLine, "three\n"),
      newReplaceLine(rlReplaceLine, "four\n"),
      newReplaceLine(rlNormalLine, "five\n"),
    ]
    var eErrLines = @[
      "testStream(4): w60: Read t.maxLines replacement block lines without finding the endblock.\n"
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent, maxLines = 4,
      eYieldLines = eYieldLines, eErrLines = eErrLines)

  test "yieldReplacementLine no more lines":
    let firstReplaceLine = "one\n"
    let replaceContent = """
two
three
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, "one\n"),
      newReplaceLine(rlReplaceLine, "two\n"),
      newReplaceLine(rlReplaceLine, "three\n"),
    ]

    check testYieldReplacementLine(firstReplaceLine, replaceContent, maxLines = 10,
      eYieldLines = eYieldLines)

  test "yieldReplacementLine endblock":
    let firstReplaceLine = "one\n"
    let replaceContent = """
two
three
<!--$ endblock -->
more
lines
"""
    var eYieldLines = @[
      newReplaceLine(rlReplaceLine, "one\n"),
      newReplaceLine(rlReplaceLine, "two\n"),
      newReplaceLine(rlReplaceLine, "three\n"),
      newReplaceLine(rlEndblockLine, "<!--$ endblock -->\n"),
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent, maxLines = 10,
      eYieldLines = eYieldLines)

  test "yieldReplacementLine no content":
    let firstReplaceLine = "<!--$ endblock -->\n"
    let replaceContent = """
two
three
"""
    var eYieldLines = @[
      newReplaceLine(rlEndblockLine, firstReplaceLine),
    ]
    check testYieldReplacementLine(firstReplaceLine, replaceContent, maxLines = 10,
      eYieldLines = eYieldLines)

  test "yieldReplacementLine no lines":
    let firstReplaceLine = ""
    let replaceContent = ""
    check testYieldReplacementLine(firstReplaceLine, replaceContent)

  test "yieldReplacementLine no lines nextline":
    let firstReplaceLine = ""
    let replaceContent = ""
    check testYieldReplacementLine(firstReplaceLine, replaceContent, command = "nextline")

  test "replace line":
    var replaceLine: ReplaceLine
    check replaceLine.kind == rlNoLine

  test "formatString":
    check testFormatString("", "")
    check testFormatString("a", "a")
    check testFormatString("ab", "ab")
    check testFormatString("}", "}")

    var variables = emptyVariables()
    variables["l"].dictv["v"] = newValue("a")
    variables["l"].dictv["v2"] = newValue("ab")
    variables["l"].dictv["v3"] = newValue("xyz")

    check testFormatString("{v}", "a", variables)
    check testFormatString("{v2}", "ab", variables)
    check testFormatString("{v3}", "xyz", variables)

    check testFormatString("{l.v}", "a", variables)

    check testFormatString("1{v}2", "1a2", variables)
    check testFormatString("1{v3}2", "1xyz2", variables)

    check testFormatString("{v}{v}", "aa", variables)
    check testFormatString("{v}{v2}", "aab", variables)
    check testFormatString("{v}{v2}{v3}", "aabxyz", variables)

    check testFormatString("{{{v} {{ } {v2}{v3}", "{a { } abxyz", variables)

    check testFormatString(" {v} {v} ", " a a ", variables)

    check testFormatString("{{", "{", variables)
    check testFormatString(" {{ ", " { ", variables)

  test "formatString warnings":
    check testFormatStringWarn("{", newWarningData(wNoEndingBracket, "", 1))
    check testFormatStringWarn("{a", newWarningData(wNoEndingBracket, "", 2))
    check testFormatStringWarn("  {a", newWarningData(wNoEndingBracket, "", 4))
    check testFormatStringWarn("  {abcd", newWarningData(wNoEndingBracket, "", 7))

    check testFormatStringWarn("{a", newWarningData(wNoEndingBracket, "", 2))
    check testFormatStringWarn("{abc", newWarningData(wNoEndingBracket, "", 4))

    check testFormatStringWarn("{3", newWarningData(wInvalidVarNameStart, "", 1))
    check testFormatStringWarn("{3}", newWarningData(wInvalidVarNameStart, "", 1))
    check testFormatStringWarn(" {3}", newWarningData(wInvalidVarNameStart, "", 2))

    check testFormatStringWarn("{a}", newWarningData(wNotInLorF, "a", 1))
    check testFormatStringWarn("{l.a}", newWarningData(wVariableMissing, "a", 1))
    check testFormatStringWarn("{a!}", newWarningData(wInvalidVarName, "", 2))

    check testFormatStringWarn("{{{a!}", newWarningData(wInvalidVarName, "", 4))

  test "testTempSegments empty block":
    check testTempSegments("")

  test "testTempSegments one line":
    let eResultLines = @["one line"]
    check testTempSegments("one line", eResultLines=eResultLines)

  test "testTempSegments two lines":
    let lines = """
one line
two lines
"""
    let eResultLines = splitNewlines(lines)
    check testTempSegments(lines, eResultLines=eResultLines)

  test "testTempSegments missing var":
    let lines = """
{var}
"""
    let eResultLines = splitNewlines(lines)
    let eErrLines = @["template.html(1): w58: The replacement variable doesn't exist: var.\n"]
    check testTempSegments(lines, eErrLines=eErrLines, eResultLines=eResultLines)

  test "testTempSegments var":
    var variables = emptyVariables()
    discard assignVariable(variables, "var", newValue(5))
    let lines = """
{var}
"""
    let eLines = """
5
"""
    let eResultLines = splitNewlines(eLines)
    check testTempSegments(lines, variables=variables, eResultLines=eResultLines)

  test "testTempSegments multiple vars":
    var variables = emptyVariables()
    discard assignVariable(variables, "var", newValue(5))
    let lines = """
{var}
line
line {var}
{var} line
asdf {var} line
{var}{var} line
{{
}}}
"""
    let eLines = """
5
line
line 5
5 line
asdf 5 line
55 line
{
}}}
"""
    let eResultLines = splitNewlines(eLines)
    check testTempSegments(lines, variables=variables, eResultLines=eResultLines)
