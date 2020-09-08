## Handle warning messages.

import streams
import tpub
import strutils

type
  Warning* = enum
     warnNoFilename,
     warnUnknownSwitch,
     warnUnknownArg,
     warnOneResultAllowed,
     warnExtraPrepostText,
     warnOneTemplateAllowed,

tpubType:
  const
    # The list of warnings. Add new messages to the bottom and do not
    # reorder the messages.
    warningsList: array[low(Warning)..high(Warning), string] = [
      #[warnNoFilename        ]# "No $1 filename. Use $2=filename.",
      #[warnUnknownSwitch     ]# "Unknown switch: $1.",
      #[warnUnknownArg        ]# "Unknown argument: $1.",
      #[warnOneResultAllowed  ]# "One result file allowed, skipping: $1.",
      #[warnExtraPrepostText  ]# "Skipping extra prepost text: $1.",
      #[warnOneTemplateAllowed]# "One template file allowed, skipping: $1.",
    ]

func getWarning(filename: string, lineNum: int,
    warning: Warning, p1: string="", p2: string=""): string {.tpub.} =

  let pattern = warningsList[warning]
  let message = pattern % [p1, p2]
  let messageNum = ord(warning)
  result = "$1($2): w$3: $4" % [filename, $lineNum, $messageNum, message]


proc warning*(outStream: Stream, filename: string="", lineNum: int=0,
    warning: Warning, p1: string="", p2: string="") =

  let fullLine = getWarning(filename, lineNum, warning, p1, p2)
  outStream.writeLine(fullLine)
