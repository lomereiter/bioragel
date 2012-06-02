/// Example: print all sequence IDs with their counts
///
/// WARNING: Loads the whole file in memory,
///          don't feed too large files

%%{
    machine gff3;

    action start_type {
        type_begin = p - data.ptr;
    }

    action end_type {
        auto type = cast(string)data[type_begin .. p - data.ptr].dup;
        types[type] += 1;
    }

    action increase_line_number {
        lineno += 1;
    }

    newline = ('\n' | '\r''\n') % increase_line_number ;

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
    type = (sofaterm | fullsoterm | accessionnumber) > start_type % end_type ;

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

import std.stdio;
import std.stream;

void main(string[] args) {
    if (args.length != 2) {
        writeln("usage: " ~ args[0] ~ " <input.gff3>");
        return;
    }
    auto file = new BufferedFile(args[1]);
    string data = file.toString();
    process(data);
}

void process(string data) {
    int[string] types;
    int lineno = 1;

    char* p = cast(char*)data.ptr;
    char* pe = p + data.length;
    char* eof = null;
    long type_begin;
    int cs;
        
    %%write init;
    %%write exec;
   
    writeln(cs);
    writeln(lineno);
    writeln(p - data.ptr);

    foreach (type, num; types) {
        writeln(type, " (", num, ")");
    }
}
