FROM images.sbgenomics.com/ognjenm/vcftools:0.1.14

# Install scripts
RUN mkdir /home/analyst
COPY clean_vcf.sh /home/analyst/
RUN chmod a+x /home/analyst/clean_vcf.sh
