## Get the command line help message.

func getHelp*(): string =
  ## Get the command line help message.
  result = """
NAME

     statictea - combines a template with data to produce a result

SYNOPSIS

     statictea [-h] [-n] [-v] [-u] [-s=server.json] [-j=shared.json] 
         [-t=template.html] [-p="prefix[,postfix]"] [-r=result.html]

DESCRIPTION

     Combine a template file with data from json files using template
     commands to produce an output file.

     The following options are available:

     -h, --help

             Show this help text then exit.

     -t=filename, --template=filename

             The template file to process. Use the name "stdin" to
             read the template from standard input.

     -r=filename, --result=filename

             The name of the file to create for the results. If not
             specified, the result goes to standard out.

     -s=filename, --server=filename

             Read a json file and store it in the server
             dictionary. You can specify zero or more server options.

     -j=filename, --shared=filename

             Read a json file and store it in the shared
             dictionary. You can specify zero or more shared options.

     -p="prefix,postfix", --prepost="prefix,postfix"

             Add a prefix, postfix comment style for use in the
             template. You can specify zero or more. Separate prefix
             from postfix with a comma. The postfix is optional.

     -u, --update

             Update the template's replace blocks to syncronize them
             with the json data.

     -l[=filename], --log[=filename]

             Turn on logging and optionally specify the filename. When
             no filename is specified, use "/var/log/statictea.log".

     -v, --version

             Show the version number then exit.

EXAMPES
     Typical usage:

             statictea -s=server.json -j=shared.json \
                 -t:template.html -r=home.html

     You can specify multiple shared or server json files.

             statictea -s=server.json -j=s1.json -j=s2.json \
                 -t=template.html -r=h.html

     You can specify comment styles to use in your templates with the
     --prepost option.  For example, if you want to use the c style
     comments:

             statictea -p="/* */" ...

     You can specify update to syncronize your template's replace
     blocks with the json data.

             statictea -u -j=shared.json -t=template.html

SEE ALSO
     For more information see https://github.com/flenniken/statictea
"""
