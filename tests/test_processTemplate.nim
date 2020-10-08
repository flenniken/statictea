
import unittest
import processTemplate
import env
import args
import testutils
import os

suite "processTemplate.nim":

  test "processTemplate":
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
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 0

