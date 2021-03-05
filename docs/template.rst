.. Comment

#$ nextline
{s.orig}

#$ nextline
{s.moduleDescription}

#$ block \
#$ : t.repeat = len(s.entries); \
#$ : dashes = '----------------------------------------------------------------------------------'; \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : nameUnderline = substr(dashes, 0, len(name)) \
#$ : description = get(entry, "description", ""); \
#$ : code = get(entry, "code", ""); \
#$ : pos = find(code, "{"); pos = case(pos, pos, -1, len(code)); \
#$ : signature = substr(code, 0, pos);
{name}
{nameUnderline}

{signature}

{description}

#$ endblock
