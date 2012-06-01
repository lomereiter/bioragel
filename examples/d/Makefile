all:
	ragel -D fastq.rl -G2
	dmd fastq.d -O -release -inline

clean:
	rm fastq.d fastq.o fastq
