## Test parseCommandLine.nim

import unittest
import parseCommandLine
import streams


proc readLines(stream: Stream): seq[string] =
  stream.setPosition(0)
  for line in stream.lines():
    result.add line


proc parseCmdLine(cmdLine: string): tuple[args: Args, warningLines: seq[string]] =
  var stream = newStringStream()
  defer: stream.close()
  let args = parseCommandLine(stream, cmdLine)
  let warningLines = stream.readLines()
  result = (args, warningLines)


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
    var (args, lines) = parseCmdLine("-v")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == true)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)

  test "parseCommandLine-h":
    var (args, lines) = parseCmdLine("-h")
    check(lines.len == 0)
    check(args.help == true)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)

  test "parseCommandLine-t":
    var (args, lines) = parseCmdLine("-t=tea.html")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 1)
    check(args.filenames[2][0] == "tea.html")
    check(args.filenames[3].len == 0)

  test "parseCommandLine-template":
    var (args, lines) = parseCmdLine("--template=tea.html")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 1)
    check(args.filenames[2][0] == "tea.html")
    check(args.filenames[3].len == 0)

  test "parseCommandLine-s":
    var (args, lines) = parseCmdLine("-s=server.json")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 1)
    check(args.filenames[0][0] == "server.json")
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)

  test "parseCommandLine-server":
    var (args, lines) = parseCmdLine("--server=server.json")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 1)
    check(args.filenames[0][0] == "server.json")
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)

  test "parseCommandLine-j":
    var (args, lines) = parseCmdLine("-j=shared.json")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 1)
    check(args.filenames[1][0] == "shared.json")
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)

  test "parseCommandLine-shared":
    var (args, lines) = parseCmdLine("--shared=shared.json")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 1)
    check(args.filenames[1][0] == "shared.json")
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)

  test "parseCommandLine-r":
    var (args, lines) = parseCmdLine("-r=result.html")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 1)
    check(args.filenames[3][0] == "result.html")

  test "parseCommandLine-result":
    var (args, lines) = parseCmdLine("--result=result.html")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 1)
    check(args.filenames[3][0] == "result.html")

  test "parseCommandLine-happy-path":
    var (args, lines) = parseCmdLine("-s=server.json -j=shared.json -t=tea.html -r=result.html")
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 1)
    check(args.filenames[0][0] == "server.json")
    check(args.filenames[1].len == 1)
    check(args.filenames[1][0] == "shared.json")
    check(args.filenames[2].len == 1)
    check(args.filenames[2][0] == "tea.html")
    check(args.filenames[3].len == 1)
    check(args.filenames[3][0] == "result.html")
    check(lines.len == 0)

  test "parseCommandLine-multiple":
    var (args, lines) = parseCmdLine("-s=server.json -s=server2.json -j=shared.json -j=shared2.json -t=tea.html -r=result.html")
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 2)
    check(args.filenames[0][0] == "server.json")
    check(args.filenames[0][1] == "server2.json")
    check(args.filenames[1].len == 2)
    check(args.filenames[1][0] == "shared.json")
    check(args.filenames[1][1] == "shared2.json")
    check(args.filenames[2].len == 1)
    check(args.filenames[2][0] == "tea.html")
    check(args.filenames[3].len == 1)
    check(args.filenames[3][0] == "result.html")

  # Test some error cases.

  test "parseCommandLine-missing-name":
    var (args, lines) = parseCmdLine("-s")
    check(args.help == false)
    check(args.version == false)
    check(args.filenames[0].len == 0)
    check(args.filenames[1].len == 0)
    check(args.filenames[2].len == 0)
    check(args.filenames[3].len == 0)
    check(lines.len == 1)
    check(lines[0] == "warning 4: No server filename. Use s=filename.")
