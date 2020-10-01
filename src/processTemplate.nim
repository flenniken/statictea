## Process the template.

import strutils
import args
import warnings
import warnenv
# import tables
# import tpub
import readjson
# import vartypes

# templateList: seq[string],
#     serverList: seq[string], sharedList: seq[string],
#     resultFilename: string , prepostList: seq[Prepost]) =

proc processTemplate*(args: Args): int =
  ## Process the template and return 0 on success.

  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    warn("starting", 0, wOneTemplateAllowed, skipping)
  echo "processing template"

  var serverVars = getEmptyVars()
  for filename in args.serverList:
    readJson(filename, serverVars)

  var sharedVars = getEmptyVars()
  for filename in args.sharedList:
    readJson(filename, sharedVars)
