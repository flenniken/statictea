import regexes
import env
import vartypes
import options
import parseCmdLine
import readLines
import matches
import warnings
import variables
import streams
import variables

proc replaceLine*(env: var Env, compiledMatchers: CompiledMatchers,
                  variables: Variables, lineNum: int, line: string, stream: Stream) =
  ## Replace the variable content in the line and output to the given
  ## stream.
  var pos = 0
  var nextPos: int

  while true:
    # Get the text before the variable.
    let beforeVarO = getMatches(compiledMatchers.leftBracketMatcher,
                                line, pos)
    if not beforeVarO.isSome:
      # Output the rest of the line as is.
      stream.write(line[pos .. ^1])
      break
    let beforeVar = beforeVarO.get()
    echo "beforeVar.length: " & $beforeVar.length

    # Get the variable.
    let variableO = getMatches(compiledMatchers.variableMatcher,
                                line, pos + beforeVar.length)
    if not variableO.isSome:
      nextPos = pos + beforeVar.length
      stream.write(line[pos ..< nextPos])
      pos = nextPos
      continue
    let variable = variableO.get()
    let (nameSpace, varName) = variable.get2Groups()
    echo "variable.length: " & $variable.length

    # Check that the variable ends with a right bracket.
    if line[pos+beforeVar.length+variable.length] != '}':
      nextPos = pos + beforeVar.length + variable.length
      stream.write(line[pos .. ^nextPos])
      pos = nextPos
      continue

    # Look up the variable's value.
    let valueO = getVariable(variables, namespace, varName)
    if not isSome(valueO):
      env.warn(lineNum, wMissingReplacementVar, varName)
      nextPos = pos + beforeVar.length + variable.length
      stream.write(line[pos ..< nextPos])
      pos = nextPos
      continue
    let value = valueO.get()

    # Write out the text before the variable and the variable's value.
    stream.write(line[pos ..< (pos + beforeVar.length - 1)])
    stream.write($value)

    pos = pos + beforeVar.length + variable.length + 1


proc processReplacementBlock*(env: var Env, lb: var LineBuffer,
                              compiledMatchers: CompiledMatchers,
                              command: string, variables: Variables) =
  ## Read replacement block lines and output result lines by replacing
  ## variable content.

  # for nextline read one line
  # for block and replace read until endblock or endreplace

  if command == "nextline":
    var line = lb.readline()
    replaceLine(env, compiledMatchers, variables, lb.lineNum, line, env.resultStream)
    return

  while true:
    var line = lb.readline()
    if line == "":
      break # No more lines.

    var linePartsO = parseCmdLine(env, compiledMatchers, line, lb.lineNum)

    if not linePartsO.isSome:
      # Write out non-command lines.
      env.resultStream.write(line)
