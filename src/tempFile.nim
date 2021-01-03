import os
import random
import strutils
import options
import posix

# Used with the rand procedure.
randomize()

type
  TempFile* = object
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

proc truncate*(tempFile: var TempFile) =
  ## Close the temp file, truncate it, then open it again.
  tempFile.file.close()
  discard truncate(tempFile.filename, 0)
  tempFile.file = open(tempFile.filename, fmReadWrite)

proc closeDelete*(tempFile: TempFile) =
  ## Close and delete the temp file.
  tempFile.file.close()
  discard tryRemoveFile(tempFile.filename)