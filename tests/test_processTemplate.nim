
import unittest
import processTemplate
import env
import args
import os
import logenv
import readjson

suite "processTemplate":

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
    defer: discard tryRemoveFile(args.resultFilename)
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 0
    let lines = readLines(args.resultFilename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"
