
import unittest
import processTemplate
import env
import args
import testutils
import os

suite "processTemplate.nim":

  test "processTemplate":
    var env = openEnv("_processTemplate.log")
    let filename = "template.html"

    let content = "Hello"
    createFile(filename, content)

    var args: Args
    args.templateList = @["template.html"]
    let rc = processTemplate(env, args)
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()
    echoLines(logLines, errLines, outLines)

    discard tryRemoveFile(filename)
