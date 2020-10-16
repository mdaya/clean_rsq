#!/bin/bash

in_vcf=$1
sample_file=$2
out_vcf=`basename $in_vcf | sed 's/.vcf.gz/_clean.vcf.gz/'`

vcftools --gzvcf $in_vcf --keep $sample_file --remove-filtered-all --recode --stdout | bgzip -c > $out_vcf
tabix $out_vcf
