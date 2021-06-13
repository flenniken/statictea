import std/os
import std/unittest
import std/options
import env
import replacement
import matches
import tempFile
import readlines

proc testYieldReplacementLine(
    firstReplaceLine: string,
    replaceContent: string,
    command: string = "block",
    maxLines: Natural = 5,
    eErrLines: seq[string] = @[],
    eYieldLines: seq[ReplaceLine] = @[],
  ): bool =
  ## Test the yieldReplacementLine.

  var env = openEnvTest("_testTempSegments.log", replaceContent)

  var lineBufferO = newLineBuffer(env.templateStream)
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

  test "getTempFileStream":
    let tempFileStreamO = getTempFileStream()
    check isSome(tempFileStreamO)
    let tempFileStream = tempFileStreamO.get()
    let tempFile = tempFileStream.tempFile
    tempFile.closeDelete()
    check not fileExists(tempFile.filename)

  test "stringSegment":
    check stringSegment("a", 0, 1) == "3,a\n"
    check stringSegment("\n", 0, 1) == "1,\n"
    check stringSegment("ab", 0, 2) == "3,ab\n"
    check stringSegment("a\n", 0, 2) == "1,a\n"

    check stringSegment("ab", 0, 1) == "0,a\n"
    check stringSegment("a\n", 0, 1) == "0,a\n"

    check stringSegment("ab", 1, 2) == "3,b\n"
    check stringSegment("a\n", 1, 2) == "1,\n"

    check stringSegment("test\n", 0, 2) == "0,te\n"
    check stringSegment("test\n", 1, 3) == "0,es\n"
    check stringSegment("test\n", 2, 4) == "0,st\n"
    check stringSegment("test\n", 3, 5) == "1,t\n"

  test "varSegment":
    check varSegment("{a}", 1, 1, false)     == "2,1   ,1   ,{a}\n"
    check varSegment("{ a }", 2, 1, false)   == "2,2   ,1   ,{ a }\n"
    check varSegment("{ abc }", 2, 3, false) == "2,2   ,3   ,{ abc }\n"
    check varSegment("{t.a}", 1, 3, false)   == "2,1   ,3   ,{t.a}\n"
    check varSegment("{t.ab}", 1, 4, false)  == "2,1   ,4   ,{t.ab}\n"

    check varSegment("{a}", 1, 1, true)     == "4,1   ,1   ,{a}\n"
    check varSegment("{ a }", 2, 1, true)   == "4,2   ,1   ,{ a }\n"
    check varSegment("{ abc }", 2, 3, true) == "4,2   ,3   ,{ abc }\n"
    check varSegment("{t.a}", 1, 3, true)   == "4,1   ,3   ,{t.a}\n"
    check varSegment("{t.ab}", 1, 4, true)  == "4,1   ,4   ,{t.ab}\n"

  test "lineToSegments":
    let prepostTable = makeDefaultPrepostTable()
    check expectedItems("segments", lineToSegments(prepostTable, "test\n"), @["1,test\n"])
    check expectedItems("segments", lineToSegments(prepostTable, "test"), @["3,test\n"])
    check expectedItems("segments", lineToSegments(prepostTable, "te{1st"), @[
      "0,te{\n",
      "3,1st\n",
    ])
    check expectedItems("segments", lineToSegments(prepostTable, "te{st "), @["3,te{st \n"])
    check expectedItems("segments", lineToSegments(prepostTable, "{var}"), @["4,1   ,3   ,{var}\n"])
    check expectedItems("segments", lineToSegments(prepostTable, "test\n"), @["1,test\n"])
    check expectedItems("segments", lineToSegments(prepostTable, "{var}\n"), @["2,1   ,3   ,{var}\n", "1,\n"])

    check expectedItems("segments", lineToSegments(prepostTable, "before{var}after\n"), @[
      "0,before\n",
      "2,1   ,3   ,{var}\n",
      "1,after\n",
    ])

    check expectedItems("segments", lineToSegments(prepostTable, "before{var}after{endingvar}"), @[
      "0,before\n",
      "2,1   ,3   ,{var}\n",
      "0,after\n",
      "4,1   ,9   ,{endingvar}\n",
    ])

    check expectedItems("segments", lineToSegments(prepostTable, "before {s.name} after {h.header}{ a }end\n"), @[
      "0,before \n",
      "2,1   ,6   ,{s.name}\n",
      "0, after \n",
      "2,1   ,8   ,{h.header}\n",
      "2,2   ,1   ,{ a }\n",
      "1,end\n",
    ])

    check expectedItems("segments", lineToSegments(prepostTable,
      "{  t.row}before {s.name} after {h.header}{ a }end\n"), @[
        "2,3   ,5   ,{  t.row}\n",
        "0,before \n",
        "2,1   ,6   ,{s.name}\n",
        "0, after \n",
        "2,1   ,8   ,{h.header}\n",
        "2,2   ,1   ,{ a }\n",
        "1,end\n",
      ])

  test "parseVarSegment":
    check parseVarSegment("2,1   ,1   ,{n}") == "n"
    check parseVarSegment("2,1   ,3   ,{t.n}") == "t.n"
    check parseVarSegment("2,2   ,6   ,{ s.name }") == "s.name"
    check parseVarSegment("2,2   ,6   ,{ s.name    }") == "s.name"
    check parseVarSegment("2,7   ,6   ,{      s.name }") == "s.name"
    check parseVarSegment("2,4   ,4   ,{   name }") == "name"

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
    ]
    var eErrLines = @[
      "template.html(4): w60: Reached the maximum replacement block line count without finding the endblock.\n"
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
