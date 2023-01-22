#$ # Statictea template for src/functionsList.nim
#$ #
# This file is auto generated from functions.nim doc comments using
# statictea.

const
#$ # Define all the doc comments. Use prefix dc_ followed by the
#$ # function name.
#$ block t.repeat = len(o.entries)
#$ : entry = o.entries[t.row]
  dc_{entry.funcName} = """
{entry.docComment}
"""

#$ endblock
  info = newBuiltInInfo
  functionsList* = [
#$ # List all the functions.
#$ #
#$ # Example line:
#$ # info("fun_add_fff", dc_add_fff, 1, 10),
#$ #
#$ block t.repeat = len(o.entries)
#$ : entry = o.entries[t.row]
    info("{entry.funcName}", dc_{entry.funcName}, {entry.lineNum}, {entry.numLines}),
#$ endblock
  ]
    ## Dynamically generated sorted list of built-in functions. Each
    ## line contains the nim function name, its doc comment, the
    ## starting line number and the number of lines in the function.
    ## See templates/dynamicFuncList.nim
    
