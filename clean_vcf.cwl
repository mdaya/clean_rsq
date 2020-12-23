class: CommandLineTool
cwlVersion: v1.1
label: clean_vcf
doc: Tool to extract a specified list of samples from a vcf, and only passed variants that have at least 1 variant allele in the samples, to a new vcf.gz file
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: quay.io/mdaya/clean_vcf:0.10

inputs:
- id: vcf_gz_file
  label: vcf_gz_file
  doc: |-
    A vcf.gz file from which variants with PASS filter and the given list of samples with phenotypes should be extracted
  type: File
  secondaryFiles:
  - pattern: .tbi
    required: false
  inputBinding:
    position: 1
    shellQuote: false
  sbg:fileTypes: .vcf.gz
- id: sample_list
  label: sample_list
  doc: |-
    A text file containing the list of samples with phenotypes to extract, one sample per line
  type: File
  inputBinding:
    position: 2
    shellQuote: false
  sbg:fileTypes: .txt

outputs:
- id: out_vcf_gz_file
  label: out_vcf_gz_file
  doc: |-
    Output VCF file containing only VCF with genotypes with that passes the missing filter
  type: File
  secondaryFiles:
  - pattern: .tbi
    required: true
  outputBinding:
    glob: '*_clean_missing_geno.vcf.gz'
  sbg:fileTypes: .vcf.gz

baseCommand:
- bash /home/analyst/clean_vcf.sh
id: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/midaya/fhs-imputed/clean-vcf/9/raw/
sbg:appVersion:
- v1.1
sbg:content_hash: a8ff64dcf6510872b912e2e558253ae6a849ae48af2372ea9aaac8bf9e9e453fd
sbg:contributors:
- midaya
sbg:createdBy: midaya
sbg:createdOn: 1602849696
sbg:id: midaya/fhs-imputed/clean-vcf/9
sbg:image_url:
sbg:latestRevision: 9
sbg:modifiedBy: midaya
sbg:modifiedOn: 1605906051
sbg:project: midaya/fhs-imputed
sbg:projectName: FHS
sbg:publisher: sbg
sbg:revision: 9
sbg:revisionNotes: Initial version
sbg:revisionsInfo:
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1602849696
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1602850113
  sbg:revision: 1
  sbg:revisionNotes: Initial version
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1602850487
  sbg:revision: 2
  sbg:revisionNotes: Changed .tbi index file to optional
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1603141547
  sbg:revision: 3
  sbg:revisionNotes: Changed to use bcftools
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1603143226
  sbg:revision: 4
  sbg:revisionNotes: Added --force-samples so that extract does not fail for non-existing
    samples
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1603148673
  sbg:revision: 5
  sbg:revisionNotes: Changed docker version to 0.5
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1603157418
  sbg:revision: 6
  sbg:revisionNotes: Changed docker version to 0.6
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1603734817
  sbg:revision: 7
  sbg:revisionNotes: Changed docker version to 0.9
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1603811355
  sbg:revision: 8
  sbg:revisionNotes: Changed version to 0.10
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1605906051
  sbg:revision: 9
  sbg:revisionNotes: Initial version
sbg:sbgMaintained: false
sbg:validationErrors: []
