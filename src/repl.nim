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

const
  wrapColumn = 60

type
  ReplCommand* = enum
    ## The REPL commands.
    ## @:* not_cmd -- not a REPL command
    ## @:* h_cmd -- display help
    ## @:* p_cmd -- print variable
    ## @:* pd_cmd -- print dictionary
    ## @:* pf_cmd -- print f or function
    ## @:* plc_cmd -- print list in columns
    ## @:* plv_cmd -- print list one per line
    ## @:* v_cmd -- print number of variables in the one letter dictionaries
    ## @:* q_cmd -- quit (or Ctrl-d)
    not_cmd
    h_cmd
    p_cmd
    pd_cmd
    pf_cmd
    plc_cmd
    plv_cmd
    v_cmd
    q_cmd

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
Enter statements or commands at the prompt.

Available commands:

* h — this help text
* p — print a variable like in a replacement block
* pd — print a dictionary as dot names
* pf - print function names, signatures or docs, e.g. f, f.cmp, f.cmp[0]
* plc - print a list in columns
* plv - print a list vertical, one element per line
* v — print the number of variables in the one letter dictionaries
* q — quit (ctrl-d too)"""

proc errorAndColumn(env: var Env, messageId: MessageId, line: string,
    runningPos: Natural, p1 = "") =
  env.writeErr(line)
  env.writeErr(startColumn(line, runningPos))
  env.writeErr(getWarning(messageId, p1))

# Available basic colors:
#
# fgBlack, fgRed, fgGreen
# fgYellow, fgBlue, fgMagenta
# fgCyan, fgWhite
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
  ## Generate a string of names in columns.  Width is the width of a
  ## row. The names are left justified and the columns are separated
  ## by 2 spaces.
  if names.len == 0:
    return
  let pad = 2
  let colWidths = getColumnWidths(names, width, pad)
  result = listColumns(names, width, pad, colWidths)

func stringToReplCommand*(str: string): ReplCommand =
  case str:
  of "h":
    result = h_cmd
  of "p":
    result = p_cmd
  of "pd":
    result = pd_cmd
  of "pf":
    result = pf_cmd
  of "plc":
    result = plc_cmd
  of "plv":
    result = plv_cmd
  of "v":
    result = vcmd
  of "q":
    result = q_cmd
  else:
    result = not_cmd

proc getMaxWidth(): Natural =
  ## Use the wrap column for the max unless the terminal width is less.
  result = terminalWidth()
  if result > wrapColumn:
    result = wrapColumn

proc handleReplLine*(env: var Env, variables: var Variables, line: string): bool =
  ## Handle the REPL line. Return true to end the loop.
  if emptyOrSpaces(line, 0):
    return false

  var runningPos = 0
  let replCmdO = matchReplCmd(line, runningPos)

  var replCmd = not_cmd
  if replCmdO.isSome:
    let cmd = stringToReplCommand(replCmdO.getGroup())
    runningPos += replCmdO.get().length
    # q, h, v commands must be on a line by themself. If not, they are
    # treated as a statement line.
    case cmd
    of q_cmd:
      if runningPos == line.len:
        return true
    of h_cmd:
      if runningPos == line.len:
        env.writeOut(replHelp())
        return false
    of v_cmd:
      if runningPos == line.len:
        env.writeOut(showVariables(variables))
        return false
    of not_cmd:
      discard
    of p_cmd, pd_cmd, pf_cmd, plc_cmd, plv_cmd:
      replCmd = cmd

  # If not a REPL command, run the statement, add to the variables,
  # then return.
  if replCmd == not_cmd:
    # Run the
    let statement = newStatement(line, 1)
    let loopControl = runStatementAssignVar(env, statement, variables,
      "repl.tea")
    if loopControl == lcStop:
      return true
    return false

  # Read the variable for the REPL command.
  var haveDotName = false
  var variableName: DotName
  var value: Value

  # Read as if the argument is a dot name.
  let variableNameOr = getDotName(line, runningPos)
  if variableNameOr.isValue and variableNameOr.value.kind == vnkNormal:
    haveDotName = true
    variableName = variableNameOr.value

    # Read the dot name's value.
    let valueOr = getVariable(variables, variableName.dotName, npLocal)
    if valueOr.isMessage:
      # The variable '$1' does not exist.", ## wVariableMissing
      errorAndColumn(env, wVariableMissing, line, runningPos, variableName.dotName)
      return
    value = valueOr.value

  if not haveDotName:
    # Not dotname variable.  Run the function to get its value.
    let statement = newStatement(line, 1)
    # echo "statement: " & $statement
    # echo "runningPos: " & $runningPos
    let vlOr = getValuePosSi(env, statement, runningPos, variables, topLevel = true)
    # echo "vlOr: " & $vlOr

    if vlOr.isMessage:
      errorAndColumn(env, vlOr.message.messageId, statement.text, vlOr.message.pos, vlOr.message.p1)
      return false

    # Check that there is not any unprocessed text following the value.
    if vlOr.value.pos != statement.text.len:
      # Check for a trailing comment.
      if statement.text[vlOr.value.pos] != '#':
        # Unused text at the end of the statement.
        errorAndColumn(env, wTextAfterValue, statement.text, vlOr.value.pos)
        return false

    value = vlOr.value.value

  case replCmd:
  of p_cmd:
    # Print a variable like in a replacement block.
    env.writeOut(valueToStringRB(value))

  of pd_cmd:
    # Print dictionary.
    if value.kind != vkDict:
      # The variable is not a dictionary.
      errorAndColumn(env, wNotDictVariable, line, runningPos)
    else:
      if haveDotName:
        env.writeOut(dotNameRep(value.dictv.dict, variableName.dotName))
      else:
        env.writeOut(dotNameRep(value.dictv.dict))

  of plc_cmd:
    if value.kind != vkList:
      # The variable is not a list.
      errorAndColumn(env, wNotListVariable, line, runningPos)
    else:
      # Print list in columns.
      var list: seq[string]
      for item in value.listv.list:
        list.add(valueToString(item))
      env.writeOut(listInColumns(list, getMaxWidth()))

  of plv_cmd:
    if value.kind != vkList:
      # The variable is not a list.
      errorAndColumn(env, wNotListVariable, line, runningPos)
    else:
      # Print list vertically, one item per line.
      for value in value.listv.list:
        env.writeOut(valueToString(value))

  of pf_cmd:
    # print function, f, f.cmp, f.cmp[0]
    if haveDotName and variableName.dotName == "f":
      # echo "terminal width = " & $width
      var list: seq[string]
      for key, value in variables["f"].dictv.dict.pairs():
        list.add(key)
      env.writeOut(listInColumns(list, getMaxWidth()))
    elif value.kind == vkList:
      for ix, funcVar in value.listv.list:
        if funcVar.kind != vkFunc:
          # The variable is not a function variable.
          errorAndColumn(env, wNotFuncVariable, line, runningPos)
          return false
        else:
          env.writeOut(fmt"{ix}:  {funcVar.funcv.signature}")
    elif value.kind == vkFunc:
      echoDocComment(value)
    else:
      # Specify f or a function variable.
      errorAndColumn(env, wSpecifyF, line, runningPos)

  of q_cmd, h_cmd, v_cmd, not_cmd:
    discard

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
