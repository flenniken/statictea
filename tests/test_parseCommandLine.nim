## Test parseCommandLine.nim

import unittest
import args
import parseCommandLine
import streams
import testUtils

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
      ) =

  var stream = newStringStream()
  defer: stream.close()

  let args = parseCommandLine(stream, cmdLine)
  let lines = stream.readLines()

  check(args.help == help)
  check(args.version == version)
  check(args.update == update)
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

  test "readLines":
    var stream = newStringStream("testing")
    defer: stream.close()
    let warningLines = stream.readLines()
    check(warningLines.len == 1)
    check(warningLines[0] == "testing")

  test "readLines2":
    var stream = newStringStream()
    defer: stream.close()
    stream.writeLine("this is a test")
    stream.writeLine("1 2 3")
    let warningLines = stream.readLines()
    check(warningLines.len == 2)
    check(warningLines[0] == "this is a test")
    check(warningLines[1] == "1 2 3")

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

  test "args to string":
    var args: Args
    let expected = """
Args:
  help=false
  version=false
  update=false
  serverList=
  sharedList=
  templateList=
  resultFilename=
  prepostList=
"""
    check($args == expected)

  test "args to string2":
    var args: Args
    args.help = true
    args.serverList = @["server.json", "more.json"]
    args.sharedList = @["shared.json"]
    args.resultFilename = "result.html"
    let expected = """
Args:
  help=true
  version=false
  update=false
  serverList=server.json, more.json
  sharedList=shared.json
  templateList=
  resultFilename=result.html
  prepostList=
"""
    check($args == expected)

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
    tpcl("-s", warningLines = @["warning 1: No server filename. Use s=filename."])

  test "parseCommandLine-no-switch":
    tpcl("-w", warningLines = @["warning 2: Unknown switch: w"])

  test "parseCommandLine-no-long-switch":
    tpcl("--hello", warningLines = @["warning 2: Unknown switch: hello"])

  test "parseCommandLine-no-arg":
    tpcl("bare", warningLines = @["warning 3: Unknown argument: bare"])

  test "parseCommandLine-no-args":
    tpcl("bare naked", warningLines = @["warning 3: Unknown argument: bare",
    "warning 3: Unknown argument: naked"])

  test "parseCommandLine-missing-result":
    tpcl("-r", warningLines = @["warning 1: No result filename. Use r=filename."])

  test "parseCommandLine-two-results":
    tpcl("-r=result.html -r=asdf.html", resultFilename="result.html",
         warningLines = @["warning 4: One result file allowed, skipping: asdf.html"])
