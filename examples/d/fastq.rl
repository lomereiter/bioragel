/// Parses FASTQ file and prints number of records

import std.stdio;
import std.conv;
import std.stream;
import std.c.string;
import std.c.stdlib;

debug {
import std.stdio;
}

struct FastqRecord {
    string header;
    string sequence;
    string quality;
}

void main(string[] args) {
    if (args.length != 2) {
        writeln("usage: " ~ args[0] ~ " <input.fastq>");
        return;
    }

    auto fastq = new BufferedFile(args[1]);

    uint count = 0;
    foreach(record; records(fastq)) {
        count += 1;
    }

    writeln(count);
}

%%{
    machine fastq;
    alphtype char;

    action increase_line_counter { linenumber += 1; }

    action start_pos_seqname { start_pos = p - buffer; }
    action end_seqname { 
        seqname = cast(string)storage[start_pos .. p - buffer].dup; 
    }

    action end_optional_seqname { 
        if (p != buffer + start_pos) {
            string opt = cast(string)storage[start_pos .. p - buffer];
            if (opt != seqname)
            {
                throw new Exception("wrong sequence identifier after '+': "~
                                    opt ~ " (expected " ~ seqname ~ ")" ~
                                    " at line " ~ to!string(linenumber));
            }
        }
    }

    action start_pos_seq { start_pos = p - buffer; }
    action end_seq { seq = cast(string)storage[start_pos .. p - buffer].dup; }

    action start_pos_qual { start_pos = p - buffer; }
    action end_qual {
        qual = cast(string)storage[start_pos .. p - buffer].dup;
        if (qual.length != seq.length) {
            debug {
                writeln("sequence length = ", seq.length, " ", seq);
                writeln("quality length = ", qual.length, " ", qual);
            }
            throw new Exception("sequence and quality have different lengths" ~
                                " (line " ~ to!string(linenumber) ~ ")");
        }
    }

    action end_block { fbreak; }

    newline = ('\n' | '\r''\n') % increase_line_counter;
    qual = ([!-~])+ > start_pos_qual % end_qual;
    seq = [^\n]+ > start_pos_seq % end_seq;
    seqname = [^\n]+ ;
    required_seqname = seqname > start_pos_seqname % end_seqname;
    optional_seqname = seqname? > start_pos_seqname % end_optional_seqname;
    block = '@' required_seqname newline seq newline 
            '+' optional_seqname newline 
            qual % end_block newline ;
    main := block+ ;

    write data;
}%% 

/// Returns range for iterating over FASTQ records
auto records(Stream stream) {

    struct Result {

        private {
            string seqname;
            string seq;
            string qual;

            int cs;        /// Those four variables are 
            ubyte* p;      ///  required    
            ubyte* pe;     ///    for      
            ubyte* eof;    ///   Ragel    

            bool _empty = false;
            size_t start_pos; // points to start_pos of currently parsed entity

            Stream stream;
            ubyte* buffer;
            immutable size_t CHUNK_SIZE = 10000;
            
            ubyte[] storage;

            uint linenumber = 1;
        }

        this(ref Stream stream) {
            this.stream = stream;
            storage = new ubyte[CHUNK_SIZE];
            buffer = storage.ptr;

            debug {
                writeln("reading first chunk from stream...");
            }
            auto read = stream.read(buffer[0 .. CHUNK_SIZE]);

            debug {
                writeln("read ", read, " bytes.");
            }
            p = cast(ubyte*)(buffer);
            pe = cast(ubyte*)(buffer + read);
            start_pos = 0;
            eof = null;
            %%write init;
            popFront();
        }
      
        ~this() {
        }

        bool empty() @property {
            return _empty;
        }

        FastqRecord front() @property {
            return FastqRecord(seqname, seq, qual);
        }
        
        void popFront() {
            if (p == pe) {
                if (stream.eof()) {
                    _empty = true;
                    eof = p;
                    return;
                } 

                /*
                 *                 buffer
                 *                                                        
                 *  [...........*....................*....................]
                 *              start_pos            p = pe                 
                 *              [        len         ]                      
                 *                                                          
                 *               <------- move                              
                 *                                                          
                 *  [...................*..................*..............]
                 *  start_pos           p                  pe = p + read 
                 *  [       len         ]
                 */

                // refill buffer
                auto len = pe - (buffer + start_pos); // number of remaining bytes
                memmove(buffer, buffer + start_pos, len); // move to beginning

                debug {
                    writeln("refilling buffer...");
                    writeln("remaining bytes: ", to!string(len));
                    writeln("mark position: ", to!string(start_pos));
                }

                auto read = stream.read(buffer[len .. CHUNK_SIZE]);

                start_pos = 0;

                debug {
                    writeln("read ", read, " bytes.");
                    writeln("buffer: ", to!string(buffer));
                    writeln("storage: ", to!string(storage.ptr));
                }

                p = buffer + len;
                pe = p + read;

            }
            %%write exec;
            if (cs == %%{ write error; }%%) {
                throw new Exception("invalid input at line " ~ to!string(linenumber));
            }
        }
    }
    return Result(stream);
}
