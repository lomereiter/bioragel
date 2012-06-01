%%{
    machine gff3;

    newline = '\n' | '\r''\n' ;

    pragma = [^\n]* ;
    pragmaline = "##" pragma ;

    commentline = '#' | '#' [^#] [^\n]* ;

    seqid = [a-zA-Z0-9.:^*$@!+_?-|]+ ;
    source = [^\t\n]+ ;

    sofaterm = [^\t\n]+ ;
    fullsoterm = [^\t\n]+ ;
    accessionnumber = "SO:" digit+ ;
    type = sofaterm | fullsoterm | accessionnumber ;

    start = [1-9] digit* ;
    end = [1-9] digit* ;

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

    value = [^,=;\t\n]+ ;
    values = value (',' value)* ;
    tagvaluepair = tag '=' values ;
    semicolon = ';' ' '+ ;
    attributes = (tagvaluepair (semicolon tagvaluepair)*)? ;

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
    gff3 := (line (newline line)*)? ; # TODO: make machine for fasta and add here

    write data;
}%%
