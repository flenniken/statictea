## Test parseCommandLine.nim

import std/unittest
import std/options
import std/strutils
import std/os
import args
import parseCommandLine
import env
import messages
import warnings
import opresult
import sharedtestcode

proc parseCommandLine*(cmdLine: string = ""): ArgsOr =
  let argv = cmdLine.splitWhitespace()
  result = parseCommandLine(argv)

proc parseWarning(cmdline: string, eWarningData: WarningData): bool =
  result = true
  let argsOr = parseCommandLine(cmdLine)
  if argsOr.isValue:
    echo "Did not get a warning."
    result = false
  elif not expectedItem("warningData", argsOr.message, eWarningData):
    result = false

proc tpcl(
    cmdLine: string,
    version: bool=false,
    help: bool=false,
    update: bool=false,
    log: bool=false,
    repl: bool=false,
    resultFilename: string = "",
    logFilename: string = "",
    serverList: seq[string] = @[],
    codeList: seq[string] = @[],
    templateFilename: string = "",
    prepostList: seq[Prepost]= @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
      ): bool =

  let argsOr = parseCommandLine(cmdLine)
  if argsOr.isMessage:
    echo "Unexpected warning:"
    echo $argsOr
    return false
  let args = argsOr.value

  result = true
  if not expectedItem("help", args.help, help):
    result = false
  if not expectedItem("version", args.version, version):
    result = false
  if not expectedItem("update", args.update, update):
    result = false
  if not expectedItem("log", args.log, log):
    result = false
  if not expectedItem("repl", args.repl, repl):
    result = false
  if not expectedItem("serverList", args.serverList, serverList):
    result = false
  if not expectedItem("codeList", args.codeList, codeList):
    result = false
  if not expectedItem("templateFilename", args.templateFilename, templateFilename):
    result = false
  if not expectedItem("resultFilename", args.resultFilename, resultFilename):
    result = false
  if not expectedItem("logFilename", args.logFilename, logFilename):
    result = false

  if not expectedItems("prepostList", args.prepostList, prepostList):
    result = false

