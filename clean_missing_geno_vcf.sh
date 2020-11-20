#!/bin/bash

in_vcf=$1
max_missing=$2
out_vcf=`basename $in_vcf | sed 's/.vcf.gz/_clean_missing_geno.vcf.gz/'`

vcftools --gzvcf $in_vcf --max-missing $max_missing --recode --stdout | bgzip -c > $out_vcf
tabix $out_vcf
