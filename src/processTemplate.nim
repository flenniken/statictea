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
import streams
import os

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
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      yield(content[start .. pos])
      start = pos+1
  if start < content.len:
    yield(content[start ..< content.len])

proc processTemplateLines(env: var Env, variables: var Variables,
                          compiledMatchers: CompiledMatchers) =
  ## Process the given template file.

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

    # If repeat is 0, read the replacement lines and the endblock and discard them.
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
      # Discard the replacement block lines and the endblock.
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        discard
      # Use the content as the replacement lines.
      var content = getVariable(variables, "t.", "content").get().stringv
      for line in yieldContentLine(content):
        storeLineSegments(env, tempSegments, compiledMatchers, line)
    else:
      # Read the replacement lines and store their compiled segments in
      # TempSegments.  Ignore the last line, the endblock, if it exists.
      var previousLine = ""
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        if previousLine != "":
          storeLineSegments(env, tempSegments, compiledMatchers, previousLine)
        previousLine = line

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

proc updateTemplateLines(env: var Env, variables: var Variables,
                          compiledMatchers: CompiledMatchers) =
  ## Update the given template file.

  #[ Read template lines and write them out. Read command lines and
  write them out. Run the command to determine the t.content, then
  write out the t.content. Repeat.

  If the template is coming from a file, write the content to a temp
  file then rename it at the end overwriting the original template
  file.  If the template comes from standard in, write the new
  template to standard out. ]#

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

    # Run the replace commands but not the others.
    let command = cmdLineParts[0].command
    if command == "replace":
      # Run the command and fill in the variables.
      var row = 0
      variables["row"] = newValue(row)
      runCommand(env, cmdLines, cmdLineParts, compiledMatchers,
                 variables)

    # Write out the command lines.
    dumpCmdLines(env.resultStream, cmdLines, cmdLineParts, "")

    # Show a warning when the replace command does not have t.content set.
    if command == "replace" and not variables.contains("content"):
      env.warn(lb.lineNum, wContentNotSet)

    if command == "replace" and variables.contains("content"):
      # Discard the replacement block lines and save the endblock if it exists.
      var endblock = ""
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        endblock = line

      # Write the content as the replacement lines.
      var content = getVariable(variables, "t.", "content").get().stringv
      for line in yieldContentLine(content):
        env.resultStream.write(line)

      # If the content does not end with a newline, add one and output
      # a warning.
      if content.len > 0 and content[^1] != '\n':
        env.warn(lb.lineNum, wMissingNewLineContent)
        env.resultStream.write('\n')

      # Write out the endblock, if it exists.
      if endblock != "":
        env.resultStream.write(endblock)
    else:
      # Read the replacement lines and endblock and write them out.
      for line in yieldReplacementLine(env, variables, command, lb, compiledMatchers):
        env.resultStream.write(line)

proc getStartingVariables(env: var Env, args: Args): Variables =
  ## Read and return the server and shared variables and setup the
  ## initial tea variables.

  # The tea variables are the top level items.  All variables are tea
  # variables in the sense that they all exists somewhere in this
  # dictionary.
  var server = readServerVariables(env, args)
  var shared = readSharedVariables(env, args)
  result = newVariables(server, shared)

proc getCompiledMatchers(args: Args): CompiledMatchers =
  ## Get the compile matchers dependent on the prepost settings from
  ## the user.

  # Get the prepost table, either the user specified one or the
  # default one. The defaults are not used when the user specifies
  # them, so that they have complete control over the preposts used.
  var prepostTable: PrepostTable
  if args.prepostList.len > 0:
    # The prepostList has been validated already.
    prepostTable = getUserPrepostTable(args.prepostList)
  else:
    prepostTable = getDefaultPrepostTable()

  # Get all the compiled regular expression matchers.
  result = getCompiledMatchers(prepostTable)

proc processTemplate*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var compiledMatchers = getCompiledMatchers(args)

  # Process the template.
  processTemplateLines(env, variables, compiledMatchers)

  if env.warningWritten > 0:
    result = 1

proc updateTemplate*(env: var Env, args: Args): int =
  ## Update the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var compiledMatchers = getCompiledMatchers(args)

  # Process the template.
  updateTemplateLines(env, variables, compiledMatchers)

  if env.warningWritten > 0:
    result = 1

proc processTemplateTop*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. This calls
  ## processTemplate.

  # Add the template and result streams to the environment.
  if not env.addExtraStreams(args):
    return 1

  # Process the template.
  result = processTemplate(env, args)

proc updateTemplateTop*(env: var Env, args: Args): int =
  ## Update the template and return 0 on success. This calls
  ## updateTemplate.

  # Add the template and result streams to the environment. Result
  # file is either a temp file or standard out.
  if not env.addExtraStreamsForUpdate(args):
    return 1

  # Update the template.
  result = updateTemplate(env, args)

  # When the template is coming from a file, update it from the temp
  # file.
  if env.templateFilename != "":

    # Close the template and result files.
    env.templateStream.close()
    env.templateStream = nil
    env.resultStream.close()
    env.resultStream = nil

    # Rename the temp file overwriting the template file.
    try:
      moveFile(env.resultFilename, env.templateFilename)
    except OSError:
      env.warn(0, wUnableToRenameTemp)
      # Delete the temp file.
      discard tryRemoveFile(env.resultFilename)
      result = 1
