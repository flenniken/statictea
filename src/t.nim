## Private module for experimenting.

import std/os
import std/strutils

let filename = "abc.txt"

if not fileExists(filename):
  var file = open(filename, fmWrite)
  file.write("test file")
  file.close()

let permissions = getFilePermissions(filename)
echo $permissions

let writeSet = {fpUserWrite, fpGroupWrite, fpOthersWrite}
echo $writeSet

let writeable = writeSet * permissions
echo $writeable

if writeable.len == 0:
  echo "readonly"
else:
  echo "writeable"
