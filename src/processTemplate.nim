## Process the template.

import args
import warnings
import env
import readjson
import vartypes
import matches
import readlines
import options
import parseCmdLine
import collectCommand
import runCommand

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

<--!$ nextline a = 5 \-->\n
<--!$ : a = 5 \-->\n
<--!$ : b = 6 \-->\n
<--!$ : c = 7  -->\n

There are three line types: cmd lines, replacement block lines and
other lines.

Cmd lines start with a prefix, and they may continue on multiple
lines.

Replacement block lines follow cmd lines. One line for the nextline
command and one or more lines for replace and block commands.

Other lines, not cmd or block lines, get echoed to the output file
unchanged.

]#

proc processTemplateLines(env: var Env, serverVars: VarsDict, sharedVars: VarsDict,
    prepostList: seq[Prepost]) =
  ## Process the given template file.

  # Get all the compiled regular expression matchers.
  let compiledMatchers = getCompiledMatchers(prepostList)

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(env.templateStream, filename=env.templateFilename)
  if not lineBufferO.isSome():
    env.warn("startup", 0, wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  # Read and process template lines.
  while true:
    # Read template lines and write out non-command lines. When a
    # command is found, collect its lines and return them.
    var cmdLines: seq[string] = @[]
    var cmdLineParts: seq[LineParts] = @[]
    collectCommand(env, lb, compiledMatchers, env.resultStream, cmdLines, cmdLineParts)
    if cmdLines.len == 0:
      break # done, no more lines

    # Run the command.
    let localVars = runCommand(env, cmdLines, cmdLineParts,
                               serverVars, sharedVars, compiledMatchers)

    # Process the replacement block.

proc processTemplate*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. It's an error when
  ## a warning messages was written.

  # Read the server json.
  var serverVars = getEmptyVars()
  for filename in args.serverList:
    readJson(env, filename, serverVars)

  # Read the shared json.
  var sharedVars = getEmptyVars()
  for filename in args.sharedList:
    readJson(env, filename, sharedVars)

  # Process the template.
  processTemplateLines(env, serverVars, sharedVars, args.prepostList)

  if env.warningWritten > 0:
    result = 1
