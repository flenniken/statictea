## Process the template.

import args
import warnings
import env
import matches
import readlines
import options
import parseCmdLine
import collectCommand
import runCommand
import variables
import vartypes
import tables
import replacement

#[

<--$ nextline -->\n
<--$ nextline \-->\n
<--$ nextline a = 5 \-->\n
<--$ nextline a = 5; b = \-->\n
<--$ : 20 \-->\n

Each line has a command. The current line continues when it has a
slash at the end. The continue line starts with a : command.  It may
continue too. The last line doesn't have a slash. If an error is
found, a warning is written, and the lines get written as is, as if
they weren't command lines.

<!--$ nextline a = 5 \-->\n
<!--$ : a = 5 \-->\n
<!--$ : b = 6 \-->\n
<!--$ : c = 7  -->\n

There are three line types: cmd lines, replacement block lines and
other lines.

Cmd lines start with a prefix, and they may continue on multiple
lines.

Replacement block lines follow cmd lines. One line for the nextline
command and one or more lines for replace and block commands.

Other lines, not cmd or block lines, get echoed to the output file
unchanged.

]#


iterator yieldContentLine*(content: string): string =
  ## Yield one content line at a time and keep the line endings.
  var start = 0
  var pos: int
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      yield(content[start .. pos])
      start = pos+1
  if start < content.len:
    yield(content[start ..< content.len])

proc processTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Process the given template file.

  # Get all the compiled regular expression matchers.
  let compiledMatchers = getCompiledMatchers(prepostTable)

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(env.templateStream,
      filename = env.templateFilename)
  if not lineBufferO.isSome():
    env.warn(0, wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  # Read and process template lines.
  while true:
    # Read template lines and write out non-command lines. When a
    # command is found, collect its lines and return them.
    var cmdLines: seq[string] = @[]
    var cmdLineParts: seq[LineParts] = @[]
    collectCommand(env, lb, compiledMatchers, env.resultStream,
                   cmdLines, cmdLineParts)
    if cmdLines.len == 0:
      break # done, no more lines

    # Run the commands that have statements and skip the others.
    let command = cmdLineParts[0].command
    if not (command in ["nextline", "block", "replace"]):
      # todo: show error when we get endblock before block?
      # todo: make it an error when other commands have statements.
      continue

    # Run the command and fill in the variables.
    var row = 0
    variables["row"] = newValue(row)
    runCommand(env, cmdLines, cmdLineParts, compiledMatchers,
               variables)
    let repeat = getTeaVarInt(variables, "repeat")

    # Show a warning when the replace command does not have t.content set.
    if command == "replace" and not variables.contains("content"):
      env.warn(lb.lineNum, wContentNotSet)

    # If repeat is 0, read the replacement lines and discard them.
    if repeat == 0:
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        discard
      continue

    # Create a new TempSegments object for storing segments.
    var startLineNum = lb.lineNum + 1
    var tempSegmentsO = newTempSegments(env, lb, compiledMatchers, command, repeat, variables)
    if not isSome(tempSegmentsO):
      break # Cannot create temp file or allocate memory, quit.
    var tempSegments = tempSegmentsO.get()

    if command == "replace" and variables.contains("content"):
      # Discard the replacement block lines.
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        discard
      # Use the content as the replacement lines.
      var content = getVariable(variables, "t.", "content").get().stringv
      for line in yieldContentLine(content):
        storeLineSegments(env, tempSegments, compiledMatchers, line)
    else:
      # Read the replacement lines and store their compiled segments in
      # TempSegments.
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        storeLineSegments(env, tempSegments, compiledMatchers, line)

    # Generate t.repeat number of replacement blocks. Recalculate the
    # variables for each one.
    while true:
      # Write out all the stored replacement block lines and make the
      # variable substitutions.
      writeTempSegments(env, tempSegments, startLineNum, variables)

      # Increment the row variable.
      inc(row)
      if row >= repeat:
        break
      variables["row"] = newValue(row)

      # Run the command and fill in the variables.
      runCommand(env, cmdLines, cmdLineParts, compiledMatchers,
                 variables)

    closeDelete(tempSegments)

proc processTemplate*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. It's an error when
  ## a warning messages was written.

  # The tea variables are the top level items.  All variables are tea
  # variables in the sense that they all exists somewhere in this
  # dictionary.
  var server = readServerVariables(env, args)
  var shared = readSharedVariables(env, args)
  var variables = newVariables(server, shared)

  # Get the prepost table, either the user specified one or the
  # default one. The defaults are not used when the user specifies
  # them, so that they have complete control over the preposts used.
  var prepostTable: PrepostTable
  if args.prepostList.len > 0:
    # The prepostList has been validated already.
    prepostTable = getUserPrepostTable(args.prepostList)
  else:
    prepostTable = getDefaultPrepostTable()

  # Process the template.
  processTemplateLines(env, variables, prepostTable)

  if env.warningWritten > 0:
    result = 1

proc processTemplateTop*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. It's an error when
  ## a warning messages was written.

  # Add the template and result streams to the environment.
  if not env.addExtraStreams(args):
    return 1

  # Process the template.
  result = processTemplate(env, args)
