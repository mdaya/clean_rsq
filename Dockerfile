FROM images.sbgenomics.com/luka_topalovic/bcftools:1.9

# Install scripts
RUN mkdir /home/analyst
COPY clean_vcf.sh /home/analyst/
RUN chmod a+x /home/analyst/clean_vcf.sh
