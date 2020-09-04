## Test parseCommandLine.nim

import unittest
import parseCommandLine
import streams

proc readLines(stream: Stream): seq[string] =
  stream.setPosition(0)
  for line in stream.lines():
    result.add line

proc tpcl(cmdLine: string, version: bool=false, help: bool=false, serverList: seq[string] = @[],
  sharedList: seq[string] = @[], templateList: seq[string] = @[], resultList: seq[string] = @[],
  warningLines: seq[string] = @[]) =
  
  var stream = newStringStream()
  defer: stream.close()

  let args = parseCommandLine(stream, cmdLine)
  let lines = stream.readLines()

  check(args.version == version)
  check(args.help == help)
  check(args.filenames[0] == serverList)
  check(args.filenames[1] == sharedList)
  check(args.filenames[2] == templateList)
  check(args.filenames[3] == resultList)
  check(lines == warningLines)



# statictea --server=server.json --sharedJson=shared.json --template=template.html --result=result.htm
# -s -j -t -r -v -h


suite "Test statictea.nim":

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
    tpcl("-r=result.html", resultList = @["result.html"])

  test "parseCommandLine-result":
    tpcl("--result=result.html", resultList = @["result.html"])

  test "parseCommandLine-happy-path":
    tpcl("-s=server.json -j=shared.json -t=tea.html -r=result.html",
         serverList = @["server.json"],
         sharedList = @["shared.json"],
         templateList = @["tea.html"],
         resultList = @["result.html"],
    )

  test "parseCommandLine-multiple":
    tpcl("-s=server.json -s=server2.json -j=shared.json -j=shared2.json -t=tea.html -r=result.html",
         serverList = @["server.json", "server2.json"],
         sharedList = @["shared.json", "shared2.json"],
         templateList = @["tea.html"],
         resultList = @["result.html"],
    )

  # Test some error cases.

  test "parseCommandLine-missing-name":
    tpcl("-s", warningLines = @["warning 4: No server filename. Use s=filename."])
