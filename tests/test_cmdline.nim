import std/unittest
import std/tables
import cmdline
import strutils

proc testCmdlineMessage(options: seq[CmlOption], line: string,
    eMessageId: CmlMessageId, eProblemParam: string = ""): bool =
  let parameters = split(line)
  let args = cmdline(options, parameters)
  if args.kind != cmlMessage:
    echo "The line did not generate a message."
    echo "got:"
    echo $args
    return false
  result = true
  if args.messageId != eMessageId:
    echo "Did not get the expected message id:"
    echo "expected: $1" % $eMessageId
    echo "     got: $1" % $args.messageid
    result = false

  if args.problemParam != eProblemParam:
    echo "Did not get the expected problem parameter:"
    echo "expected: $1" % eProblemParam
    echo "     got: $1" % args.problemParam
    result = false

  # if result:
  #   echo getMessage(args.messageid, args.problemParam)

suite "cmdline.nim":

  test "test me":
    check 1 == 1

  test "messages":
    check getMessage(cmlBareTwoDashes) == "Two dashes must be followed by an option name."

  test "newCmlOption":
    check $newCmlOption("help", 'h', cmlNoParameter) ==
      "option: long=help, short=h, optionType=cmlNoParameter"

    check $newCmlOption("log", 'l', cmlParameter) ==
      "option: long=log, short=l, optionType=cmlParameter"

    check $newCmlOption("param", 'p', cmlOptionalParameter) ==
      "option: long=param, short=p, optionType=cmlOptionalParameter"

    check $newCmlOption("param", '_', cmlBareParameter) ==
      "option: long=param, short=_, optionType=cmlBareParameter"

  test "cmdLine":
    var options = newSeq[CmlOption]()
    let parameters = newSeq[string]()
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgs
    check argsOrMessage.args.len == 0

  test "cmdLine":
    var options = newSeq[CmlOption]()
    let parameters = newSeq[string]()
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgs
    check argsOrMessage.args.len == 0

  test "bin/cmdline --help":
    let parameters = @["--help"]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlNoParameter))
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgs
    check argsOrMessage.args.len == 1
    check argsOrMessage.args["help"].len == 0

  test "bin/cmdline -h":
    let parameters = @["-h"]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlNoParameter))
    let args = cmdLine(options, parameters)
    check $args == """
args:
help: @[]"""

  test "bin/cmdline --help --log":
    let parameterSets = [
      ["--help", "--log"],
      ["-h", "-l"],
      ["--help", "-l"],
      ["-h", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("help", 'h', cmlNoParameter))
      options.add(newCmlOption("log", 'l', cmlNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
help: @[]
log: @[]"""

  test "bin/cmdline --server server.json":
    let parameterSets = [
      ["--server", "server.json"],
      ["-s", "server.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("server", 's', cmlParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
server: @["server.json"]"""

  test "bin/cmdline --server server.json --shared shared.json":
    let parameterSets = [
      ["--server", "server.json", "--shared", "shared.json"],
      ["-s", "server.json", "-j", "shared.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("server", 's', cmlParameter))
      options.add(newCmlOption("shared", 'j', cmlParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
server: @["server.json"]
shared: @["shared.json"]"""

  test "bin/cmdline --server server.json --server second.json":
    let parameters = @[
      "--server", "server.json",
      "--server", "second.json",
    ]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("server", 's', cmlParameter))
    let args = cmdLine(options, parameters)
    check $args == """
args:
server: @["server.json", "second.json"]"""

  test "bin/cmdline tea.svg":
    let parameterSets = [
      ["tea.svg"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("filename", '_', cmlBareParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
filename: @["tea.svg"]"""

  test "bin/cmdline tea.svg tea.svg.save":
    let parameterSets = [
      ["tea.svg", "tea.svg.save"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("source", '_', cmlBareParameter))
      options.add(newCmlOption("destination", '_', cmlBareParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
source: @["tea.svg"]
destination: @["tea.svg.save"]"""

  # Test optional parameter.

  test "bin/cmdline -t":
    let parameterSets = [
      ["-t"],
      ["--optional"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
optional: @[]"""

  test "bin/cmdline -t -l":
    let parameterSets = [
      ["-t", "-l"],
      ["--optional", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      options.add(newCmlOption("log", 'l', cmlNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
optional: @[]
log: @[]"""

  test "bin/cmdline tea.svg -t -l":
    let parameterSets = [
      ["tea.svg", "-t", "-l"],
      ["tea.svg", "--optional", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("filename", '_', cmlBareParameter))
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      options.add(newCmlOption("log", 'l', cmlNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
filename: @["tea.svg"]
optional: @[]
log: @[]"""

  test "bin/cmdline -lt":
    let parameterSets = [
      ["-lt"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      options.add(newCmlOption("log", 'l', cmlNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
log: @[]
optional: @[]"""

  test "bin/cmdline cmlBareTwoDashes":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-- -l", cmlBareTwoDashes)
    check testCmdlineMessage(options, "-l --", cmlBareTwoDashes)

  test "bin/cmdline cmlInvalidShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-p -l -t", cmlInvalidShortOption, "p")
    check testCmdlineMessage(options, "-l -p -t", cmlInvalidShortOption, "p")
    check testCmdlineMessage(options, "-l -t -p", cmlInvalidShortOption, "t")

  test "bin/cmdline cmlInvalidOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("optional", 't', cmlOptionalParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--tea -l -t", cmlInvalidOption, "tea")
    check testCmdlineMessage(options, "-t --tea -l", cmlInvalidOption, "tea")
    check testCmdlineMessage(options, "-t -l --tea", cmlInvalidOption, "tea")

  test "bin/cmdline cmlMissingRequiredParameter":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("required", 'r', cmlParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--required -l", cmlMissingParameter, "required")
    check testCmdlineMessage(options, "--required --log", cmlMissingParameter, "required")
    check testCmdlineMessage(options, "--log --required", cmlMissingParameter, "required")

  test "bin/cmdline cmlBareOneDash":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log -", cmlBareOneDash)
    check testCmdlineMessage(options, "- --log", cmlBareOneDash)

  test "bin/cmdline cmlInvalidShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log -z", cmlInvalidShortOption, "z")
    check testCmdlineMessage(options, "-z --log", cmlInvalidShortOption, "z")

  test "bin/cmdline cmlShortParamInList":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("tea", 't', cmlNoParameter))
    options.add(newCmlOption("zoo", 'z', cmlParameter))
    check testCmdlineMessage(options, "-ltz", cmlShortParamInList, "z")
    check testCmdlineMessage(options, "-zlt", cmlShortParamInList, "z")

  test "bin/cmdline cmlDupShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("leg", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-ltz", cmlDupShortOption, "l")

  test "bin/cmdline cmlDupLongOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", 'l', cmlNoParameter))
    options.add(newCmlOption("tea", 'g', cmlNoParameter))
    check testCmdlineMessage(options, "-l", cmlDupLongOption, "tea")

  test "bin/cmdline cmlBareShortName":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", 't', cmlBareParameter))
    check testCmdlineMessage(options, "-b", cmlBareShortName, "t")

  test "bin/cmdline cmlAlphaNumericShort":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '*', cmlParameter))
    check testCmdlineMessage(options, "-l", cmlAlphaNumericShort, "*")

  test "bin/cmdline cmlMissingBareParameter":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '_', cmlBareParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-l", cmlMissingBareParameter, "tea")

  test "bin/cmdline cmlMissingBareParameters":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '_', cmlBareParameter))
    options.add(newCmlOption("tea2", '_', cmlBareParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("help", 'h', cmlNoParameter))

    check testCmdlineMessage(options, "-l -h", cmlMissingBareParameter, "tea")
    check testCmdlineMessage(options, "-lh -l", cmlMissingBareParameter, "tea")
    check testCmdlineMessage(options, "--log --help", cmlMissingBareParameter, "tea")

    check testCmdlineMessage(options, "-l bare", cmlMissingBareParameter, "tea2")
    check testCmdlineMessage(options, "-lh bare", cmlMissingBareParameter, "tea2")
    check testCmdlineMessage(options, "bare --help", cmlMissingBareParameter, "tea2")

  test "bin/cmdline log with filename":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log statictea.log", cmlTooManyBareParameters)
