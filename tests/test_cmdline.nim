import std/unittest
import cmdline

suite "cmdline.nim":

  test "test me":
    check 1 == 1

  test "newClOption":
    check $newClOption("help", 'h', clNoParameter) == "option: help, h, clNoParameter"
    check $newClOption("log", 'l', clParameter) == "option: log, l, clParameter"
    check $newClOption("param", 'p', clOptionalParameter) == "option: param, p, clOptionalParameter"

  test "cmdLine":
    var options = newSeq[ClOption]()
    let parameters = newSeq[string]()
    let args = cmdLine(options, parameters)
    check $args == "no arguments"

  test "cmdLine":
    var options = newSeq[ClOption]()
    let parameters = newSeq[string]()
    let args = cmdLine(options, parameters)
    check $args == "no arguments"

  test "bin/cmdline --help":
    let parameters = @["--help"]
    var options = newSeq[ClOption]()
    options.add(newClOption("help", 'h', clNoParameter))
    let args = cmdLine(options, parameters)
    check $args == """
args:
help: @[]
"""

  test "bin/cmdline -h":
    let parameters = @["-h"]
    var options = newSeq[ClOption]()
    options.add(newClOption("help", 'h', clNoParameter))
    let args = cmdLine(options, parameters)
    check $args == """
args:
help: @[]
"""

  test "bin/cmdline --help --log":
    let parameterSets = [
      ["--help", "--log"],
      ["-h", "-l"],
      ["--help", "-l"],
      ["-h", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("help", 'h', clNoParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
help: @[]
log: @[]
"""

  test "bin/cmdline --server server.json":
    let parameterSets = [
      ["--server", "server.json"],
      ["-s", "server.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("server", 's', clParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
server: @["server.json"]
"""

  test "bin/cmdline --server server.json --shared shared.json":
    let parameterSets = [
      ["--server", "server.json", "--shared", "shared.json"],
      ["-s", "server.json", "-j", "shared.json"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("server", 's', clParameter))
      options.add(newClOption("shared", 'j', clParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
server: @["server.json"]
shared: @["shared.json"]
"""

  test "bin/cmdline --server server.json --server second.json":
    let parameters = @[
      "--server", "server.json",
      "--server", "second.json",
    ]
    var options = newSeq[ClOption]()
    options.add(newClOption("server", 's', clParameter))
    let args = cmdLine(options, parameters)
    check $args == """
args:
server: @["server.json", "second.json"]
"""

  test "bin/cmdline tea.svg":
    let parameterSets = [
      ["tea.svg"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("filename", '_', clBareParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
filename: @["tea.svg"]
"""

  test "bin/cmdline tea.svg tea.svg.save":
    let parameterSets = [
      ["tea.svg", "tea.svg.save"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("source", '_', clBareParameter))
      options.add(newClOption("destination", '_', clBareParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
source: @["tea.svg"]
destination: @["tea.svg.save"]
"""

  # Test optional parameter.

  test "bin/cmdline -t":
    let parameterSets = [
      ["-t"],
      ["--optional"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("optional", 't', clOptionalParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
optional: @[]
"""

  test "bin/cmdline -t -l":
    let parameterSets = [
      ["-t", "-l"],
      ["--optional", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("optional", 't', clOptionalParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
optional: @[]
log: @[]
"""

  test "bin/cmdline tea.svg -t -l":
    let parameterSets = [
      ["tea.svg", "-t", "-l"],
      ["tea.svg", "--optional", "--log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("filename", '_', clBareParameter))
      options.add(newClOption("optional", 't', clOptionalParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
filename: @["tea.svg"]
optional: @[]
log: @[]
"""

  test "bin/cmdline -lt":
    let parameterSets = [
      ["-lt"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("optional", 't', clOptionalParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
log: @[]
optional: @[]
"""

  test "bin/cmdline clmBareTwoDashes":
    let parameterSets = [
      ["--", "-l", "-t"],
      ["-t", "-l", "--"],
      ["-t", "--", "-l"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("optional", 't', clOptionalParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmBareTwoDashes"

  test "bin/cmdline clmInvalidShortOption":
    let parameterSets = [
      ["-p", "-l", "-t"],
      ["-t", "-l", "-p"],
      ["-t", "-p", "-l"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("optional", 't', clOptionalParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmInvalidShortOption for p."

  test "bin/cmdline clmInvalidOption":
    let parameterSets = [
      ["--tea", "-l", "-t"],
      ["-t", "-l", "--tea"],
      ["-t", "--tea", "-l"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("optional", 't', clOptionalParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmInvalidOption for tea."

  test "bin/cmdline clmMissingRequiredParameter":
    let parameterSets = [
      ["--required", "-l"],
      ["--required", "--log"],
      ["--log", "--required"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("required", 'r', clParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmMissingRequiredParameter for required."

  test "bin/cmdline clmBareOneDash":
    let parameterSets = [
      ["--log", "-"],
      ["-", "-l"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmBareOneDash"

  test "bin/cmdline clmInvalidShortOption":
    let parameterSets = [
      ["--log", "-z"],
      ["-z", "-l"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmInvalidShortOption for z."

  test "bin/cmdline clmShortParamInList":
    let parameterSets = [
      ["-ltz"],
      ["-zlt"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("log", 'l', clNoParameter))
      options.add(newClOption("tea", 't', clNoParameter))
      options.add(newClOption("zoo", 'z', clParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmShortParamInList for z."

  test "bin/cmdline clmDupShortOption":
    let parameterSets = [
      ["-ltz"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("log", 'l', clNoParameter))
      options.add(newClOption("leg", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmDupShortOption for l."

  test "bin/cmdline clmDupLongOption":
    let parameterSets = [
      ["-ltz"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("tea", 'l', clNoParameter))
      options.add(newClOption("tea", 'g', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmDupLongOption for tea."

  test "bin/cmdline clmBareShortName":
    let parameterSets = [
      ["-ltz"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("tea", 't', clBareParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmBareShortName for t."

  test "bin/cmdline clmAlphaNumericShort":
    let parameterSets = [
      ["-ltz"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("tea", '*', clParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmAlphaNumericShort for *."

  test "bin/cmdline clmMissingBareParameter":
    let parameterSets = [
      ["-l"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("tea", '_', clBareParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmMissingBareParameter"

  test "bin/cmdline clmMissingBareParameters":
    let parameterSets = [
      ["-l", "-h"],
      ["-l", "baretea"],
      ["baretea", "-h"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("tea", '_', clBareParameter))
      options.add(newClOption("tea2", '_', clBareParameter))
      options.add(newClOption("log", 'l', clNoParameter))
      options.add(newClOption("help", 'h', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmMissingBareParameter"

  test "bin/cmdline log with filename":
    let parameterSets = [
      ["--log", "statictea.log"],
    ]
    for parameters in parameterSets:
      var options = newSeq[ClOption]()
      options.add(newClOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == "message: clmTooManyBareParameters"
