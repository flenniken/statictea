import std/unittest
import std/os
import codefile
import variables
import env

proc testRunCodeFile(
    content: string = "",
    variables: var Variables,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    showLog: bool = false
  ): bool =
  ## Test the runCodeFile procedure.

  # Open err and log streams.
  var env = openEnvTest("_testRunCodeFile.log")

  let filename = "_codefile.tmp"
  createFile(filename, content)
  defer: discard tryRemoveFile(filename)

  runCodeFile(env, filename, variables)

  result = true
  if not env.readCloseDeleteCompare(eLogLines, eErrLines, showLog = showLog):
    result = false

suite "codefile.nim":

  test "runCodeFile":
    let content = ""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables)
    # echo $variables
    # check variables.len == 0

