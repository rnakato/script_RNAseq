#!/bin/bash
cmdname=`basename $0`
function usage()
{
    echo "DESeq2.sh <Matrix> <build> <num of reps> <groupname> <FDR> <gtf>" 1>&2
    echo "  Example:" 1>&2
    echo "  DESeq2.sh star/Matrix GRCh38 2:2 WT:KD 0.05 GRCh38.gtf" 1>&2
}

all=0
while getopts a option
do
    case ${option} in
        a)
            all=1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -ne 6 ]; then
  usage
  exit 1
fi

outname=$1
build=$2
n=$3
gname=$4
p=$5
gtf=$6

n1=$(cut -d':' -f1 <<<${n})
n2=$(cut -d':' -f2 <<<${n})

Rdir=$(cd $(dirname $0) && pwd)
R="Rscript $Rdir/DESeq2.R"

Ddir=`database.sh`

ex(){
    echo $1
    eval $1
}

postfix=count.$build

# genes
ncol=$((n1+n2+2))
ex "cut -f 1-$ncol $outname.genes.$postfix.txt > $outname.genes.$postfix.temp"
ex "$R -i=$outname.genes.$postfix.temp -n=$n -gname=$gname -o=$outname.genes.$postfix -p=$p -nrowname=2 -ncolskip=1"
rm $outname.genes.$postfix.temp

# isoforms
ncol=$((n1+n2+2))
cut -f 1-$ncol $outname.isoforms.$postfix.txt > $outname.isoforms.$postfix.temp
ex "$R -i=$outname.isoforms.$postfix.temp -n=$n -gname=$gname -o=$outname.isoforms.$postfix -p=$p -nrowname=2 -ncolskip=1"
rm $outname.isoforms.$postfix.temp

#d=`echo $build | sed -e 's/.proteincoding//g'`
for str in genes isoforms; do
#    if test $str = "genes"; then
#        refFlat=`ls $Ddir/Ensembl/$d/release1*/gtf_chrUCSC/*.$build.1*.chr.gene.refFlat | tail -n1`
#    else
#        refFlat=`ls $Ddir/Ensembl/$d/release1*/gtf_chrUCSC/*.$build.1*.chr.transcript.refFlat | tail -n1`
#    fi

    s=""
    # gene info 追加
#    for ty in all DEGs upDEGs downDEGs; do
#            head=$outname.$str.$postfix.DESeq2.$ty
#            add_geneinfo_fromRefFlat.pl $str $head.tsv $refFlat 0 > $head.temp
#            mv $head.temp $head.tsv
  #          s="$s -i $head.tsv -n fitted-$str-$ty"
  #  done

    # short gene, nonsense geneを除去 (all除く)
#    if test $all = 0; then
#        for ty in DEGs upDEGs downDEGs; do
#            head=$outname.$str.$postfix.DESeq2.$ty
#            filter_short_or_nonsense_genes.pl $head.tsv -l 1000 > $head.temp
#            mv $head.temp $head.tsv
#        done
#    fi

    for ty in DEGs upDEGs downDEGs; do
       head=$outname.$str.$postfix.DESeq2.$ty
       ncol=`head -n1 $head.tsv | awk '{print NF}'`
       n1=$((ncol-2))
       n2=$((ncol-3))
       n3=$((ncol-5))
       cut -f$n1,$n2,$n3 $head.tsv | grep -v chromosome > $head.bed
    done

    s=""
    for ty in all DEGs upDEGs downDEGs; do
        head=$outname.$str.$postfix.DESeq2.$ty
        s="$s -i $head.tsv -n fitted-$str-$ty"
    done
    csv2xlsx.pl $s -o $outname.$str.$postfix.DESeq2.xlsx
done
