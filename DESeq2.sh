#!/bin/bash
cmdname=`basename $0`
function usage()
{
    echo "DESeq2.sh <Matrix> <build> <num of reps> <groupname> <FDR>" 1>&2
    echo "  Example:" 1>&2
    echo "  DESeq2.sh star/Matrix GRCh38 2:2 WT:KD 0.05" 1>&2
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

if [ $# -ne 5 ]; then
  usage
  exit 1
fi

outname=$1
build=$2
n=$3
gname=$4
p=$5

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
ex "$R -i=$outname.genes.$postfix.txt -n=$n -gname=$gname -o=$outname.genes.$postfix -p=$p -nrowname=2 -ncolskip=1"
ex "$R -i=$outname.isoforms.$postfix.txt -n=$n -gname=$gname -o=$outname.isoforms.$postfix -p=$p -nrowname=2 -ncolskip=1"

for str in genes isoforms; do
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
        n1=$((ncol-5))
        n2=$((ncol-4))
        n3=$((ncol-3))
        n4=$((ncol-2))
        n5=$((ncol-1))
        cut -f$n1,$n3,$n4 $head.tsv | grep -v chromosome > $head.bed
        grep -v chromosome $head.tsv | awk 'BEGIN { OFS="\t" } {print $'$n1', $'$n3', $'$n4', $2, $'$n5', $'$n2' }' > $head.bed6
    done

    s=""
    for ty in all DEGs upDEGs downDEGs; do
        head=$outname.$str.$postfix.DESeq2.$ty
        s="$s -i $head.tsv -n fitted-$str-$ty"
    done
    csv2xlsx.pl $s -o $outname.$str.$postfix.DESeq2.xlsx
done
