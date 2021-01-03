
import unittest
import processTemplate
import env
import args
import os

proc testProcessTemplate(templateContent: string = "",
    serverJson: string = "",
    sharedJson: string = "",
    eRc = 0,
    eResultLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  ## Test the processTemplate procedure.

  # Open err, out and log streams.
  var env = openEnvTest("_testProcessTemplate.log")

  var args: Args

  # Create a template file from the given template content.
  let templateFilename = "template.html"
  createFile(templateFilename, templateContent)
  defer: discard tryRemoveFile(templateFilename)
  args.templateList = @[templateFilename]

  # Create the server json file.
  if serverJson != "":
    let serverFilename = "server.json"
    createFile(serverFilename, serverJson)
    defer: discard tryRemoveFile(serverFilename)
    args.serverList = @[serverFilename]

  # Create the shared json file.
  if sharedJson != "":
    let sharedFilename = "shared.json"
    createFile(sharedFilename, sharedJson)
    defer: discard tryRemoveFile(sharedFilename)
    args.sharedList = @[sharedFilename]

  args.resultFilename = "result.txt"

  # Process the template and write out the result.
  let rc = processTemplate(env, args)

  result = env.readCloseDeleteCompare()

  if not expectedItem("rc", rc, eRc):
    result = false

  # Read the result file.
  let resultLines = env.readCloseDeleteResult()
  if not expectedItems("resultLines", resultLines, eResultLines):
    result = false

suite "processTemplate":

  test "createFile":
    let filename = "template.html"
    createFile(filename, "Hello")
    defer: discard tryRemoveFile(filename)
    let lines = readLines(filename, maximum=4)
    check lines.len == 1
    check lines[0] == "Hello"

  test "processTemplate empty":
    check testProcessTemplate()

# todo: repeat of 0
# todo: repeat of 0 with warnings to verify line number
# todo: repeat > 0 with warnings to verify line number
