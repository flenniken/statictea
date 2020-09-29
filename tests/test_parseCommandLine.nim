## Test parseCommandLine.nim

import unittest
import args
import parseCommandLine
import warnenv
import streams

proc tpcl(
    cmdLine: string,
    version: bool=false,
    help: bool=false,
    update: bool=false,
    nolog: bool=false,
    resultFilename: string = "",
    serverList: seq[string] = @[],
    sharedList: seq[string] = @[],
    templateList: seq[string] = @[],
    warningLines: seq[string] = @[],
    prepostList: seq[Prepost]= @[]
      ) =

  openWarnStream(newStringStream())
  let args = parseCommandLine(cmdLine)
  let lines = readWarnLines()
  closeWarnStream()

  check(args.help == help)
  check(args.version == version)
  check(args.update == update)
  check(args.nolog == nolog)
  check(args.serverList == serverList)
  check(args.sharedList == sharedList)
  check(args.templateList == templateList)
  check(args.resultFilename == resultFilename)
  check(args.prepostList == prepostList)
  check(lines == warningLines)


suite "Test statictea.nim":

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

  test "parseCommandLine-v":
    tpcl("-v", version=true)

  test "parseCommandLine-h":
    tpcl("-h", help=true)

  test "parseCommandLine-t":
    tpcl("-t=tea.html", templateList = @["tea.html"])

  test "parseCommandLine-template":
    tpcl("--template=tea.html", templateList = @["tea.html"])

  test "parseCommandLine-s":
    tpcl("-s=server.json", serverList = @["server.json"])

  test "parseCommandLine-server":
    tpcl("--server=server.json", serverList = @["server.json"])

  test "parseCommandLine-j":
    tpcl("-j=shared.json", sharedList = @["shared.json"])

  test "parseCommandLine-shared":
    tpcl("--shared=shared.json", sharedList = @["shared.json"])

  test "parseCommandLine-r":
    tpcl("-r=result.html", resultFilename = "result.html")

  test "parseCommandLine-result":
    tpcl("--result=result.html", resultFilename = "result.html")

  test "parseCommandLine-n":
    tpcl("-n", nolog=true)

  test "parseCommandLine-nolog":
    tpcl("--nolog", nolog=true)

  test "parseCommandLine-happy-path":
    tpcl("-s=server.json -j=shared.json -t=tea.html -r=result.html",
         serverList = @["server.json"],
         sharedList = @["shared.json"],
         templateList = @["tea.html"],
         resultFilename = "result.html",
    )

  test "parseCommandLine-multiple":
    tpcl("-s=server.json -s=server2.json -j=shared.json -j=shared2.json -t=tea.html -r=result.html",
         serverList = @["server.json", "server2.json"],
         sharedList = @["shared.json", "shared2.json"],
         templateList = @["tea.html"],
         resultFilename = "result.html",
    )

  # You cannot test quotes here. The quote processing happens before sending to the parser.
  # test "parseCommandLine-quotes1":
  #   tpcl("-r='result.html'", resultFilename = "result.html")

  # test "parseCommandLine-quotes2":
  #   tpcl("-r=\"name with spaces result.html\"", resultFilename = "name with spaces result.html")

  test "parseCommandLine-prepost":
    tpcl("--prepost=<--$", prepostList = @[("<--$", "")])

  # Test some error cases.

  test "parseCommandLine-no-filename":
    tpcl("-s", warningLines = @["cmdline(0): w0: No server filename. Use s=filename."])

  test "parseCommandLine-no-switch":
    tpcl("-w", warningLines = @["cmdline(0): w1: Unknown switch: w."])

  test "parseCommandLine-no-long-switch":
    tpcl("--hello", warningLines = @["cmdline(0): w1: Unknown switch: hello."])

  test "parseCommandLine-no-arg":
    tpcl("bare", warningLines = @["cmdline(0): w2: Unknown argument: bare."])

  test "parseCommandLine-no-args":
    tpcl("bare naked", warningLines = @["cmdline(0): w2: Unknown argument: bare.",
    "cmdline(0): w2: Unknown argument: naked."])

  test "parseCommandLine-missing-result":
    tpcl("-r", warningLines = @["cmdline(0): w0: No result filename. Use r=filename."])

  test "parseCommandLine-two-results":
    tpcl("-r=result.html -r=asdf.html", resultFilename="result.html",
         warningLines = @["cmdline(0): w3: One result file allowed, skipping: 'asdf.html'."])
