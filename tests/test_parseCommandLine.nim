## Test parseCommandLine.nim

import unittest
import args
import parseCommandLine
import warnenv
import streams
import env

proc tpcl(
    cmdLine: string,
    version: bool=false,
    help: bool=false,
    update: bool=false,
    resultFilename: string = "",
    serverList: seq[string] = @[],
    sharedList: seq[string] = @[],
    templateList: seq[string] = @[],
    warningLines: seq[string] = @[],
    prepostList: seq[Prepost]= @[]
      ): bool =

  openWarnStream(newStringStream())
  let args = parseCommandLine(cmdLine)
  let lines = readWarnLines()
  closeWarnStream()

  notReturn expectedItem("help", args.help, help)
  notReturn expectedItem("version", args.version, version)
  notReturn expectedItem("update", args.update, update)
  notReturn expectedItem("serverList", args.serverList, serverList)
  notReturn expectedItem("sharedList", args.sharedList, sharedList)
  notReturn expectedItem("templateList", args.templateList, templateList)
  notReturn expectedItem("resultFilename", args.resultFilename, resultFilename)
  notReturn expectedItems("prepostList", args.prepostList, prepostList)
  notReturn expectedItems("warningLines", lines, warningLines)
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

    prepostList = @[("#$", "")]
    check($prepostList == "(#$, )")

    prepostList = @[("<--$", "-->")]
    check($prepostList == "(<--$, -->)")

    prepostList = @[("<--$", "-->"), ("#$", "")]
    check($prepostList == "(<--$, -->), (#$, )")

  test "parsePrepost":
    check(parsePrepost("") == (("", ""), ""))
    check(parsePrepost("<--$") == (("<--$", ""), ""))
    check(parsePrepost("<--$ -->") == (("<--$", "-->"), ""))
    check(parsePrepost("<--$ --> extra") == (("<--$", "-->"), "extra"))
    check(parsePrepost("<--$ -->   extra  ") == (("<--$", "-->"), "extra  "))
    check(parsePrepost("a") == (("a", ""), ""))
    check(parsePrepost("a b") == (("a", "b"), ""))
    check(parsePrepost("a b c") == (("a", "b"), "c"))
    check(parsePrepost("   a b") == (("a", "b"), ""))
    check(parsePrepost("   a  ") == (("a", ""), ""))
    check(parsePrepost("     ") == (("", ""), ""))
    check(parsePrepost("a\n b\n") == (("a", "b"), ""))
    check(parsePrepost("nextline block") == (("nextline", "block"), ""))
    check(parsePrepost("\x19a b") == (("", ""), ""))
    check(parsePrepost("a b\x00y") == (("a", "b"), "\x00y"))
    check(parsePrepost("a \x00y") == (("a", ""), "\x00y"))

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
    check tpcl("--prepost=<--$", prepostList = @[("<--$", "")])

  # Test some error cases.

  test "parseCommandLine-no-filename":
    check tpcl("-s", warningLines = @["cmdline(0): w0: No server filename. Use s=filename."])

  test "parseCommandLine-no-switch":
    check tpcl("-w", warningLines = @["cmdline(0): w1: Unknown switch: w."])

  test "parseCommandLine-no-long-switch":
    check tpcl("--hello", warningLines = @["cmdline(0): w1: Unknown switch: hello."])

  test "parseCommandLine-no-arg":
    check tpcl("bare", warningLines = @["cmdline(0): w2: Unknown argument: bare."])

  test "parseCommandLine-no-args":
    check tpcl("bare naked", warningLines = @["cmdline(0): w2: Unknown argument: bare.",
    "cmdline(0): w2: Unknown argument: naked."])

  test "parseCommandLine-missing-result":
    check tpcl("-r", warningLines = @["cmdline(0): w0: No result filename. Use r=filename."])

  test "parseCommandLine-two-results":
    check tpcl("-r=result.html -r=asdf.html", resultFilename="result.html",
         warningLines = @["cmdline(0): w3: One result file allowed, skipping: 'asdf.html'."])
