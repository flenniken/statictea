## Get the command line help message.

func getHelp*(): string =
  ## Get the command line help message.
  result = """
NAME

     statictea - combines a template with JSON to produce a result

SYNOPSIS

     statictea [-h] [-v] [-x] [-u] [-s server.json] [-o codefile.tea] 
         [-t template.html] [-p "prefix[,postfix]"] [-r result.html]

DESCRIPTION

     Combine a template with json files to produce an output file.

     The following options are available:

     -h, --help

             Show this help text then exit.

     -l [filename], --log [filename]

             Turn on logging and optionally specify the filename. When
             no filename is specified this file is used:
             * Mac: ~/Library/log/statictea.log
             * Other: ~/statictea.log

     -o filename, --code filename

             Run a code file to populate the o shared dictionary. You
             can specify zero or more code options.

     -p "prefix,postfix", --prepost "prefix,postfix"

             Add a prefix, postfix comment style for use in the
             template. You can specify zero or more. Separate prefix
             from postfix with a comma. The postfix is optional.

     -r filename, --result filename

             The name of the file to create for the results. If not
             specified, the result goes to standard out.

     -s filename, --server filename

             Read a json file and store it in the server
             dictionary. You can specify zero or more server options.

     -t filename, --template filename

             The template file to process. Use the name "stdin" to
             read the template from standard input.

     -u, --update

             Update the template's replace blocks to syncronize them
             with the json data.

     -v, --version

             Show the version number then exit.

     -x, --repl

             Run commands at a prompt.

EXAMPES
     Typical usage:

             statictea -s server.json -o codefile.tea \
                 -t:template.html -r home.html

     You can specify multiple server or code files.

             statictea -s server.json -o shared.tea -o shared2.tea \
                 -t template.html -r h.html

     You can specify comment styles to use in your templates with the
     --prepost option.  For example, if you want to use the c style
     comments:

             statictea -p '/*$,*/' ...

     You can specify update to syncronize your template's replace
     blocks with the shared data.

             statictea -u -o shared.tea -t template.html

SEE ALSO
     For more information see https://github.com/flenniken/statictea
"""
