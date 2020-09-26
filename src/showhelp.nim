## Show help on the command line.

proc getHelp(): string =
  result = """
NAME
     statictea - combines a template with data to produce a result

SYNOPSIS
     statictea [-h] [-l] [-v] [-s=server.json] [-j=shared.json] [-t=template.html]
       [-p="pre post"] [-r=result.html]

DESCRIPTION
     Combine a template file with data from json files using template commands to produce
     an output file.

     The following options are available:

     -h, --help
             Show this help text then exit.

     -l, --log
             Log timing, system statistics, and diognatics information to the
             statictea.log file.

     -v, --version
             Show the version number then exit.

     -s=filename, --server=filename
             Read a json file and store it in the server
             dictionary. You can specify zero or more files.

     -j=filename, --shared=filename
             Read a json file and store it in the shared
             dictionary. You can specify zero or more files.

     -t=filename, --template=filename
             The template file to process. Use the name "stdin" to read the template
             from standard input.

     -r=filename, --result=filename
             The name of the file to create for the results. If not specified,
             the result goes to standard out.

     -p="prefix postfix", --prepost="prefix postfix"
             Add prefix, postfix comment styles for use in the template. You can
             specify zero or more. Separate prefix from postfix with a space. The
             postfix is optional.

EXAMPES
     Typical usage:
             statictea -l -s=server.json -j=shared.json -t:template.html -r=home.html

     You can specify multiple shared of server json files.
             statictea -l -s=server.json -j=s1.json -j=s2.json -t=template.html -r=h.html

     You can specify comment styles to use in your templates with the --prepost option.
     If you want to use the c style comments: /* ... */ the prepost option:
             statictea -p="/* */" ...

SEE ALSO
     For more information see https://github.com/flenniken/statictea
"""

proc showHelp*(): int =
  echo getHelp()
