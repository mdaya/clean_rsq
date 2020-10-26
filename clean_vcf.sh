#!/bin/bash

in_vcf=$1
sample_file=$2
out_vcf=`basename $in_vcf | sed 's/.vcf.gz/_clean.vcf.gz/'`
tmp_sample_vcf=`basename $in_vcf | sed 's/.vcf.gz/_samples.vcf.gz/'`

bcftools view --samples-file $sample_file $in_vcf | bgzip -c > $tmp_sample_vcf
tabix $tmp_sample_vcf

bcftools view --min-ac=1 --apply-filters PASS --no-update $tmp_sample_vcf | bgzip -c > $out_vcf
tabix $out_vcf

