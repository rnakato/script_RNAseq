## Scripts for RNA-seq analysis
---
### csv2xlsx.pl
merge csv/tsv files to a single xlsx file

    csv2xlsx.pl -i file1.tsv -n tabname1 [-i file2.tsv -n tabname2 ...] -o output.xlsx

---
## RNA-seq pipeline
Command example:

    for prefix in CDLS1 CDLS2 WT1 WT2; do
       star.sh paired $prefix "fastq/${prefix}_R1.fq.gz fastq/${prefix}_R2.fq.gz" Ensembl GRCh38 0
    done
    
    rsem_merge.sh "WT1 WT2 CDLS1 CDLS2" Matrix.CdLS Ensembl GRCh38 "2015_001"
    edgeR.sh Matrix.CdLS Ensembl GRCh38 2:2 0.05


### star.sh: execute STAR
#### Usage

    star.sh <single|paired> <output prefix> <fastq> <Ensembl|UCSC> <build> <--forward-prob>

For `--forward-prob`, supply 0 for stranded RNA-seq and 0.5 for unstranded RNA-seq.

Output: 
* star/*Aligned.sortedByCoord.out.bam # mapfile for genome
* star/*.Aligned.toTranscriptome.out.bam  # mapfile for gene
* star/*.<genes|isoforms>.results  # gene expression data
* log/star-*.txt

log example:

|Sequenced	|Uniquely mapped|	(%)	|Mapped to multiple loci|	(%)|	Mapped to too many loci|	(%)|	Unmapped (too many mismatches)	|Unmapped (too short)	|Unmapped (other)	|chimeric reads|	(%)	|Splices total	|Annotated	|(%)	|Non-canonical	|(%)	|Mismatch rate per base (%)|	Deletion rate per base (%)	|Insertion rate per base (%)|
----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----
|29446992	|27430449	|93.15	|1012811	|3.44	|5253	|0.02	|0%|	3%	|0%	|0	|0	|18960488	|18725703	|98.76	|30590	|0.16	|0.19	|0.01	|0.01|


### Example

### rsem_merge.sh: execute RSEM

    rsem_merge.sh <files> <output> <Ensembl|UCSC> <build> <strings for sed>

Output:
* gene expression data: *.<genes|isoforms>.<TPM|count>.<build>.txt
* merged xlsx: *.<build>.xlsx 


### edgeR.sh: execute edgeR for two groups

    edgeR.sh [-a] <Matrix> <Ensembl|UCSC> <build> <num of reps> <groupname>  <FDR>

Output
* merged xlsx: *.<genes|isoforms>.count.<build>.edgeR.xlsx
* BCV/MDS plot: *.<genes|isoforms>.count.<build>.BCV-MDS.pdf
* MA plot:  *.<genes|isoforms>.count.<build>.MAplot.pdf

* DEGのリストからは1kbpより短い遺伝子は除かれます。また、出力されるのはprotein_coding、antisense, lincRNAのみです。ALLには全て含まれます。
* DEGにこれらの遺伝子を含めたい場合は-aオプションを指定します。
