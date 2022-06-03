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
  let argsOrMessage = cmdline(options, parameters)
  if argsOrMessage.kind != cmlMessageKind:
    echo "The line did not generate a message."
    echo "got:"
    echo $argsOrMessage
    return false
  result = true
  if argsOrMessage.messageId != eMessageId:
    echo "Did not get the expected message id:"
    echo "expected: $1" % $eMessageId
    echo "     got: $1" % $argsOrMessage.messageid
    result = false

  if argsOrMessage.problemParam != eProblemParam:
    echo "Did not get the expected problem parameter:"
    echo "expected: $1" % eProblemParam
    echo "     got: $1" % argsOrMessage.problemParam
    result = false

  # if result:
  #   echo getMessage(argsOrMessage.messageid, argsOrMessage.problemParam)

suite "cmdline.nim":

  test "test me":
    check 1 == 1

  test "messages":
    check getMessage(cml_00_BareTwoDashes) ==
      "Two dashes must be followed by an option name."

  test "newCmlOption":
    check $newCmlOption("help", 'h', cmlNoParameter) ==
      "option: long=help, short=h, optionType=cmlNoParameter"

    check $newCmlOption("log", 'l', cmlParameter0or1) ==
      "option: long=log, short=l, optionType=cmlParameter0or1"

    check $newCmlOption("param", 'p', cmlOptionalParameter) ==
      "option: long=param, short=p, optionType=cmlOptionalParameter"

    check $newCmlOption("param", '_', cmlBareParameter) ==
      "option: long=param, short=_, optionType=cmlBareParameter"

    check $newCmlOption("once", 'o', cmlParameterOnce) ==
      "option: long=once, short=o, optionType=cmlParameterOnce"

    check $newCmlOption("many", 'm', cmlParameterMany) ==
      "option: long=many, short=m, optionType=cmlParameterMany"

  test "cmdLine no parameters":
    var options = newSeq[CmlOption]()
    let parameters = newSeq[string]()
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgsKind
    check argsOrMessage.args.len == 0

  test "--help":
    let parameters = @["--help"]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlNoParameter))
    let argsOrMessage = cmdLine(options, parameters)
    check argsOrMessage.kind == cmlArgsKind
    check argsOrMessage.args.len == 1
    check argsOrMessage.args["help"].len == 0

  test "-h":
    let parameters = @["-h"]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlNoParameter))
    let argsOrMessage = cmdLine(options, parameters)

    var eCmlArgs: CmlArgs
    eCmlArgs["help"] = newSeq[string]()
    check compareArgs(argsOrMessage, eCmlArgs)

  test "--help --log":
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

  test "--server server.json":
    let parameterSets = [
      ["--server", "server.json"],
      ["-s", "server.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("server", 's', cmlParameterMany))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["server"] = @["server.json"]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "--server server.json --shared shared.json":
    let parameterSets = [
      ["--server", "server.json", "--shared", "shared.json"],
      ["-s", "server.json", "-j", "shared.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("server", 's', cmlParameterMany))
      options.add(newCmlOption("shared", 'j', cmlParameterMany))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["server"] = @["server.json"]
      eCmlArgs["shared"] = @["shared.json"]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "--server server.json --server second.json":
    let parameters = @[
      "--server", "server.json",
      "--server", "second.json",
    ]
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("server", 's', cmlParameterMany))
    let argsOrMessage = cmdLine(options, parameters)

    var eCmlArgs: CmlArgs
    eCmlArgs["server"] = @["server.json", "second.json"]
    check compareArgs(argsOrMessage, eCmlArgs)

  test "once":
    let parameterSets = [
      ["--help", "me"],
      ["-h", "me"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("help", 'h', cmlParameterOnce))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["help"] = @["me"]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "tea.svg":
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

  test "tea.svg tea.svg.save":
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

  test "-t":
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

  test "-t -l":
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

  test "tea.svg -t -l":
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

  test "-lt":
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

  test "stop parameters":
    let parameterSets = [
      ["--help", "asdf"],
      ["-h", "asdf"],
      ["-v", "-h"],
      ["-h", "-v"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("help", 'h', cmlStopParameter))
      options.add(newCmlOption("version", 'v', cmlNoParameter))
      options.add(newCmlOption("required", '_', cmlBareParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["help"] = @[]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "no short option":
    let parameterSets = [
      ["--noshort"],
    ]
    for parameters in parameterSets:
      var options = newSeq[CmlOption]()
      options.add(newCmlOption("noshort", '_', cmlNoParameter))
      let argsOrMessage = cmdLine(options, parameters)

      var eCmlArgs: CmlArgs
      eCmlArgs["noshort"] = @[]
      check compareArgs(argsOrMessage, eCmlArgs)

  test "dup optional options":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlOptionalParameter))
    # It is ok to have duplicate options that don't have parameters.
    # check testCmdlineMessage(options, "-l -l",
    # check testCmdlineMessage(options, "-l --log",
    check testCmdlineMessage(options, "-l abc --log def",
      cml_12_AlreadyHaveOneArg, "log")

  test "cml_00_BareTwoDashes":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-- -l", cml_00_BareTwoDashes)
    check testCmdlineMessage(options, "-l --", cml_00_BareTwoDashes)

  test "cml_04_InvalidShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-p -l -t", cml_04_InvalidShortOption, "p")
    check testCmdlineMessage(options, "-l -p -t", cml_04_InvalidShortOption, "p")
    check testCmdlineMessage(options, "-l -t -p", cml_04_InvalidShortOption, "t")

  test "cml_01_InvalidOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("optional", 't', cmlOptionalParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--tea -l -t", cml_01_InvalidOption, "tea")
    check testCmdlineMessage(options, "-t --tea -l", cml_01_InvalidOption, "tea")
    check testCmdlineMessage(options, "-t -l --tea", cml_01_InvalidOption, "tea")

  test "cml_02_OptionRequiresArg":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("many", 'm', cmlParameterMany))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("once", 'o', cmlParameterOnce))

    check testCmdlineMessage(options, "--many -l", cml_02_OptionRequiresArg, "many")
    check testCmdlineMessage(options, "--many --log", cml_02_OptionRequiresArg,
      "many")
    check testCmdlineMessage(options, "--log --many", cml_02_OptionRequiresArg,
      "many")
    check testCmdlineMessage(options, "--many a", cml_02_OptionRequiresArg,
      "once")

  test "cml_03_BareOneDash":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log -", cml_03_BareOneDash)
    check testCmdlineMessage(options, "- --log", cml_03_BareOneDash)

  test "cml_04_InvalidShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log -z", cml_04_InvalidShortOption, "z")
    check testCmdlineMessage(options, "-z --log", cml_04_InvalidShortOption, "z")

  test "cml_05_ShortParamInList":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("tea", 't', cmlNoParameter))
    options.add(newCmlOption("zoo", 'z', cmlParameterMany))
    check testCmdlineMessage(options, "-ltz", cml_05_ShortParamInList, "z")
    check testCmdlineMessage(options, "-zlt", cml_05_ShortParamInList, "z")

  test "cml_06_DupShortOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("leg", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-ltz", cml_06_DupShortOption, "l")

  test "cml_07_DupLongOption":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", 'l', cmlNoParameter))
    options.add(newCmlOption("tea", 'g', cmlNoParameter))
    check testCmdlineMessage(options, "-l", cml_07_DupLongOption, "tea")

  test "cml_08_BareShortName":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", 't', cmlBareParameter))
    check testCmdlineMessage(options, "-b", cml_08_BareShortName, "t")

  test "cml_09_AlphaNumericShort":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '*', cmlParameterMany))
    check testCmdlineMessage(options, "-l", cml_09_AlphaNumericShort, "*")

  test "cml_10_MissingArgument":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '_', cmlBareParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "-l", cml_10_MissingArgument, "tea")

  test "cml_10_MissingArguments":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("tea", '_', cmlBareParameter))
    options.add(newCmlOption("tea2", '_', cmlBareParameter))
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    options.add(newCmlOption("help", 'h', cmlNoParameter))

    check testCmdlineMessage(options, "-l -h", cml_10_MissingArgument, "tea")
    check testCmdlineMessage(options, "-lh -l", cml_10_MissingArgument, "tea")
    check testCmdlineMessage(options, "--log --help", cml_10_MissingArgument, "tea")

    check testCmdlineMessage(options, "-l bare", cml_10_MissingArgument, "tea2")
    check testCmdlineMessage(options, "-lh bare", cml_10_MissingArgument, "tea2")
    check testCmdlineMessage(options, "bare --help", cml_10_MissingArgument, "tea2")

  test "cml_11_TooManyBareArgs":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlNoParameter))
    check testCmdlineMessage(options, "--log statictea.log", cml_11_TooManyBareArgs)

  test "cml_12_AlreadyHaveOneArg":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlParameterOnce))

    check testCmdlineMessage(options, "--log statictea.log --log hello",
      cml_12_AlreadyHaveOneArg, "log")
    check testCmdlineMessage(options, "-l statictea.log -l hello",
      cml_12_AlreadyHaveOneArg, "log")
    check testCmdlineMessage(options, "-l statictea.log --log hello",
      cml_12_AlreadyHaveOneArg, "log")
    check testCmdlineMessage(options, "--log statictea.log -l hello",
      cml_12_AlreadyHaveOneArg, "log")

  test "cml_12_AlreadyHaveOneArg 0 or 1":
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("log", 'l', cmlParameter0or1))

    check testCmdlineMessage(options, "--log statictea.log --log hello",
      cml_12_AlreadyHaveOneArg, "log")
    check testCmdlineMessage(options, "-l statictea.log -l hello",
      cml_12_AlreadyHaveOneArg, "log")

  test "CmlMessageId":
    check ord(low(CmlMessageId)) == 0
    if ord(high(CmlMessageId)) > 14:
      echo "time to update this test."
      check false == true

    let expected = @ [
      cml_00_BareTwoDashes,
      cml_01_InvalidOption,
      cml_02_OptionRequiresArg,
      cml_03_BareOneDash,
      cml_04_InvalidShortOption,
      cml_05_ShortParamInList,
      cml_06_DupShortOption,
      cml_07_DupLongOption,
      cml_08_BareShortName,
      cml_09_AlphaNumericShort,
      cml_10_MissingArgument,
      cml_11_TooManyBareArgs,
      cml_12_AlreadyHaveOneArg,
    ]

    var ix = 0
    for messageId in CmlMessageId:
      # echo "$1 $2" % [$ord(messageId), $messageId]
      check messageId == expected[ix]
      inc(ix)
      if messageId == expected[expected.len - 1]:
        break

  test "ArgsOrMessage string repr warning":
    let expected = """
argsOrMessage.messageId = cml_07_DupLongOption
argsOrMessage.problemParam = 'test'"""
    let argsOrMessage = newArgsOrMessage(cml_07_DupLongOption, "test")
    check $argsOrMessage == expected

  test "ArgsOrMessage no args":
    let expected = "no arguments"
    var args: CmlArgs
    let argsOrMessage = newArgsOrMessage(args)
    check $argsOrMessage == expected

  test "ArgsOrMessage args":
    let expected = """argsOrMessage.args[test] = ["me"]"""
    var args: CmlArgs
    args["test"] = @["me"]
    let argsOrMessage = newArgsOrMessage(args)
    check $argsOrMessage == expected

  test "ArgsOrMessage multiple args":
    let expected = """
argsOrMessage.args[test] = ["me"]
argsOrMessage.args[save] = ["flower.jpg", "tea.png"]"""
    var args: CmlArgs
    args["test"] = @["me"]
    args["save"] = @["flower.jpg", "tea.png"]
    let argsOrMessage = newArgsOrMessage(args)
    check $argsOrMessage == expected
