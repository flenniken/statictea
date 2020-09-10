## Process the template.

import streams
import strutils
import args
import warnings

proc processTemplate*(warnings: Stream, args: Args) =

# templateList: seq[string],
#     serverList: seq[string], sharedList: seq[string],
#     resultFilename: string , prepostList: seq[Prepost]) = 

  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    warning(warnings, "starting", 0, wOneTemplateAllowed, skipping)
# file(line): w1: One template file allowed, skipping: tea2.html, tea3.html"
  echo "processing template"
