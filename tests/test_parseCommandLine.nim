## Test parseCommandLine.nim

import std/unittest
import std/options
import std/strutils
import args
import parseCommandLine
import env
import messages
import warnings

proc parseCommandLine*(cmdLine: string = ""): ArgsOrWarning =
  let argv = cmdLine.splitWhitespace()
  result = parseCommandLine(argv)

func `$`(prepostList: seq[Prepost]): string =
  var parts: seq[string]
  for pp in prepostList:
    parts.add("($1, $2)" % [pp.prefix, pp.postfix])
  result = parts.join(", ")

proc newStrFromBuffer(buffer: openArray[uint8]): string =
  result = newStringOfCap(buffer.len)
  for ix in 0 ..< buffer.len:
    result.add((char)buffer[ix])

proc parseWarning(cmdline: string, eWarningData: WarningData): bool =
  result = true
  let argsOrWarning = parseCommandLine(cmdLine)
  if argsOrWarning.kind != awWarning:
    echo "Did not get a warning."
    result = false
  elif not expectedItem("warningData", argsOrWarning.warningData, eWarningData):
    result = false

proc tpcl(
    cmdLine: string,
    version: bool=false,
    help: bool=false,
    update: bool=false,
    log: bool=false,
    resultFilename: string = "",
    logFilename: string = "",
    serverList: seq[string] = @[],
    sharedList: seq[string] = @[],
    templateList: seq[string] = @[],
    prepostList: seq[Prepost]= @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
      ): bool =

  let argsOrWarning = parseCommandLine(cmdLine)
  if argsOrWarning.kind != awArgs:
    echo "Unexpected warning:"
    echo $argsOrWarning
    return false
  let args = argsOrWarning.args

  result = true
  if not expectedItem("help", args.help, help):
    result = false
  if not expectedItem("version", args.version, version):
    result = false
  if not expectedItem("update", args.update, update):
    result = false
  if not expectedItem("log", args.log, log):
    result = false
  if not expectedItem("serverList", args.serverList, serverList):
    result = false
  if not expectedItem("sharedList", args.sharedList, sharedList):
    result = false
  if not expectedItem("templateList", args.templateList, templateList):
    result = false
  if not expectedItem("resultFilename", args.resultFilename, resultFilename):
    result = false
  if not expectedItem("logFilename", args.logFilename, logFilename):
    result = false
  if not expectedItems("prepostList", args.prepostList, prepostList):
    result = false

proc testParsePrepostGood(str: string, ePrefix: string, ePostfix: string = ""): bool =
  let prepostO = parsePrepost(str)
  if not isSome(prepostO):
    echo "'$1' is not a valid prepost." % str
    return false
  result = true
  let prepost = prepostO.get()
  if not expectedItem("prefix", prepost.prefix, ePrefix):
    result = false
  if not expectedItem("postfix", prepost.postfix, ePostfix):
    result = false

proc testParsePrepostBad(str: string): bool =
  let prepostO = parsePrepost(str)
  if isSome(prepostO):
    echo "'$1' is a valid prepost." % str
    return false
  result = true

