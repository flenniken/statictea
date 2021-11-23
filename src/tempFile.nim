## Temporary file methods.

import std/os
import std/random
import std/strutils
import std/options

# Used with the rand procedure.
randomize()

type
  TempFile* = object
    ## Temporary filename and file object.
    filename*: string
    file*: File

proc openTempFile*(): Option[TempFile] =
  ## Create and open an empty file in the temp directory open for read
  ## write. When no error, return TempFile containing the file and
  ## filename.

  let filename = joinPath(getTempDir(), "tea$1.tmp" % $rand(9_000_000))
  var file: File
  try:
    file = open(filename, fmReadWrite)
  except:
    return
  result = some(TempFile(file: file, filename: filename))

proc closeDelete*(tempFile: TempFile) =
  ## Close and delete the temp file.
  tempFile.file.close()
  discard tryRemoveFile(tempFile.filename)
