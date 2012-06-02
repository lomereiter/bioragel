%%{
    machine gff3;

    newline = '\n' | '\r''\n' ;

    pragma = [^\n]* ;
    pragmaline = "##" pragma ;

    commentline = '#' | '#' [^#] [^\n]* ;

    escapedcharacter = '%' [A-F0-9]{2} ;
    seqidcharacter = [a-zA-Z0-9.:^*$@!+_?-|] | escapedcharacter ;
    seqid = seqidcharacter+ ;
    source = [^\t\n]+ ;

    sofaterm = [^\t\n]+ ;
    fullsoterm = [^\t\n]+ ;
    accessionnumber = "SO:" digit+ ;
    type = (sofaterm | fullsoterm | accessionnumber) ;

    start = '.' | ([1-9] digit*) ;
    end = '.' | ([1-9] digit*) ;

    sign = [\-+]? ;
    floatnumber = sign? digit* '.'? digit+ ([eE] sign? digit+)? ;
    score = floatnumber | '.';

    strand = '+' | '-' | '.' | '?' ;

    phase = [0-2] | '.' ;

    predefinedtag = "ID" | "Name" | "Alias" | "Parent" | 
                    "Target" | "Gap" | "Derives_from" |
                    "Note" | "Dbxref" | "Ontology_term" |
                    "Is_circular" ;
    reservedtag = upper [^,=;\t\n]* ;
    usertag = lower [^,=;\t\n]* ;
    tag = predefinedtag | reservedtag | usertag;

    emptyvalue = "" ;
    value = [^,=;\t\n]+ | emptyvalue ;
    values = value (',' value)* ;
    tagvaluepair = tag '=' values ;
    semicolon = ';' ' '* ;

    nonconformantstuff = [\t;,]+ ;

    attributes = '.' | (tagvaluepair (semicolon tagvaluepair)* nonconformantstuff?) ;

    recordline = seqid '\t' 
                 source '\t' 
                 type '\t' 
                 start '\t' 
                 end '\t' 
                 score '\t'
                 strand '\t'
                 phase '\t'
                 attributes ;

    line = pragmaline | commentline | recordline | "" ;

    description = '>'[^ \n][^\n]* ;
    fastaline = [^>\n]+ ;
    data = fastaline (newline fastaline)* ;
    fastasequence = description newline data ;
    fasta = "##FASTA" newline fastasequence (newline fastasequence)* ;

    gff3 := (line (newline line)*)? fasta? newline* ;

    write data;
}%%
