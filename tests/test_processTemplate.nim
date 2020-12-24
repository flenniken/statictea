
import unittest
import processTemplate
import env
import args
import os
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
    var env = openEnvTest("_processTemplateToStdout.log")

    let templateFilename = "template.html"
    createFile(templateFilename, "Hello")
    defer: discard tryRemoveFile(templateFilename)

    var args: Args
    args.templateList = @["template.html"]
    check env.addExtraStreams(args) == true
    check env.templateFilename == templateFilename
    check env.resultFilename == ""

    let rc = processTemplate(env, args)
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 1
    check outLines[0] == "Hello"

    env.close()

  test "processTemplate to file":
    var env = openEnvTest("_processTemplateToFile.log")

    # Create template file.
    let templateFilename = "template.html"
    createFile(templateFilename, "Hello")
    defer: discard tryRemoveFile(templateFilename)
    var lines = readLines(templateFilename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"

    # Add the template and result file to the environment.
    var args: Args
    args.templateList = @[templateFilename]
    args.resultFilename = "resultToFile.txt"
    let success = env.addExtraStreams(args)
    check success == true
    check env.templateFilename == templateFilename
    check env.resultFilename == args.resultFilename
    check env.resultStream != nil
    check env.templateStream != nil

    # echo "template stream:"
    # echoStream(env.templateStream)

    # Process the template and write out the result.
    let rc = processTemplate(env, args)

    # Read the log, err and out streams.
    let (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 0

    # Read the result file.
    let resultLines = env.readCloseDeleteResult()
    check resultLines.len == 1
    check resultLines[0] == "Hello"

    # The template and result streams should be closed.
    env.close()
    check env.templateStream == nil
    check env.resultStream == nil


  test "addExtraStreams two templates":
    var env = openEnvTest("_addExtraStreams.log")

    # Create template file.
    let templateFilename = "template.html"
    createFile(templateFilename, "Hello")
    defer: discard tryRemoveFile(templateFilename)
    var lines = readLines(templateFilename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"

    let templateFilename2 = "template2.html"
    createFile(templateFilename2, "Hello2")
    defer: discard tryRemoveFile(templateFilename2)
    var lines2 = readLines(templateFilename2, maximum=4)
    check lines2.len == 1
    check lines2[0] == "Hello2"

    # Add the template and result file to the environment.
    var args: Args
    args.templateList = @[templateFilename, templateFilename2]
    args.resultFilename = "resultToFile.txt"
    let success = env.addExtraStreams(args)
    check success == true
    check env.templateFilename == templateFilename
    check env.resultFilename == args.resultFilename
    check env.resultStream != nil
    check env.templateStream != nil

    # Process the template and write out the result.
    let rc = processTemplate(env, args)

    # Read the log, err and out streams.
    let eErrLines = @[
      "initializing(0): w5: One template file allowed on the command line, skipping: template2.html.",
    ]
    check env.readCloseDeleteCompare(eErrLines = eErrLines)

    # Read the result file.
    let resultLines = env.readCloseDeleteResult()
    check resultLines.len == 1
    check resultLines[0] == "Hello"

