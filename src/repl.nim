## Run commands at a prompt.
## Run evaluate print loop (REPL).

import std/rdstdin
import std/tables
import std/options
import std/strutils
import std/strformat
import std/terminal
import std/exitprocs
import messages
import env
import vartypes
import args
import opresult
import startingvars
import matches
import regexes
import runCommand
import variables
import unicodes
import parseMarkdown

func showVariables(variables: Variables): string =
  ## Show the number of variables in the one letter dictionaries.
  var first = true
  for key, d in variables.pairs():
    if not first:
      result.add(" ")
    first = false
    if d.dictv.dict.len == 0:
      result.add("$1={}" % key)
    else:
      result.add("$1={$2}" % [key, $d.dictv.dict.len])

proc replHelp(): string =
  result = """
You enter statements or commands at the prompt.

Available commands:
* h — this help text
* p dotname — print a variable as dot names
* ph dotname — print function's doc comment
* pj dotname — print a variable as json
* pr dotname — print a variable like in a replacement block
* v — show the number of top variables in the top level dictionaries
* q — quit"""

proc errorAndColumn(env: var Env, messageId: MessageId, line: string,
    runningPos: Natural, p1 = "") =
  env.writeErr(line)
  env.writeErr(startColumn(line, runningPos))
  env.writeErr(getWarning(messageId, p1))

# fgBlack
# fgRed
# fgGreen
# fgYellow
# fgBlue
# fgMagenta
# fgCyan
# fgWhite
# fgDefault -- default terminal foreground color

proc echoColorFragments(codeString: string, fragments: seq[Fragment]) =
  ## Write the fragment to standard out with the fragments colored.

  # Note: this code outputs to stdout directly instead of returning a
  # string with ansi codes so it works on Windows.

  for fragment in fragments:
    var color: ForegroundColor
    case fragment.fragmentType
    of hlOther, hlNumber, hlParamName, hlDotName:
      color = fgDefault
    of hlParamType, hlDocComment:
      color = fgRed
    of hlMultiline, hlStringType:
      color = fgGreen
    of hlFuncCall:
      color = fgBlue
    of hlComment:
      color = fgMagenta

    let msg = codeString[fragment.start .. fragment.fEnd-1]
    stdout.styledWrite(color, msg)

proc echoDocComment(funcVar: Value) =
  ## Write the doc comment to standard out with syntax highlighting.
  assert funcVar.kind == vkFunc
  let functionSpec = funcVar.funcv
  var elements = parseMarkdown(functionSpec.docComment)
  for element in elements:
    case element.tag
    of ElementTag.nothing:
      discard
    of p:
      stdout.write(element.content[0])
    of code:
      let codeString = element.content[1]
      let fragments = highlightCode(codeString)
      echoColorFragments(codeString, fragments)
    of bullets:
      for nl_string in element.content:
        stdout.write("* ")
        stdout.write(nl_string)

func getRows(numNames: Natural, columns: Natural): Natural =
  ## Determine the number of rows from the number of columns and the
  ## number of names.
  result = numNames div columns
  if numNames mod columns != 0:
    inc(result)

proc getColumnWidths(names: seq[string], width: Natural, pad: Natural): seq[Natural] =
  ## Return a list of the column widths to fit in the given width. The
  ## column widths do not include the pad, padding is between columns.

  # Find the widest item.
  var maxWidth = 0
  for name in names:
    if name.len > maxWidth:
      maxWidth = name.len

  # Determine the starting number of columns and their widths based on
  # the longest.
  var columns = width div (maxWidth + pad)

  if columns == 0:
    return @[width]

  var colWidths = newSeq[Natural]()
  var lastTotalWidth = 0

  while true:
    let rows = getRows(names.len, columns)

    # Determine the width of each column.
    var nextColWidths = newSeq[Natural](columns)
    for rowIx in countUp(0, rows-1):
      for colIx in countUp(0, columns-1):
        let ix =  colIx * rows + rowIx
        if ix < names.len:
          let nameWidth = names[ix].len
          if nameWidth > nextColWidths[colIx]:
            nextColWidths[colIx] = nameWidth

    var totalWidth = 0
    for w in nextColWidths:
      totalWidth += w

    if totalWidth <= lastTotalWidth or totalWidth > width:
      break

    colWidths = nextColWidths
    lastTotalWidth = totalWidth
    inc(columns)

  result = colWidths

proc listColumns(names: seq[string], width: Natural, pad: Natural, colWidths: seq[Natural]): string =
  ## Display the names as columns.

  # Handle one column.
  if colWidths.len <= 1:
    for ix, name in names:
      if ix != 0:
        result.add("\n")
      result.add(name)
    return

  # Generate spaces for use as padding.
  var spaces = newStringOfCap(width)
  for _ in countUp(0, width-1):
    spaces.add(" ")

  # Get the number of rows and columns.
  let rows = getRows(names.len, colWidths.len)
  let columns = colWidths.len

  # Display the names.
  for rowIx in countUp(0, rows-1):
    var row = ""
    for colIx in countUp(0, columns-1):
      let ix =  colIx * rows + rowIx
      if ix < names.len:
        let name = names[ix]
        row.add(name)
        let colWidth = colWidths[colIx]
        var padding = colWidth - name.len + pad
        assert(name.len <= colWidth)
        assert(padding >= pad)
        row.add(spaces[0 .. padding - 1])
    row = row.strip(trailing = true)
    if row != "":
      if rowIx != 0:
        result.add("\n")
      result.add(row)

