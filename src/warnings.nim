## Handle warning messages.

import streams
import tpub
import strutils

type
  Warning* = enum
     wNoFilename,
     wUnknownSwitch,
     wUnknownArg,
     wOneResultAllowed,
     wExtraPrepostText,
     wOneTemplateAllowed,
     wNoPrepostValue,
     wSkippingExtraPrepost,

tpubType:
  const
    # The list of warnings. Add new messages to the bottom and do not
    # reorder the messages.
    warningsList: array[low(Warning)..high(Warning), string] = [
      #[wNoFilename          ]# "No $1 filename. Use $2=filename.",
      #[wUnknownSwitch       ]# "Unknown switch: $1.",
      #[wUnknownArg          ]# "Unknown argument: $1.",
      #[wOneResultAllowed    ]# "One result file allowed, skipping: $1.",
      #[wExtraPrepostText    ]# "Skipping extra prepost text: $1.",
      #[wOneTemplateAllowed  ]# "One template file allowed, skipping: $1.",
      #[wNoPrepostValue      ]# "No prepost value. Use $1=\"...\".",
      #[wSkippingExtraPrepost]# "Skipping extra prepost text: $1.",
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
