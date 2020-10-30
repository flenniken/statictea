
import unittest
import processTemplate
import env
import args
import testutils
import os
import logenv
import options
import regexes

# todo: test line endings on Windows

proc checkGetCommand(line: string, start: Natural, expected: string, expectedLength: Natural) =
  let matchesO = getCommand(line, start)
  check matchesO.isSome
  let matches = matchesO.get()
  check matches.getGroup() == expected
  check matches.length == expectedLength

suite "processTemplate":
  test "getCommand":
    let line = "<--$ nextline -->"
    let expected = "nextline"
    checkGetCommand(line, 5, expected, 9)

  # test "matchLastPart":
  #   let line = "<--$ nextline -->\n"
  #   let matchesO = matchLastPart(line, "-->", 15)
  #   check matchesO.isSome
  #   let matches = matchesO.get()
  #   let continuation = matches.getGroup()
  #   let length = matches.length
  #   check continuation == ""
  #   check length == 4

  test "processTemplate to stdout":
    var env = openEnv("_processTemplate.log")

    let templateFilename = "template.html"
    let content = "Hello"
    createFile(templateFilename, content)
    defer: discard tryRemoveFile(templateFilename)

    var args: Args
    args.templateList = @["template.html"]
    let rc = processTemplate(env, args)
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 1
    check outLines[0] == "Hello"

  test "processTemplate to file":
    var env = openEnv("_processTemplateFile.log")

    let templateFilename = "template.html"
    let content = "Hello"
    createFile(templateFilename, content)
    defer: discard tryRemoveFile(templateFilename)

    var args: Args
    args.templateList = @["template.html"]
    args.resultFilename = "resultToFile.txt"
    let rc = processTemplate(env, args)
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 0
    let lines = readLines(args.resultFilename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"
