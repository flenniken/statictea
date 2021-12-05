## Process the template.

import std/streams
import std/os
import std/options
import std/tables
import args
import messages
import env
import matches
import readlines
import parseCmdLine
import collectCommand
import runCommand
import variables
import vartypes
import readjson
# import replacement

proc fillReplacementBlock*(env: Env, lb: LineBuffer,
    command: string, variables: Variables,
    inOutExtraLine: var ExtraLine) =
  ## Fill in the replacement block and return the line after it.
  # dummy do nothing temp proc.

template getNewLineBuffer(env: Env): untyped =
  ## Get a new line buffer for the environment's template.
  ## When there is not enough memory for the line buffer, generate a
  ## warning and return.
  let lineBufferO = newLineBuffer(env.templateStream,
      filename = env.templateFilename)
  if not lineBufferO.isSome():
    env.warn(0, wNotEnoughMemoryForLB)
    return
  lineBufferO.get()
  # var lb {.inject.} = lineBufferO.get()

proc processTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Process the given template file lines.

  # Allocate a buffer for reading lines. Return when no enough memory.
  var lb = getNewLineBuffer(env)

  # Read and process template lines.
  var inOutExtraLine: ExtraLine
  while true:
    # Read template lines and write out non-commands lines. When a
    # command that needs processing is found, return its lines.
    let cmdLines = collectCommand(env, lb, prepostTable, inOutExtraLine)
    if inOutExtraLine.kind == elkOutOfLines:
      break

    # Run the command to fill in the variables.
    runCommand(env, cmdLines, prepostTable, variables)

    # Fill in the replacement block and return the line after it.
    let command = cmdLines.lineParts[0].command
    fillReplacementBlock(env, lb, command, variables, inOutExtraLine)

proc updateTemplateLines(env: var Env, variables: var Variables,
    prepostTable: PrepostTable) =
  ## Update the given template file's replacement blocks.

  #[ Read template lines and write them out. Read command lines and
  write them out. Run the command to determine the t.content, then
  write out the t.content. Repeat.

  If the template is coming from a file, write the content to a temp
  file then rename it at the end overwriting the original template
  file.  If the template comes from standard in, write the new
  template to standard out. ]#

  # Allocate a buffer for reading lines. Return when no enough memory.
  var lb = getNewLineBuffer(env)

  # Read and process template lines.
  var inOutExtraLine: ExtraLine
  while true:
    # Read template lines and write out non-command lines. When a
    # replace command is found, collect its lines and return them.
    # ExtraLine is an input and output parameter.
    var cmdLines = collectReplaceCommand(env, lb, prepostTable, inOutExtraLine)
    if cmdLines.noMoreLines:
      break

    # Run the replace command to set the content variable.
    runCommand(env, cmdLines, prepostTable, variables)

    # Update the replacement block with lines from the content
    # variable. ExtraLine is an input and output parameter.
    updateReplacementBlock(inOutExtraLine)
    if inOutExtraLine.noMoreLines:
      break

proc readJsonFiles*(env: var Env, filenames: seq[string]): VarsDict =
  ## Read json files and return a variable dictionary.  Skip a
  ## duplicate variable and generate a warning.

  var varsDict = newVarsDict()
  for filename in filenames:
    let valueOrWarning = readJsonFile(filename)
    if valueOrWarning.kind == vwWarning:
      env.warn(0, valueOrWarning.warningData)
    else:
      # Merge in the variables.
      for k, v in valueOrWarning.value.dictv.pairs:
        if k in varsDict:
          # Skip the duplicates
          env.warn(0, wDuplicateVar, k)
        else:
          varsDict[k] = v
  result = varsDict

proc getStartingVariables(env: var Env, args: Args): Variables =
  ## Read and return the server and shared variables and setup the
  ## initial tea variables.

  # The tea variables are the top level items.  All variables are tea
  # variables in the sense that they all exists somewhere in this
  # dictionary.

  var serverVarDict = readJsonFiles(env, args.serverList)
  var sharedVarDict = readJsonFiles(env, args.sharedList)
  var argsVarDict = getTeaArgs(args).dictv

  result = emptyVariables(serverVarDict, sharedVarDict, argsVarDict)

proc getPrepostTable(args: Args): PrepostTable =
  ## Get the the prepost settings from the user or use the default
  ## ones.

  # Get the prepost table, either the user specified one or the
  # default one. The defaults are not used when the user specifies
  # them, so that they have complete control over the preposts used.
  if args.prepostList.len > 0:
    # The prepostList has been validated already.
    result = makeUserPrepostTable(args.prepostList)
  else:
    result = makeDefaultPrepostTable()

proc processTemplate*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var prepostTable = getPrepostTable(args)

  # Process the template.
  processTemplateLines(env, variables, prepostTable)

  if env.warningWritten > 0:
    result = 1

proc updateTemplate*(env: var Env, args: Args): int =
  ## Update the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var prepostTable = getPrepostTable(args)

  # Process the template.
  updateTemplateLines(env, variables, prepostTable)

  if env.warningWritten > 0:
    result = 1

proc processTemplateTop*(env: var Env, args: Args): int =
  ## Setup the environment streams then process the template and
  ## return 0 on success.

  # Add the template and result streams to the environment.
  if not env.addExtraStreams(args):
    return 1

  # Process the template.
  result = processTemplate(env, args)

# todo: using t.content on a block command? show message?

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
