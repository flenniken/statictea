
import unittest
import processTemplate
import env
import args
import os
import logenv
import readjson

suite "processTemplate":

  test "createFile":
    let filename = "template.html"
    createFile(filename, "Hello")
    defer: discard tryRemoveFile(filename)
    let lines = readLines(filename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"

  test "processTemplate to stdout":
    var env = openEnv("_processTemplate.log")

    let templateFilename = "template.html"
    createFile(templateFilename, "Hello")
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
    createFile(templateFilename, "Hello")
    defer: discard tryRemoveFile(templateFilename)
    var lines = readLines(templateFilename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"

    var args: Args
    args.templateList = @[templateFilename]
    args.resultFilename = "resultToFile.txt"
    let rc = processTemplate(env, args)
    # defer: discard tryRemoveFile(args.resultFilename)

    # The template ane result streams should be closed.
    check env.templateFilename == templateFilename
    check env.templateStream == nil
    check env.resultFilename == args.resultFilename
    check env.resultStream == nil

    let (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 0

    lines = readLines(args.resultFilename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"
