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
      # todo: show error when we get endblock before block.
      # todo: make it an error when other commands have statements?
      continue

    # Run the command and fill in the variables.
    var row = 0
    variables.tea["row"] = newValue(row)
    runCommand(env, cmdLines, cmdLineParts, compiledMatchers,
               variables)

    let repeat = getTeaVarInt(variables, "repeat")

    # Read the replacement block lines and return the compiled
    # replacement block.
    let replacementBlock = collectReplacementBlock(env, lb,
      compiledMatchers, command, repeat, variables)

    if repeat == 0:
      continue

    # Generate t.repeat number of replacement blocks. Recalculate the
    # variables for each one.
    while true:
      playReplacementBlock(env, variables, replacementBlock)

      inc(row)
      if row >= repeat:
        break

      # Run the command and fill in the variables.
      variables.tea["row"] = newValue(row)
      runCommand(env, cmdLines, cmdLineParts, compiledMatchers,
                 variables)


proc processTemplate*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. It's an error when
  ## a warning messages was written.

  var variables = readJsonVariables(env, args)

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