suite "parseCommandLine":

  test "parseCommandLine-v":
    check tpcl("-v", version=true)

  test "parseCommandLine-h":
    check tpcl("-h", help=true)

  test "parseCommandLine-t":
    check tpcl("-t tea.html", templateFilename = "tea.html")

  test "parseCommandLine-template":
    check tpcl("--template tea.html", templateFilename = "tea.html")

  test "parseCommandLine-s":
    check tpcl("-s server.json -t tea.html",
      templateFilename = "tea.html",
      serverList = @["server.json"])

  test "parseCommandLine-server":
    check tpcl("--server server.json -t tea.html",
      templateFilename = "tea.html",
      serverList = @["server.json"])

  test "parseCommandLine-o":
    check tpcl("-o shared.tea -t tea.html",
      templateFilename = "tea.html",
      codeList = @["shared.tea"])

  test "parseCommandLine-code":
    check tpcl("--code codefile.tea -t tea.html",
      templateFilename = "tea.html",
      codeList = @["codefile.tea"])

  test "parseCommandLine-r":
    check tpcl("-r result.html -t tea.html",
      templateFilename = "tea.html",
      resultFilename = "result.html")

  test "parseCommandLine-result":
    check tpcl("--result result.html -t tea.html",
      templateFilename = "tea.html",
      resultFilename = "result.html")

  test "parseCommandLine-log":
    check tpcl("-l -t tea.html", log = true,
      templateFilename = "tea.html")

  test "parseCommandLine-log with filename":
    check tpcl("--log statictea.log -t tea.html", log = true,
      templateFilename = "tea.html",
      logFilename = "statictea.log")

  test "parseCommandLine-happy-path":
    check tpcl("-s server.json -o codefile.tea -t tea.html -r result.html",
         serverList = @["server.json"],
         codeList = @["codefile.tea"],
         templateFilename = "tea.html",
         resultFilename = "result.html",
    )

  test "parseCommandLine-multiple":
    check tpcl("-s server.json -s server2.json -o codefile.tea -o codefile2.tea -t tea.html -r result.html",
         serverList = @["server.json", "server2.json"],
         codeList = @["codefile.tea", "codefile2.tea"],
         templateFilename = "tea.html",
         resultFilename = "result.html",
    )

  test "parseCommandLine-two-templates":
    let cmd = "-t tea.html -t tea2.html -r result"
    check parseWarning(cmd, newWarningData(
      wCmlAlreadyHaveOneArg, "template"))

  # You cannot test quotes here. The quote processing happens before sending to the parser.
  # test "parseCommandLine-quotes1":
  #   check tpcl("-r='result.html'", resultFilename = "result.html")

  # test "parseCommandLine-quotes2":
  #   check tpcl("-r=\"name with spaces result.html\"", resultFilename = "name with spaces result.html")

  test "parseCommandLine-prepost":
    let prepostList = @[newPrepost(r"<--$", "")]
    check tpcl("--prepost <--$ -t template", templateFilename = "template",
               prepostList = prepostList)

  # The test code splits args by spaces. The following "# $" becomes
  # two args "#" and "$".
  # See the external tests.
  # test "parseCommandLine org mode prefix":
  #   check tpcl("--prepost=# $", prepostList = @[newPrepost("# $", "")])

  # Test some error cases.

  test "parseCommandLine-no-filename":
    check parseWarning("-s", newWarningData(wCmlOptionRequiresArg, "server"))

  test "parseCommandLine-no-switch":
    check parseWarning("-w", newWarningData(wCmlInvalidShortOption, "w"))

  test "parseCommandLine-no-long-switch":
    check parseWarning("--hello", newWarningData(wCmlInvalidOption, "hello"))

  test "parseCommandLine-no-arg":
    check parseWarning("bare", newWarningData(wCmdTooManyBareArgs))

  test "parseCommandLine-missing-result":
    check parseWarning("-r", newWarningData(wCmlOptionRequiresArg, "result"))

  test "parseCommandLine-two-results":
    check parseWarning("-r result.html -r asdf.html",
      newWarningData(wCmlAlreadyHaveOneArg, "result"))

  test "template same as result":
    let filename = "tea.html"
    createFile(filename, "test file")
    let cmd = "-t tea.html -r tea.html"
    check parseWarning(cmd, newWarningData(wSameAsTemplate, "result"))
    discard tryRemoveFile(filename)

  test "template same as log":
    let filename = "tea.html"
    createFile(filename, "test file")
    let cmd = "-t tea.html -l tea.html"
    check parseWarning(cmd, newWarningData(wSameAsTemplate, "log"))
    discard tryRemoveFile(filename)

  test "result same as log":
    let filename = "tea.html"
    createFile(filename, "test file")
    let cmd = "-t template -r tea.html -l tea.html"
    check parseWarning(cmd, newWarningData(wSameAsResult, "log"))
    discard tryRemoveFile(filename)

  test "result with update":
    let cmd = "-u -t template.html -r tea.html"
    check parseWarning(cmd, newWarningData(wResultWithUpdate))

  test "-x":
    check tpcl("-x", repl = true)

  test "-x -s":
    check tpcl("-x -s server.json",
      repl = true,
      serverList = @["server.json"]
    )

  test "-x -s -o":
    check tpcl("-x -s server.json -o shared.tea",
      repl = true,
      serverList = @["server.json"],
      codeList = @["shared.tea"],
    )

  test "-x -s -o -t":
    check tpcl("-x -s server.json -o shared.tea -t tmpl.html",
      repl = true,
      serverList = @["server.json"],
      codeList = @["shared.tea"],
      templateFilename = "tmpl.html",
    )

  test "-l -t":
    check tpcl("-l -t tmpl.html",
      log = true,
      templateFilename = "tmpl.html",
    )

  test "-l -s -o -t -r -p":
    check tpcl(
      "-l -s server.json -o codefile.tea -s server2.json -p abc$,def -p $$ -r result.html -t tmpl.html",
      log = true,
      serverList = @["server.json", "server2.json"],
      codeList = @["codefile.tea"],
      templateFilename = "tmpl.html",
      resultFilename = "result.html",
      prepostList = @[newPrepost("abc$", "def"), newPrepost("$$", "")]
    )
