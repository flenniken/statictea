## Show help on the command line.

proc getHelp(): string =
  result = "show help"

proc showHelp*(): int =
  echo getHelp()
