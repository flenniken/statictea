import std/unittest
import cmdline

suite "cmdline.nim":

  test "test me":
    check 1 == 1

  test "newOption":
    check $newOption("help", 'h', clNoParameter) == "option: help, h, clNoParameter"
    check $newOption("log", 'l', clParameter) == "option: log, l, clParameter"
    check $newOption("param", 'p', clOptionalParameter) == "option: param, p, clOptionalParameter"

  test "cmdLine":
    var options = newSeq[Option]()
    let parameters = newSeq[string]()
    let args = cmdLine(options, parameters)
    check $args == "no arguments"

  test "cmdLine":
    var options = newSeq[Option]()
    let parameters = newSeq[string]()
    let args = cmdLine(options, parameters)
    check $args == "no arguments"

  test "bin/cmdline --help":
    let parameters = @["--help"]
    var options = newSeq[Option]()
    options.add(newOption("help", 'h', clNoParameter))
    let args = cmdLine(options, parameters)
    check $args == """
args:
help: @[]
"""

  test "bin/cmdline -h":
    let parameters = @["-h"]
    var options = newSeq[Option]()
    options.add(newOption("help", 'h', clNoParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("help", 'h', clNoParameter))
      options.add(newOption("log", 'l', clNoParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("server", 's', clParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("server", 's', clParameter))
      options.add(newOption("shared", 'j', clParameter))
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
    var options = newSeq[Option]()
    options.add(newOption("server", 's', clParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("filename", '_', clBareParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("source", '_', clBareParameter))
      options.add(newOption("destination", '_', clBareParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("optional", 't', clOptionalParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("optional", 't', clOptionalParameter))
      options.add(newOption("log", 'l', clNoParameter))
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
      var options = newSeq[Option]()
      options.add(newOption("filename", '_', clBareParameter))
      options.add(newOption("optional", 't', clOptionalParameter))
      options.add(newOption("log", 'l', clNoParameter))
      let args = cmdLine(options, parameters)
      check $args == """
args:
filename: @["tea.svg"]
optional: @[]
log: @[]
"""

