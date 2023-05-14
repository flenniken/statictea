##
#$ Create a temporary file.
#$
#$ Example:
#$
#$ ~~~nim
#$ import tempFile
#$ var tempFileO = openTempFile()
#$ require tempFileO.isSome
#$ var tempFile = tempFileO.get()
#$
#$ tempFile.file.write("this is a test\\n")
#$ tempFile.file.write("line 2\\n")
#$ tempFile.file.close()
#$
#$ var fh = open(tempFile.filename, fmRead)
#$ let line1 = readline(fh)
#$ let line2 = readline(fh)
#$ fh.close()
#$
#$ discard tryRemoveFile(tempFile.filename)
#$
#$ check line1 == "this is a test"
#$ check line2 == "line 2"
#$ ~~~

import std/os
import std/random
import std/strutils
import std/options
import std/streams

# Used with the rand procedure.
randomize()

type
  TempFile* = object
    ## Temporary filename and associated file object.
    filename*: string
    file*: File

  TempFileStream* = object
    ## Temporary filename and associated stream object.
    filename*: string
    stream*: Stream

proc tempFilename(): string =
  return joinPath(getTempDir(), "tea$1.tmp" % $rand(9_000_000))

proc openTempFile*(): Option[TempFile] =
  ## Create an empty file in the temp directory open for read
  ## write. Return a TempFile object containing the filename and
  ## file object.  Call closeDeleteFile when you are done with the
  ## file.
  let filename = tempFilename()
  var file: File
  try:
    file = open(filename, fmReadWrite)
  except:
    return
  result = some(TempFile(file: file, filename: filename))

proc closeDeleteFile*(tempFile: TempFile) =
  ## Close and delete the temp file.
  tempFile.file.close()
  discard tryRemoveFile(tempFile.filename)

proc openTempFileStream*(): Option[TempFileStream] =
  ## Create an empty file stream in the temp directory open for read
  ## write. Return a TempFileStream object containing the filename and
  ## stream object.  Call closeDeleteStream when you are done with the
  ## stream.
  let filename = tempFilename()
  var newStream = openFileStream(filename, fmReadWrite)
  if newStream == nil:
    return
  result = some(TempFileStream(filename: filename, stream: newStream))

proc closeDeleteStream*(tempFileStream: TempFileStream) =
  ## Close the stream and delete the associated temp file.
  tempFileStream.stream.close()
  discard tryRemoveFile(tempFileStream.filename)
