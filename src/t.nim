# try out things here
# build and run with "n tt"

proc unsafeCall() =
  raise newException(OSError, "OS")

proc p(): bool {.raises: [].} =
  try:
    unsafeCall()
    result = true
  except:
    result = false

echo $p()
