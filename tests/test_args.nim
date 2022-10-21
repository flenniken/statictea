import std/unittest
import args
import compareLines

suite "args.nim":

  test "prepost":
    let prepost = newPrepost("abc", "def")
    check $prepost == "\"abc,def\""

  test "empty args":
    var args: Args
    let expected = """
args.help = false
args.version = false
args.update = false
args.log = false
args.repl = false
args.logFilename = ""
args.resultFilename = ""
args.serverList = []
args.codeList = []
args.templateFilename = ""
args.prepostList = []"""
    check testLinesSideBySide($args, expected)

  test "args string":
    var args: Args
    args.help = true
    args.serverList = @["one.json", "two.json"]
    args.resultFilename = "result.html"
    args.prepostList = @[newPrepost("#", "@"), newPrepost("begin", "end")]
    let expected = """
args.help = true
args.version = false
args.update = false
args.log = false
args.repl = false
args.logFilename = ""
args.resultFilename = "result.html"
args.serverList = ["one.json", "two.json"]
args.codeList = []
args.templateFilename = ""
args.prepostList = ["#,@", "begin,end"]"""
    check testLinesSideBySide($args, expected)

  test "args string2":
    var args: Args
    args.help = true
    args.serverList = @["server.json", "more.json"]
    args.codeList = @["shared.tea"]
    args.resultFilename = "result.html"
    let expected = """
args.help = true
args.version = false
args.update = false
args.log = false
args.repl = false
args.logFilename = ""
args.resultFilename = "result.html"
args.serverList = ["server.json", "more.json"]
args.codeList = ["shared.tea"]
args.templateFilename = ""
args.prepostList = []"""
    check testLinesSideBySide($args, expected)

  test "args logging no name":
    var args: Args
    args.help = true
    args.log = true
    args.serverList = @["server.json", "more.json"]
    args.codeList = @["shared.tea"]
    args.resultFilename = "result.html"
    let expected = """
args.help = true
args.version = false
args.update = false
args.log = true
args.repl = false
args.logFilename = ""
args.resultFilename = "result.html"
args.serverList = ["server.json", "more.json"]
args.codeList = ["shared.tea"]
args.templateFilename = ""
args.prepostList = []"""
    check testLinesSideBySide($args, expected)

  test "args logging with name":
    var args: Args
    args.help = true
    args.log = true
    args.serverList = @["server.json", "more.json"]
    args.codeList = @["shared.tea"]
    args.resultFilename = "result.html"
    args.logFilename = "statictea.log"
    let expected = """
args.help = true
args.version = false
args.update = false
args.log = true
args.repl = false
args.logFilename = "statictea.log"
args.resultFilename = "result.html"
args.serverList = ["server.json", "more.json"]
args.codeList = ["shared.tea"]
args.templateFilename = ""
args.prepostList = []"""
    check testLinesSideBySide($args, expected)

  test "args repl":
    var args: Args
    args.repl = true
    let expected = """
args.help = false
args.version = false
args.update = false
args.log = false
args.repl = true
args.logFilename = ""
args.resultFilename = ""
args.serverList = []
args.codeList = []
args.templateFilename = ""
args.prepostList = []"""
    check testLinesSideBySide($args, expected)


