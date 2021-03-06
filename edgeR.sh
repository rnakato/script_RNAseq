#!/bin/bash
cmdname=`basename $0`
function usage()
{
    echo "$cmdname [-a] <Matrix> <Ensembl|UCSC> <build> <num of reps> <groupname> <FDR>" 1>&2
    echo "  Example:" 1>&2
    echo "  $cmdname Matrix GRCh38 2:2 WT:KD 0.05" 1>&2
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
db=$2
build=$3
n=$4
gname=$5
p=$6

n1=$(cut -d':' -f1 <<<${n})
n2=$(cut -d':' -f2 <<<${n})

Ddir=`database.sh`

Rdir=$(cd $(dirname $0) && pwd)
R="Rscript $Rdir/edgeR.R"

ex(){
    echo $1
    eval $1
}

postfix=count.$build

# genes
ncol=$((n1+n2+2))
ex "cut -f 1-$ncol $outname.genes.count.$build.txt > $outname.genes.count.$build.temp"
ex "$R -i=$outname.genes.count.$build.temp    -n=$n -gname=$gname -o=$outname.genes.$postfix    -p=$p -nrowname=2 -ncolskip=1"
rm $outname.genes.count.$build.temp

# isoforms
ncol=$((n1+n2+3))
cut -f 1-$ncol $outname.isoforms.count.$build.txt > $outname.isoforms.count.$build.temp
ex "$R -i=$outname.isoforms.count.$build.temp -n=$n -gname=$gname -o=$outname.isoforms.$postfix -p=$p -nrowname=3 -ncolskip=2 -color=orange"
rm $outname.isoforms.count.$build.temp

d=`echo $build | sed -e 's/.proteincoding//g'`
for str in genes isoforms; do
    if test $str = "genes"; then
#        nline=0
        refFlat=`ls $Ddir/$db/$d/release1*/gtf_chrUCSC/*.$build.1*.chr.gene.refFlat | tail -n1`
    else
#        nline=1
        refFlat=`ls $Ddir/$db/$d/release1*/gtf_chrUCSC/*.$build.1*.chr.transcript.refFlat | tail -n1`
    fi

    s=""
    # gene info 追加
    for ty in all DEGs upDEGs downDEGs; do
	    head=$outname.$str.$postfix.edgeR.$ty
	    add_geneinfo_fromRefFlat.pl $str $head.tsv $refFlat 0 > $head.temp
	    mv $head.temp $head.tsv
	    s="$s -i $head.tsv -n fitted-$str-$ty"
    done

    # short gene, nonsense geneを除去 (all除く)
    if test $all = 0; then
	for ty in DEGs upDEGs downDEGs; do
	    head=$outname.$str.$postfix.edgeR.$ty
	    filter_short_or_nonsense_genes.pl $head.tsv -l 1000 > $head.temp
	    mv $head.temp $head.tsv
	done
    fi

    for ty in DEGs upDEGs downDEGs; do
       head=$outname.$str.$postfix.edgeR.$ty
       ncol=`head -n1 $head.tsv | awk '{print NF}'`
       n1=$((ncol-3))
       n2=$((ncol-4))
       n3=$((ncol-6))
       cut -f$n1,$n2,$n3 $head.tsv | grep -v chromosome > $head.bed
    done

    csv2xlsx.pl $s -o $outname.$str.$postfix.edgeR.xlsx
done
