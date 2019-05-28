#!/bin/bash

bam=$1
mhccoords=$2
outPrefix=$3

mhc=$(cat $mhccoords)

#bam to fastq
mapunset=${outPrefix}_map_unset.fq
mapfq1=${outPrefix}_map_1.fq 
mapfq2=${outPrefix}_map_2.fq 
unmapfq1=${outPrefix}_unmap_1.fq
unmapfq2=${outPrefix}_unmap_2.fq
unmapunset=${outPrefix}_unmap_unset.fq
mhcfq1=${outPrefix}_mhc_1.fq
mhcfq2=${outPrefix}_mhc_2.fq
reads1tmp=${outPrefix}_reads1.tmp
reads2tmp=${outPrefix}_reads2.tmp
reads1=${outPrefix}_reads1
reads2=${outPrefix}_reads2
reads=${outPrefix}_reads

echo "Extracting MHC and unmapped reads from BAM..."

if [[ ! -f "$bam".bai ]]; then
    samtools index $bam $bam.bai
fi

samtools view $bam $mhc -b |\
    samtools sort -n - |\
    samtools fastq -1 $mapfq1 -2 $mapfq2 -0 $mapunset -

samtools view -F 0x2 $bam -b |\
    samtools sort -n - |\
    samtools fastq -1 $unmapfq1 -2 $unmapfq2 -

cat $mapfq1 $unmapfq1 > $mhcfq1.tmp
cat $mapfq2 $unmapfq2 > $mhcfq2.tmp

sed -n '1~4p' $mhcfq1.tmp | sed 's|^@||' | sort > $reads1tmp
sed -n '1~4p' $mhcfq2.tmp | sed 's|^@||' | sort > $reads2tmp

if [[ $(head -n1 $reads1tmp) =~ /1$ ]] && [[ $(head -n1 $reads2tmp) =~ /2$ ]]; then

     comm -12 <(sed 's|/[[:digit:]]$||' $read1tmp | sort) <(sed 's|/[[:digit:]]$||' $reads2tmp | sort) |\
	 sort -V |\
	 uniq > $reads

     awk '{ print $0 "/1" }' $reads > $reads1
     awk '{ print $0 "/2" }' $reads > $reads2

 elif

     comm -12 <(sort $read1tmp) <(sort $reads2tmp) |\
	 sort -V |\
	 uniq > $reads

     cat $reads1tmp > $reads1
     cat $reads2tmp > $reads2

fi

echo "Writing fastq files..."

seqtk subseq $mhcfq1.tmp ${outPrefix}_reads > $mhcfq1
seqtk subseq $mhcfq2.tmp ${outPrefix}_reads > $mhcfq2

#rm $mapfq1 $mapfq2 $mapunset $unmapfq1 $unmapfq2 $unmapunset $mhcfq1.tmp \
#	$mhcfq2.tmp $reads1tmp $reads2tmp $reads1 $reads2 $reads

echo "Done!"
