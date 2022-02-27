import std/unittest
import std/tables
import cmdline
import strutils

proc compareArgs(argsOrMessage: ArgsOrMessage, eCmlArgs: CmlArgs): bool =
  if argsOrMessage.kind == cmlMessageKind:
    echo "argsOrMessage contains a message."
    echo "got:"
    echo getMessage(argsOrMessage.messageId, argsOrMessage.problemParam)
    return false
  result = true
  let cmlArgs = argsOrMessage.args
  if cmlArgs.len != eCmlArgs.len:
    echo "The two CmlArgs have a different number of items:"
    echo "expected: $1" % $eCmlArgs.len
    echo "     got: $1" % $cmlArgs.len
    result = false

  for eKey, eValue in pairs(eCmlArgs):
    if not (eKey in cmlArgs):
      echo "expected: $1" % eKey
      echo "     got: nothing"
      result = false
      continue
    let value = cmlArgs[eKey]
    if value != eValue:
      echo "expected: $1 = $2" % [eKey, $eValue]
      echo "     got: $1 = $2" % [eKey, $value]
      result = false

proc testCmdlineMessage(options: seq[CmlOption], line: string,
    eMessageId: CmlMessageId, eProblemParam: string = ""): bool =
  let parameters = split(line)
  let args = cmdline(options, parameters)
  if args.kind != cmlMessageKind:
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
    check getMessage(cml_00_BareTwoDashes) ==
      "Two dashes must be followed by an option name."

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
    check argsOrMessage.kind == cmlArgsKind
    check argsOrMessage.args.len == 0

  test "cmdLine":
    var options = newSeq[CmlOption]()
    let parameters = newSeq[string]()
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgsKind
    check argsOrMessage.args.len == 0

  test "bin/cmdline --help":
    let parameters = @["--help"]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlNoParameter))
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgsKind
    check argsOrMessage.args.len == 1
    check argsOrMessage.args["help"].len == 0

  test "bin/cmdline -h":
    let parameters = @["-h"]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlNoParameter))
    let argsOrMessage = cmdLine(options, parameters)

    var eCmlArgs: CmlArgs
    eCmlArgs["help"] = newSeq[string]()
    check compareArgs(argsOrMessage, eCmlArgs)

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
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["help"] = newSeq[string]()
      eCmlArgs["log"] = newSeq[string]()
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline --server server.json":
    let parameterSets = [
      ["--server", "server.json"],
      ["-s", "server.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("server", 's', cmlParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["server"] = @["server.json"]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline --server server.json --shared shared.json":
    let parameterSets = [
      ["--server", "server.json", "--shared", "shared.json"],
      ["-s", "server.json", "-j", "shared.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("server", 's', cmlParameter))
      options.add(newCmlOption("shared", 'j', cmlParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["server"] = @["server.json"]
      eCmlArgs["shared"] = @["shared.json"]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline --server server.json --server second.json":
    let parameters = @[
      "--server", "server.json",
      "--server", "second.json",
    ]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("server", 's', cmlParameter))
    let argsOrMessage = cmdLine(options, parameters)

    var eCmlArgs: CmlArgs
    eCmlArgs["server"] = @["server.json", "second.json"]
    check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline tea.svg":
    let parameterSets = [
      ["tea.svg"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("filename", '_', cmlBareParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["filename"] = @["tea.svg"]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline tea.svg tea.svg.save":
    let parameterSets = [
      ["tea.svg", "tea.svg.save"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("source", '_', cmlBareParameter))
      options.add(newCmlOption("destination", '_', cmlBareParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["source"] = @["tea.svg"]
      eCmlArgs["destination"] = @["tea.svg.save"]
      check compareArgs(argsOrMessage, eCmlArgs)

  # Test optional parameter.

  test "bin/cmdline -t":
    let parameterSets = [
      ["-t"],
      ["--optional"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["optional"] = newSeq[string]()
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline -t -l":
    let parameterSets = [
      ["-t", "-l"],
      ["--optional", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      options.add(newCmlOption("log", 'l', cmlNoParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["optional"] = newSeq[string]()
      eCmlArgs["log"] = newSeq[string]()
      check compareArgs(argsOrMessage, eCmlArgs)

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
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["filename"] = @["tea.svg"]
      eCmlArgs["optional"] = newSeq[string]()
      eCmlArgs["log"] = newSeq[string]()
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline -lt":
    let parameterSets = [
      ["-lt"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("optional", 't', cmlOptionalParameter))
      options.add(newCmlOption("log", 'l', cmlNoParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["optional"] = newSeq[string]()
      eCmlArgs["log"] = newSeq[string]()
      check compareArgs(argsOrMessage, eCmlArgs)

  test "bin/cmdline cml_00_BareTwoDashes":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-- -l", cml_00_BareTwoDashes)
    check testCmdlineMessage(options, "-l --", cml_00_BareTwoDashes)

  test "bin/cmdline cml_04_InvalidShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-p -l -t", cml_04_InvalidShortOption, "p")
    check testCmdlineMessage(options, "-l -p -t", cml_04_InvalidShortOption, "p")
    check testCmdlineMessage(options, "-l -t -p", cml_04_InvalidShortOption, "t")

  test "bin/cmdline cml_01_InvalidOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("optional", 't', cmlOptionalParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--tea -l -t", cml_01_InvalidOption, "tea")
    check testCmdlineMessage(options, "-t --tea -l", cml_01_InvalidOption, "tea")
    check testCmdlineMessage(options, "-t -l --tea", cml_01_InvalidOption, "tea")

  test "bin/cmdline cml_02_MissingParameter":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("required", 'r', cmlParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--required -l", cml_02_MissingParameter, "required")
    check testCmdlineMessage(options, "--required --log", cml_02_MissingParameter,
      "required")
    check testCmdlineMessage(options, "--log --required", cml_02_MissingParameter,
      "required")

  test "bin/cmdline cml_03_BareOneDash":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log -", cml_03_BareOneDash)
    check testCmdlineMessage(options, "- --log", cml_03_BareOneDash)

  test "bin/cmdline cml_04_InvalidShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log -z", cml_04_InvalidShortOption, "z")
    check testCmdlineMessage(options, "-z --log", cml_04_InvalidShortOption, "z")

  test "bin/cmdline cml_05_ShortParamInList":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("tea", 't', cmlNoParameter))
    options.add(newCmlOption("zoo", 'z', cmlParameter))
    check testCmdlineMessage(options, "-ltz", cml_05_ShortParamInList, "z")
    check testCmdlineMessage(options, "-zlt", cml_05_ShortParamInList, "z")

  test "bin/cmdline cml_06_DupShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("leg", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-ltz", cml_06_DupShortOption, "l")

  test "bin/cmdline cml_07_DupLongOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", 'l', cmlNoParameter))
    options.add(newCmlOption("tea", 'g', cmlNoParameter))
    check testCmdlineMessage(options, "-l", cml_07_DupLongOption, "tea")

  test "bin/cmdline cml_08_BareShortName":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", 't', cmlBareParameter))
    check testCmdlineMessage(options, "-b", cml_08_BareShortName, "t")

  test "bin/cmdline cml_09_AlphaNumericShort":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '*', cmlParameter))
    check testCmdlineMessage(options, "-l", cml_09_AlphaNumericShort, "*")

  test "bin/cmdline cml_10_MissingBareParameter":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '_', cmlBareParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-l", cml_10_MissingBareParameter, "tea")

  test "bin/cmdline cml_10_MissingBareParameters":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '_', cmlBareParameter))
    options.add(newCmlOption("tea2", '_', cmlBareParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("help", 'h', cmlNoParameter))

    check testCmdlineMessage(options, "-l -h", cml_10_MissingBareParameter, "tea")
    check testCmdlineMessage(options, "-lh -l", cml_10_MissingBareParameter, "tea")
    check testCmdlineMessage(options, "--log --help", cml_10_MissingBareParameter, "tea")

    check testCmdlineMessage(options, "-l bare", cml_10_MissingBareParameter, "tea2")
    check testCmdlineMessage(options, "-lh bare", cml_10_MissingBareParameter, "tea2")
    check testCmdlineMessage(options, "bare --help", cml_10_MissingBareParameter, "tea2")

  test "bin/cmdline cml_11_TooManyBareParameters":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log statictea.log", cml_11_TooManyBareParameters)

  test "CmlMessageId":
    check ord(low(CmlMessageId)) == 0
    check ord(high(CmlMessageId)) == 11

    let expected = @ [
      cml_00_BareTwoDashes,
      cml_01_InvalidOption,
      cml_02_MissingParameter,
      cml_03_BareOneDash,
      cml_04_InvalidShortOption,
      cml_05_ShortParamInList,
      cml_06_DupShortOption,
      cml_07_DupLongOption,
      cml_08_BareShortName,
      cml_09_AlphaNumericShort,
      cml_10_MissingBareParameter,
      cml_11_TooManyBareParameters,
    ]

    var ix = 0
    for messageId in CmlMessageId:
      # echo "$1 $2" % [$ord(messageId), $messageId]
      check messageId == expected[ix]
      inc(ix)
