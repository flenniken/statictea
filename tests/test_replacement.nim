import os
import unittest
import env
import replacement
import matches
import variables
import streams
import options
import tempFile
import sets
import readlines

proc testTempSegments(content: string, command: string = "nextline", repeat: Natural = 1,
    eResultLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testTempSegments.log", "template.html")
  var inStream = newStringStream(content)
  if inStream == nil:
    return false
  var resultStream = newStringStream()
  if resultStream == nil:
    return false
  var lineBufferO = newLineBuffer(inStream)
  if not lineBufferO.isSome:
    return false
  var lb = lineBufferO.get()
  var tempSegmentsO = allocateTempSegments(env, lb.lineNum)
  if not isSome(tempSegmentsO):
    return false
  var tempSegments = tempSegmentsO.get()
  var variables = getTestVariables()
  let compiledMatchers = getCompiledMatchers()
  fillTempSegments(env, tempSegments, lb, compiledMatchers, command,
                   repeat, variables)
  # tempSegments.echoSegments()
  writeTempSegments(env, tempSegments, lb.lineNum, variables, resultStream)
  freeCloseDelete(tempSegments)
  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  var resultLines = readStream(resultStream)
  if not expectedItems("resultLines", resultLines, eResultLines):
    result = false


proc testReplaceLine(line: string,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eResultLines: seq[string] = @[],
  ): bool =

  var env = openEnvTest("_testReplaceLine.log", "template.html")

  var stream = newStringStream()
  let compiledMatchers = getCompiledMatchers()
  let variables = getTestVariables()
  let lineNum = 1
  replaceLine(env, compiledMatchers, variables, lineNum, line, stream)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  let resultLines = stream.readAndClose()
  if not expectedItems("result lines", resultLines, eResultLines):
    echo "    : 0123456789 123456789 123456789 123456789 123456789 123456789 123456789"
    echo "Line: " & line
    result = false


suite "processReplacementBlock":

  # s.test = "hello"
  # h.test = "there"
  # five = 5
  # t.five = 5
  # g.aboutfive = 5.11

  test "replaceLine empty":
    let line = ""
    check testReplaceLine(line)

  test "replaceLine no vars":
    let line = "this is a test."
    let eResultLines = @["this is a test."]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine one var":
    let line = "this is a test {s.test}."
    let eResultLines = @["this is a test hello."]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine two vars":
    let line = "this {s.test} is a test {s.test}."
    let eResultLines = @["this hello is a test hello."]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine hello":
    let line = "{s.test}"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine { no var":
    let line = "{4s.test}"
    let eResultLines = @["{4s.test}"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine no }":
    let line = "{s.test"
    let eResultLines = @["{s.test"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine missing var":
    let line = "{s.missing}"
    let eResultLines = @["{s.missing}"]
    let eErrLines = @["template.html(1): w58: The replacement variable doesn't exist: s.missing."]
    check testReplaceLine(line, eErrLines = eErrLines, eResultLines = eResultLines)

  test "replaceLine multiple vars":
    let line = "{five}{s.missing}{h.test}"
    let eResultLines = @["5{s.missing}there"]
    let eErrLines = @["template.html(1): w58: The replacement variable doesn't exist: s.missing."]
    check testReplaceLine(line, eErrLines = eErrLines, eResultLines = eResultLines)

  test "replaceLine var space before":
    let line = "{ s.test}"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine var space after":
    let line = "{s.test }"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine var lots of space":
    let line = "{        s.test       }"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "getTempFileStream":
    let tempFileStreamO = getTempFileStream()
    check isSome(tempFileStreamO)
    let tempFileStream = tempFileStreamO.get()
    let tempFile = tempFileStream.tempFile
    let stream = tempFileStream.stream
    tempFile.closeDelete()
    check not fileExists(tempFile.filename)

  test "stringSegment":
    check stringSegment("a", 0, 1) == "0,a\n"
    check stringSegment("\n", 0, 1) == "1,\n"
    check stringSegment("ab", 0, 2) == "0,ab\n"
    check stringSegment("a\n", 0, 2) == "1,a\n"

    check stringSegment("ab", 0, 1) == "0,a\n"
    check stringSegment("a\n", 0, 1) == "0,a\n"

    check stringSegment("ab", 1, 2) == "0,b\n"
    check stringSegment("a\n", 1, 2) == "1,\n"

    check stringSegment("test\n", 0, 2) == "0,te\n"
    check stringSegment("test\n", 1, 3) == "0,es\n"
    check stringSegment("test\n", 2, 4) == "0,st\n"
    check stringSegment("test\n", 3, 5) == "1,t\n"

    check stringSegment("", 0, 0) == "0,\n"
    check stringSegment("test", 4, 5) == "0,\n"
    check stringSegment("test", 3, 3) == "0,\n"
    check stringSegment("test", 3, 2) == "0,\n"

  test "varSegment":
    check varSegment("{a}", 1, 0, 1)     == "2,1   ,0,1  ,{a}\n"
    check varSegment("{ a }", 2, 0, 1)   == "2,2   ,0,1  ,{ a }\n"
    check varSegment("{ abc }", 2, 0, 3) == "2,2   ,0,3  ,{ abc }\n"
    check varSegment("{t.a}", 1, 2, 1)   == "2,1   ,2,1  ,{t.a}\n"
    check varSegment("{t.ab}", 1, 2, 2)  == "2,1   ,2,2  ,{t.ab}\n"

  test "lineToSegments":
    let compiledMatchers = getCompiledMatchers()
    check expectedItems("segments", lineToSegments(compiledMatchers, "test\n"), @["1,test\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "test"), @["0,test\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "te{1st"), @[
      "0,te{\n",
      "0,1st\n",
    ])
    check expectedItems("segments", lineToSegments(compiledMatchers, "te{st "), @["0,te{st \n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "te{st 123"), @[
      "0,te{st \n",
      "0,123\n",
    ])
    check expectedItems("segments", lineToSegments(compiledMatchers, "{var}"), @["2,1   ,0,3  ,{var}\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "test\n"), @["1,test\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "{var}\n"), @["2,1   ,0,3  ,{var}\n", "1,\n"])

    check expectedItems("segments", lineToSegments(compiledMatchers, "before{var}after\n"), @[
      "0,before\n",
      "2,1   ,0,3  ,{var}\n",
      "1,after\n",
    ])

    check expectedItems("segments", lineToSegments(compiledMatchers, "before {s.name} after {h.header}{ a }end\n"), @[
      "0,before \n",
      "2,1   ,2,4  ,{s.name}\n",
      "0, after \n",
      "2,1   ,2,6  ,{h.header}\n",
      "2,2   ,0,1  ,{ a }\n",
      "1,end\n",
    ])

    check expectedItems("segments", lineToSegments(compiledMatchers,
      "{  t.row}before {s.name} after {h.header}{ a }end\n"), @[
        "2,3   ,2,3  ,{  t.row}\n",
        "0,before \n",
        "2,1   ,2,4  ,{s.name}\n",
        "0, after \n",
        "2,1   ,2,6  ,{h.header}\n",
        "2,2   ,0,1  ,{ a }\n",
        "1,end\n",
      ])


  test "allocateTempSegments":
    var env = openEnvTest("_allocateTempSegments.log")

    var tempSegmentsO = allocateTempSegments(env, 0)

    check env.readCloseDeleteCompare()

    check tempSegmentsO.isSome
    var tempSegments = tempSegmentsO.get()
    check tempSegments.tempFile.filename != ""
    check tempSegments.lb.filename == tempSegments.tempFile.filename
    check tempSegments.oneWarnTable.len == 0

    tempSegments.freeCloseDelete()

  test "parseVarSegment":
    check parseVarSegment("2,1   ,0,1  ,{n}") == (namespace: "", name: "n")
    check parseVarSegment("2,1   ,2,1  ,{t.n}") == (namespace: "t.", name: "n")
    check parseVarSegment("2,2   ,2,4  ,{ s.name }") == (namespace: "s.", name: "name")
    check parseVarSegment("2,2   ,2,4  ,{ s.name    }") == (namespace: "s.", name: "name")
    check parseVarSegment("2,7   ,2,4  ,{      s.name }") == (namespace: "s.", name: "name")
    check parseVarSegment("2,4   ,0,4  ,{   name }") == (namespace: "", name: "name")

  test "TempSegments nextline":
    let content = """
replacement block
line 2
more text
"""
    var eResultLines = @[
      "replacement block",
    ]
    check testTempSegments(content, command = "nextline", repeat = 1, eResultLines = eResultLines)

  test "TempSegments nextline variables":
    let content = """
{s.test} {h.test}!
"""
    var eResultLines = @[
      "hello there!",
    ]
    check testTempSegments(content, command = "nextline", repeat = 1, eResultLines = eResultLines)

  test "TempSegments nextline variables":
    let content = """
{s.test} {h.test}!
"""
    var eResultLines = @[
      "hello there!",
    ]
    check testTempSegments(content, command = "nextline", repeat = 1, eResultLines = eResultLines)


  # s.test = "hello"
  # h.test = "there"
  # five = 5
  # t.five = 5
  # g.aboutfive = 5.11

  test "TempSegments block":
    let content = """
replacement {abc} block
{s.test} {abc}
more text {missing}
<!--$ endblock -->
"""
    var eResultLines = @[
      "replacement {abc} block",
      "hello {abc}",
      "more text {missing}",
    ]
    # Note: the line number is handled at a higher level.
    var eErrLines = @[
      "template.html(4): w58: The replacement variable doesn't exist: abc.",
      "template.html(6): w58: The replacement variable doesn't exist: missing.",
    ]
    check testTempSegments(content, command = "block", repeat = 1,
      eErrLines = eErrLines, eResultLines = eResultLines)

  test "TempSegments maxLines":
    let content = """
one
two
three
four
five
six
seven
eight
nine
ten
eleven
twelve
"""
    var eResultLines = @[
      "one",
      "two",
      "three",
      "four",
      "five",
      "six",
      "seven",
      "eight",
      "nine",
      "ten",
    ]
    # Note: the line number is handled at a higher level.
    var eErrLines = @[
      "template.html(10): w60: Reached the maximum replacement block line count without finding the endblock.",
    ]
    check testTempSegments(content, command = "block", repeat = 1,
      eErrLines = eErrLines, eResultLines = eResultLines)


  test "TempSegments clear":
    var env = openEnvTest("_allocateTempSegments.log")

    var tempSegmentsO = allocateTempSegments(env, 0)

    check env.readCloseDeleteCompare()

    check tempSegmentsO.isSome
    var tempSegments = tempSegmentsO.get()
    check tempSegments.tempFile.filename != ""
    check tempSegments.lb.filename == tempSegments.tempFile.filename
    check tempSegments.oneWarnTable.len == 0

    # Store segments in tempSegments.
    var variables = getTestVariables()
    let compiledMatchers = getCompiledMatchers()
    storeLineSegments(env, tempSegments, compiledMatchers, "first test line")

    # Clear the tempSegments object.
    tempSegments.clear()

    # Store segments in tempSegments.
    storeLineSegments(env, tempSegments, compiledMatchers, "after truncate line")

    # Read the stored segments.
    var resultStream = newStringStream()
    check resultStream != nil
    writeTempSegments(env, tempSegments, 0, variables, resultStream)

    tempSegments.freeCloseDelete()

    # echoStream(resultStream)
    var resultLines = readStream(resultStream)

    let eResultLines = @["after truncate line"]
    check expectedItems("resultLines", resultLines, eResultLines)
