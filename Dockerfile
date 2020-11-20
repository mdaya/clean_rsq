FROM images.sbgenomics.com/luka_topalovic/bcftools:1.9

#Install VCFTools
RUN apt-get update -y && apt-get install -y \
    vcftools 

# Install scripts
RUN mkdir /home/analyst
COPY *_vcf.sh /home/analyst/
RUN chmod a+x /home/analyst/*_vcf.sh
