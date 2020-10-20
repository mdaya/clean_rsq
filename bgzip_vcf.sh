#!/bin/bash

in_gz_vcf=$1
out_gz_vcf=`basename $in_vcf | sed 's/.vcf.gz/_bgzipped.vcf.gz/'`

zcat $in_gz_vcf | bgzip -c > $out_gz_vcf
tabix $out_gz_vcf


