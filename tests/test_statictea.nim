import unittest
import statictea
import parseopt
import streams
# import parseCommandLine

proc readLines(stream: Stream): seq[string] =
  for line in stream.lines():
    result.add line


proc parseArgs(theArgs: seq[string]): tuple[args: Args, warningLines: seq[string]] =
  var optParser = initOptParser(theArgs)
  var stream = newStringStream()
  defer: stream.close()
  var args = parseCommandLine(optParser, stream)
  var warningLines = stream.readLines()
  result = (args, warningLines)


# statictea --data serverdata.json --shared shared.json --template template.html --result result.html
# -d -s -t -r -v -h


suite "Test statictea.nim":

  test "parseCommandLine-v":
    var (args, lines) = parseArgs(@["-v"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == true)
    check(args.templates.len == 0)

  test "parseCommandLine-h":
    var (args, lines) = parseArgs(@["-h"])
    check(lines.len == 0)
    check(args.help == true)
    check(args.version == false)
    check(args.templates.len == 0)

  test "parseCommandLine-t":
    var (args, lines) = parseArgs(@["-t=tea.html"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.templates.len == 1)
    check(args.templates[0] == "tea.html")

  test "parseCommandLine-template":
    var (args, lines) = parseArgs(@["--template=tea.html"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.templates.len == 1)
    check(args.templates[0] == "tea.html")

  test "parseCommandLine-d":
    var (args, lines) = parseArgs(@["-d=server.json"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.server.len == 1)
    check(args.server[0] == "server.json")

  test "parseCommandLine-data":
    var (args, lines) = parseArgs(@["--data=server.json"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.server.len == 1)
    check(args.server[0] == "server.json")

  test "parseCommandLine-s":
    var (args, lines) = parseArgs(@["-s=shared.json"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.shared.len == 1)
    check(args.shared[0] == "shared.json")

  test "parseCommandLine-shared":
    var (args, lines) = parseArgs(@["--shared=shared.json"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.shared.len == 1)
    check(args.shared[0] == "shared.json")

  test "parseCommandLine-happy-path":
    var (args, lines) = parseArgs(@["-d=server.json", "-s=shared.json", "-t=tea.html", "-r=result.html"])
    check(lines.len == 0)
    check(args.help == false)
    check(args.version == false)
    check(args.server.len == 1)
    check(args.server[0] == "server.json")
    check(args.shared.len == 1)
    check(args.shared[0] == "shared.json")
    check(args.templates.len == 1)
    check(args.templates[0] == "tea.html")
