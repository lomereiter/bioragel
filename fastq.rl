# TODO: doesn't work with wrapped lines yet
%%{
    machine fastq;
    alphtype char;

    newline = '\n' ;
    qual = [!-~]+ ;
    seq = [^\n]+ ;
    seqname = [^\n]+ ;
    required_seqname = seqname ;
    optional_seqname = seqname? ;
    block = '@' required_seqname newline seq newline 
            '+' optional_seqname newline 
            qual newline ;
    main := block+ ;

    write data;
}%% 
