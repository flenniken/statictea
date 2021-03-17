import os
import unittest
import env
import replacement
import matches
import variables
import options
import tempFile
import readlines
import varTypes

proc testTempSegments(variables: Variables, templateContent: string, command: string = "nextline", repeat: Natural = 1,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eResultLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testTempSegments.log", templateContent)

  var lineBufferO = newLineBuffer(env.templateStream)
  if not lineBufferO.isSome:
    return false
  var lb = lineBufferO.get()
  let compiledMatchers = getCompiledMatchers()
  var tempSegmentsO = newTempSegments(env, lb, compiledMatchers, command, repeat, variables)
  if not isSome(tempSegmentsO):
    return false
  var tempSegments = tempSegmentsO.get()
  var previousLine = ""
  for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
    if previousLine != "":
      storeLineSegments(env, tempSegments, compiledMatchers, previousLine)
    previousLine = line
  writeTempSegments(env, tempSegments, lb.lineNum, variables)
  closeDelete(tempSegments)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines, eResultLines)

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
    check varSegment("{a}", 1, 0, 1, false)     == "2,1   ,0,1  ,{a}\n"
    check varSegment("{ a }", 2, 0, 1, false)   == "2,2   ,0,1  ,{ a }\n"
    check varSegment("{ abc }", 2, 0, 3, false) == "2,2   ,0,3  ,{ abc }\n"
    check varSegment("{t.a}", 1, 2, 1, false)   == "2,1   ,2,1  ,{t.a}\n"
    check varSegment("{t.ab}", 1, 2, 2, false)  == "2,1   ,2,2  ,{t.ab}\n"

    check varSegment("{a}", 1, 0, 1, true)     == "4,1   ,0,1  ,{a}\n"
    check varSegment("{ a }", 2, 0, 1, true)   == "4,2   ,0,1  ,{ a }\n"
    check varSegment("{ abc }", 2, 0, 3, true) == "4,2   ,0,3  ,{ abc }\n"
    check varSegment("{t.a}", 1, 2, 1, true)   == "4,1   ,2,1  ,{t.a}\n"
    check varSegment("{t.ab}", 1, 2, 2, true)  == "4,1   ,2,2  ,{t.ab}\n"

  test "lineToSegments":
    let compiledMatchers = getCompiledMatchers()
    check expectedItems("segments", lineToSegments(compiledMatchers, "test\n"), @["1,test\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "test"), @["3,test\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "te{1st"), @[
      "0,te{\n",
      "3,1st\n",
    ])
    check expectedItems("segments", lineToSegments(compiledMatchers, "te{st "), @["3,te{st \n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "{var}"), @["4,1   ,0,3  ,{var}\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "test\n"), @["1,test\n"])
    check expectedItems("segments", lineToSegments(compiledMatchers, "{var}\n"), @["2,1   ,0,3  ,{var}\n", "1,\n"])

    check expectedItems("segments", lineToSegments(compiledMatchers, "before{var}after\n"), @[
      "0,before\n",
      "2,1   ,0,3  ,{var}\n",
      "1,after\n",
    ])

    check expectedItems("segments", lineToSegments(compiledMatchers, "before{var}after{endingvar}"), @[
      "0,before\n",
      "2,1   ,0,3  ,{var}\n",
      "0,after\n",
      "4,1   ,0,9  ,{endingvar}\n",
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

  test "parseVarSegment":
    check parseVarSegment("2,1   ,0,1  ,{n}") == (namespace: "", name: "n")
    check parseVarSegment("2,1   ,2,1  ,{t.n}") == (namespace: "t.", name: "n")
    check parseVarSegment("2,2   ,2,4  ,{ s.name }") == (namespace: "s.", name: "name")
    check parseVarSegment("2,2   ,2,4  ,{ s.name    }") == (namespace: "s.", name: "name")
    check parseVarSegment("2,7   ,2,4  ,{      s.name }") == (namespace: "s.", name: "name")
    check parseVarSegment("2,4   ,0,4  ,{   name }") == (namespace: "", name: "name")

  test "TempSegments nextline":
    let templateContent = """
replacement block
line 2
more text
"""
    var eResultLines = @[
      "replacement block\n",
    ]
    var variables = emptyVariables()
    check testTempSegments(variables, templateContent, command = "nextline", repeat = 1, eResultLines = eResultLines)

  test "TempSegments nextline variables":
    let templateContent = """
{s.test} {h.test}!
"""
    var eResultLines = @[
      "hello there!\n",
    ]
    var variables = emptyVariables()
    assignVariable(variables, "t.", "server", newValue(newVarsDict()))
    assignVariable(variables, "t.", "shared", newValue(newVarsDict()))
    assignVariable(variables, "s.", "test", newValue("hello"))
    assignVariable(variables, "h.", "test", newValue("there"))
    check testTempSegments(variables, templateContent, command = "nextline", repeat = 1, eResultLines = eResultLines)

  test "TempSegments nextline variables":
    let templateContent = """
{s.test} {h.test}!
"""
    var eResultLines = @[
      "hello there!\n",
    ]
    var variables = emptyVariables()
    assignVariable(variables, "t.", "server", newValue(newVarsDict()))
    assignVariable(variables, "t.", "shared", newValue(newVarsDict()))
    assignVariable(variables, "s.", "test", newValue("hello"))
    assignVariable(variables, "h.", "test", newValue("there"))
    check testTempSegments(variables, templateContent, command = "nextline", repeat = 1, eResultLines = eResultLines)

  test "TempSegments nextline variables 2":
    let templateContent = "{s.test} {h.test}"
    var eResultLines = @["hello there"]
    var variables = emptyVariables()
    assignVariable(variables, "t.", "server", newValue(newVarsDict()))
    assignVariable(variables, "t.", "shared", newValue(newVarsDict()))
    assignVariable(variables, "s.", "test", newValue("hello"))
    assignVariable(variables, "h.", "test", newValue("there"))
    check testTempSegments(variables, templateContent, command = "nextline", repeat = 1, eResultLines = eResultLines)


  # s.test = "hello"
  # h.test = "there"
  # five = 5
  # t.five = 5
  # g.aboutfive = 5.11

  test "TempSegments block":
    let templateContent = """
replacement {abc} block
{s.test} {abc}
more text {missing}
<!--$ endblock -->
"""
    var eResultLines = splitNewLines """
replacement {abc} block
hello {abc}
more text {missing}
"""
    # Note: the line number is handled at a higher level.
    var eErrLines = splitNewLines """
template.html(4): w58: The replacement variable doesn't exist: abc.
template.html(5): w58: The replacement variable doesn't exist: abc.
template.html(6): w58: The replacement variable doesn't exist: missing.
"""
    var variables = emptyVariables()
    assignVariable(variables, "t.", "server", newValue(newVarsDict()))
    assignVariable(variables, "s.", "test", newValue("hello"))
    check testTempSegments(variables, templateContent, command = "block", repeat = 1,
      eErrLines = eErrLines, eResultLines = eResultLines)

  test "TempSegments maxLines":
    let templateContent = """
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
    var eResultLines = splitNewLines """
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
"""
    # Note: the line number is handled at a higher level.
    var eErrLines = @[
      "template.html(10): w60: Reached the maximum replacement block line count without finding the endblock.\n",
    ]
    var variables = emptyVariables()
    check testTempSegments(variables, templateContent, command = "block", repeat = 1,
      eErrLines = eErrLines, eResultLines = eResultLines)
