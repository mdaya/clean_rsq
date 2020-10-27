#!/bin/bash

in_vcf=$1
sample_file=$2
out_vcf=`basename $in_vcf | sed 's/.vcf.gz/_clean.vcf.gz/'`

bcftools view --samples-file $sample_file $in_vcf --min-ac=1:minor --apply-filters PASS | bgzip -c > $out_vcf
tabix $out_vcf
