#$ # Statictea template for src/functionsList.nim
#$ #
# This file is auto generated from src/functions.nim doc comments using
# the statictea template templates/dynamicFuncList.nim and the nimble
# task dyfuncs.

type
  BuiltInInfo* = object
    ## The built-in function information.
    ##
    ## * **funcName** — the function name in the nim file, e.g.: fun_add_ii
    ## * **docComment** — the function documentation
    ## * **numLines** — the number of function code lines
    funcName*: string
    docComment*: string
    numLines*: Natural

func newBuiltInInfo*(
    funcName: string,
    docComment: string,
    numLines: Natural
  ): BuiltInInfo =
  ## Return a BuiltInInfo object.
  result = BuiltInInfo(funcName: funcName, docComment: docComment,
    numLines: numLines)

const
#$ # Define all the doc comments. Use prefix dc_ followed by the
#$ # function name.
#$ block
#$ : t.repeat = len(o.entries)
#$ : entry = o.entries[t.row]
  dc_{entry.funcName} = """
{entry.docComment}
"""

#$ endblock
  info = newBuiltInInfo
  functionsList = [
#$ # List all the functions.
#$ #
#$ # Example line:
#$ # info("fun_add_fff", dc_add_fff, 10),
#$ #
#$ block t.repeat = len(o.entries)
#$ : entry = o.entries[t.row]
    info("{entry.funcName}", dc_{entry.funcName}, {entry.numLines}),
#$ endblock
  ]
    ## Dynamically generated sorted list of built-in functions. Each
    ## line contains the nim function name, its doc comment, and the
    ## number of lines.  See templates/dynamicFuncList.nim
    
  # Note: the function starting lines is separate from the list above
  # so when there are changes the diffs are easier to read.

  functionStarts = [
#$ # Make a list of all the function start lines.
#$ nextline t.repeat = len(o.entries)
#$ : entry = o.entries[t.row]
    {entry.lineNum},
  ]
    ## Dynamically generated array of starting line numbers for each
    ## built-in function in the functions.nim file.