suite "parseCommandLine":

  test "fileListIndex":
    check(fileListIndex("server") == 0)
    check(fileListIndex("shared") == 1)
    check(fileListIndex("template") == 2)
    check(fileListIndex("other") == -1)

  test "letterToWord":
    check(letterToWord('s') == "server")
    check(letterToWord('j') == "shared")
    check(letterToWord('t') == "template")
    check(letterToWord('r') == "result")
    check(letterToWord('h') == "help")
    check(letterToWord('v') == "version")
    check(letterToWord('u') == "update")
    check(letterToWord('p') == "prepost")
    check(letterToWord('z') == "")

  test "prepost string representation":
    var prepostList: seq[Prepost]

    prepostList = @[newPrepost("#$", "")]
    check($prepostList == "(#$, )")

    prepostList = @[newPrepost("<--$", "-->")]
    check($prepostList == "(<--$, -->)")

    prepostList = @[newPrepost("<--$", "-->"), newPrepost("#$", "")]
    check($prepostList == "(<--$, -->), (#$, )")

  test "parsePrepost":
    check testParsePrepostGood("a,b", "a", ePostfix = "b")
    check testParsePrepostGood("a,b", "a", "b")
    check testParsePrepostGood("a", "a", "")
    check testParsePrepostGood("<--$,-->", "<--$", "-->")
    check testParsePrepostGood("$$", "$$", "")
    check testParsePrepostGood("1234567890123456789$,2234567890123456789$",
                               "1234567890123456789$", "2234567890123456789$")
    check testParsePrepostGood("# ", "# ", "")
    check testParsePrepostGood(" ", " ", "")
    check testParsePrepostGood("  ", "  ", "")
    check testParsePrepostGood("   ", "   ", "")
    check testParsePrepostGood("   ,   ", "   ", "   ")

  test "testOrgModePrefix":
    check testParsePrepostGood("# $", "# $", "")

  test "testParsePrepostBad":
    check testParsePrepostBad("")
    check testParsePrepostBad(",")
    check testParsePrepostBad("a,")
    check testParsePrepostBad(",asdf")
    check testParsePrepostBad("a,b,")
    check testParsePrepostBad("123456789 123456789 1,b")
    check testParsePrepostBad("b,123456789 123456789 1")
    check testParsePrepostBad("añyóng")
    check testParsePrepostBad(newStrFromBuffer([0x08u8, 0x12]))
    check testParsePrepostBad(newStrFromBuffer([0x31u8, 0x2c, 0x12]))

  test "parseCommandLine-v":
    check tpcl("-v", version=true)

  test "parseCommandLine-h":
    check tpcl("-h", help=true)

  test "parseCommandLine-t":
    check tpcl("-t=tea.html", templateList = @["tea.html"])

  test "parseCommandLine-template":
    check tpcl("--template=tea.html", templateList = @["tea.html"])

  test "parseCommandLine-s":
    check tpcl("-s=server.json", serverList = @["server.json"])

  test "parseCommandLine-server":
    check tpcl("--server=server.json", serverList = @["server.json"])

  test "parseCommandLine-j":
    check tpcl("-j=shared.json", sharedList = @["shared.json"])

  test "parseCommandLine-shared":
    check tpcl("--shared=shared.json", sharedList = @["shared.json"])

  test "parseCommandLine-r":
    check tpcl("-r=result.html", resultFilename = "result.html")

  test "parseCommandLine-result":
    check tpcl("--result=result.html", resultFilename = "result.html")

  test "parseCommandLine-log":
    check tpcl("-l", log = true)

  test "parseCommandLine-log with filename":
    check tpcl("--log=statictea.log", log = true, logFilename = "statictea.log")

  test "parseCommandLine-happy-path":
    check tpcl("-s=server.json -j=shared.json -t=tea.html -r=result.html",
         serverList = @["server.json"],
         sharedList = @["shared.json"],
         templateList = @["tea.html"],
         resultFilename = "result.html",
    )

  test "parseCommandLine-multiple":
    check tpcl("-s=server.json -s=server2.json -j=shared.json -j=shared2.json -t=tea.html -r=result.html",
         serverList = @["server.json", "server2.json"],
         sharedList = @["shared.json", "shared2.json"],
         templateList = @["tea.html"],
         resultFilename = "result.html",
    )

  # You cannot test quotes here. The quote processing happens before sending to the parser.
  # test "parseCommandLine-quotes1":
  #   check tpcl("-r='result.html'", resultFilename = "result.html")

  # test "parseCommandLine-quotes2":
  #   check tpcl("-r=\"name with spaces result.html\"", resultFilename = "name with spaces result.html")

  test "parseCommandLine-prepost":
    check tpcl("--prepost=<--$", prepostList = @[newPrepost("<--$", "")])

  # The test code splits args by spaces. The following "# $" becomes
  # two args "#" and "$".
  # See the external tests.
  # test "parseCommandLine org mode prefix":
  #   check tpcl("--prepost=# $", prepostList = @[newPrepost("# $", "")])

  # Test some error cases.

  test "parseCommandLine-no-filename":
    check parseWarning("-s", newWarningData(wNoFilename, "server", "s"))

  test "parseCommandLine-no-switch":
    check parseWarning("-w", newWarningData(wUnknownSwitch, "w"))

  test "parseCommandLine-no-long-switch":
    check parseWarning("--hello", newWarningData(wUnknownSwitch, "hello"))

  test "parseCommandLine-no-arg":
    check parseWarning("bare", newWarningData(wUnknownArg, "bare"))

  test "parseCommandLine-missing-result":
    check parseWarning("-r", newWarningData(wNoFilename, "result", "r"))

  test "parseCommandLine-two-results":
    check parseWarning("-r=result.html -r=asdf.html",
      newWarningData(wOneResultAllowed, "asdf.html"))