proc listInColumns*(names: seq[string], width: Natural): string =
  ## Generate a string of the names in columns.  Width is the width of
  ## a row. The names are left justified and the columns are separated
  ## by 2 spaces.
  if names.len == 0:
    return
  let pad = 2
  let colWidths = getColumnWidths(names, width, pad)
  result = listColumns(names, width, pad, colWidths)

proc handleReplLine*(env: var Env, variables: var Variables, line: string): bool =
  ## Handle the REPL line. Return true to end the loop.
  if emptyOrSpaces(line, 0):
    return false

  var runningPos = 0
  let replCmdO = matchReplCmd(line, runningPos)
  if not replCmdO.isSome:

    # Run the statement and add to the variables.
    let statement = newStatement(line[runningPos .. ^1], 1)

    let loopControl = runStatementAssignVar(env, statement, variables,
      "repl.tea")
    if loopControl == lcStop:
      return true
    return false

  # We got a REPL command.

  let replCmd = replCmdO.getGroup()
  runningPos += replCmdO.get().length

  if replCmd in ["q", "h", "v"]:
    if runningPos != line.len:
      # Invalid REPL command syntax, unexpected text.
      errorAndColumn(env, wInvalidReplSyntax, line, runningPos)
      return false
    case replCmd
    of "q":
      return true
    of "h":
      env.writeOut(replHelp())
      return false
    of "v":
      env.writeOut(showVariables(variables))
      return false

  # Skip whitespace, if any.
  let spaceMatchO = matchTabSpace(line, runningPos)
  if isSome(spaceMatchO):
    runningPos += spaceMatchO.get().length

  # Read the variable for the command.
  var haveVarName = false
  var variableName: VariableName
  var value: Value
  let variableNameOr = getVariableName(line, runningPos)
  if variableNameOr.isValue and variableNameOr.value.kind == vnkNormal:
    haveVarName = true
    variableName = variableNameOr.value

    # Read the dot name's value.
    let valueOr = getVariable(variables, variableName.dotName, npLocal)
    if valueOr.isMessage:
      # The variable '$1' does not exist.", ## wVariableMissing
      errorAndColumn(env, wVariableMissing, line, runningPos, variableName.dotName)
      return
    value = valueOr.value

  if not haveVarName:
    # Get the right hand side value and match the following whitespace.
    let statement = newStatement(line, 1)
    # echo "statement: " & $statement
    # echo "runningPos: " & $runningPos
    let vlOr = getValuePosSi(env, statement, runningPos, variables, topLevel = true)
    # echo "vlOr: " & $vlOr

    if vlOr.isMessage:
      errorAndColumn(env, vlOr.message.messageId, statement.text, runningPos, vlOr.message.p1)
      return false

    # Check that there is not any unprocessed text following the value.
    if vlOr.value.pos != statement.text.len:
      # Check for a trailing comment.
      if statement.text[vlOr.value.pos] != '#':
        # Unused text at the end of the statement.
        errorAndColumn(env, wTextAfterValue, statement.text, vlOr.value.pos)
        return false

    value = vlOr.value.value

  # The print options mirror the string function.
  case replCmd:
  of "p": # string dn
    if value.kind == vkDict:
      env.writeOut(dotNameRep(value.dictv.dict))
    else:
      env.writeOut(valueToString(value))
  of "pj": # string json
    env.writeOut(valueToString(value))
  of "ph": # print doc comment
    if haveVarName and variableName.dotName == "f":
      var width = terminalWidth()
      if width > 60:
        width = 60
      # echo "terminal width = " & $width
      var list: seq[string]
      for key, value in variables["f"].dictv.dict.pairs():
        list.add(key)
      env.writeOut(listInColumns(list, width))


    elif value.kind == vkList:
      for ix, funcVar in value.listv.list:
        env.writeOut(fmt"{ix}:  {funcVar.funcv.signature}")
    elif value.kind == vkFunc:
      echoDocComment(value)
    else:
      # The variable is not a function variable.
      errorAndColumn(env, wNotFuncVariable, line, runningPos)
  of "pr": # string rb
    env.writeOut(valueToStringRB(value))
  else:
    discard
  result = false

proc runEvaluatePrintLoop*(env: var Env, args: Args) =
  ## Run commands at a prompt.
  # Register a exit proc to remove any terminal attributes.
  addExitProc(resetAttributes)

  var variables = getStartVariables(env, args)
  var line: string
  while true:
    try:
      line = readLineFromStdin("tea> ")
    except IOError:
      break
    let stop = handleReplLine(env, variables, line)
    if stop:
      break
