class: Workflow
cwlVersion: v1.1
label: merge_clean_missing_geno_vcf
doc: Tool to merge two VCFs with differing sample sets and from differing genotyping plaforms, after which the file is filtered to only extract a specified list of samples, and only passed variants that have at least 1 variant allele in the samples, and that pass a given missing genotypes filter (which caters for variants present in one data set but not another), to a new vcf.gz file
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

inputs:
- id: sample_list
  label: sample_list
  doc: |-
    A text file containing the list of samples with phenotypes to extract, one sample per line
  type: File
  sbg:fileTypes: .txt
  sbg:x: -190
  sbg:y: 16
- id: input_files
  label: Input files
  doc: Input files to be merged.
  type: File[]
  sbg:fileTypes: VCF, VCF.GZ
  sbg:x: -402.39886474609375
  sbg:y: -142.5

outputs:
- id: output_vcf
  label: output_vcf
  doc: VCF file with genotypes with large missingness, removed
  type: File?
  secondaryFiles:
  - pattern: .tbi
    required: true
  outputSource:
  - clean_geno_vcf/output_vcf
  sbg:x: 325.60113525390625
  sbg:y: -124.5

steps:
- id: bcftools_merge
  label: Bcftools Merge
  in:
  - id: input_files
    source:
    - input_files
  - id: output_type
    default: CompressedVCF
  run:
    class: CommandLineTool
    cwlVersion: sbg:draft-2
    label: Bcftools Merge
    $namespaces:
      sbg: https://sevenbridges.com

    requirements:
    - id: '#cwl-js-engine'
      class: ExpressionEngineRequirement
      requirements:
      - class: DockerRequirement
        dockerPull: rabix/js-engine
    - class: CreateFileRequirement
      fileDef:
      - fileContent: |-
          #!/bin/bash
          for f in *.vcf
          do
              if [ -e $f ]; then
                  bgzip -c -f "$f" > "${f}.gz" && /opt/bcftools-1.9/bcftools index -t -f "${f}.gz"
              fi
          done
          for f in *.vcf.gz
          do
              if [ -e $f ] && [ ! -e $f.tbi ]; then
                  /opt/bcftools-1.9/bcftools index -t -f "$f"
              fi
          done
        filename: gzip_vcf.sh

    inputs:
    - id: '#input_files'
      label: Input files
      type:
      - type: array
        items: File
      inputBinding:
        position: 60
        valueFrom:
          class: Expression
          engine: '#cwl-js-engine'
          script: |-
            {

            var cmd = "";
            var file;
            var file_array = [].concat($job.inputs.input_files)
            var array_length = file_array.length
              for (i = 0; i < array_length; i++) {
                var file_name = file_array[i].path.replace(/^.*[\\\/]/, '')
                if (file_name.split('.').pop() == "gz"){cmd += file_name + " ";}
                else {cmd += file_name + ".gz ";}
            }
               
              if (array_length == 1){
                return ""
              }
              else{return cmd}

            }
        separate: false
        sbg:cmdInclude: true
      description: Input files to be merged.
      sbg:category: File input
      sbg:fileTypes: VCF, VCF.GZ
      sbg:stageInput: copy
    - id: '#output_type'
      label: Output type
      type:
      - 'null'
      - name: output_type
        type: enum
        symbols:
        - CompressedBCF
        - UncompressedBCF
        - CompressedVCF
        - UncompressedVCF
      inputBinding:
        prefix: --output-type
        position: 24
        valueFrom:
          class: Expression
          engine: '#cwl-js-engine'
          script: |-
            {if($job.inputs.input_files.length != 1) {
              if($job.inputs.output_type === 'CompressedBCF') return 'b'
              if($job.inputs.output_type === 'UncompressedBCF') return 'u'
              if($job.inputs.output_type === 'CompressedVCF') return 'z'
              if($job.inputs.output_type === 'UncompressedVCF') return 'v'}
             else{return ""}
            }
        separate: true
        sbg:cmdInclude: true
      description: 'Compressed BCF (b), u: uncompressed BCF, z: compressed VCF, v:
        uncompressed VCF.'
      sbg:altPrefix: -O
      sbg:category: VCF output options
      sbg:toolDefaultValue: Uncompressed VCF
    - id: '#regions'
      label: Regions for processing
      type:
      - 'null'
      - type: array
        items: string
      inputBinding:
        prefix: --regions
        position: 17
        separate: true
        itemSeparator: ','
        sbg:cmdInclude: true
      description: Restrict to comma-separated list of regions.
      sbg:altPrefix: -r
      sbg:category: VCF input options
      sbg:stageInput:
    - id: '#regions_from_file'
      label: Processing regions from file
      type:
      - 'null'
      - File
      inputBinding:
        prefix: --regions-file
        position: 18
        separate: true
        sbg:cmdInclude: true
      description: Restrict to regions listed in a file.
      sbg:altPrefix: -R
      sbg:category: VCF input options
      sbg:fileTypes: BED
    - id: '#threads'
      label: Threads
      type:
      - 'null'
      - int
      inputBinding:
        prefix: --threads
        position: 0
        separate: true
        sbg:cmdInclude: true
      description: |-
        Number of output compression threads to use in addition to main thread. Only used when output type is CompressedBCF CompressedVCF.
      sbg:category: Execution
    - id: '#tag'
      label: Tagged GEN file
      type:
      - 'null'
      - string
      inputBinding:
        prefix: --tag
        position: 27
        separate: true
        sbg:cmdInclude: true
      description: 'Tag to take values for .gen file: GT,PL,GL,GP.'
      sbg:category: GEN/SAMPLE conversion
    - id: '#memory'
      label: Memory in MB
      type:
      - 'null'
      - int
      description: |-
        Memory in MB to use. Appropriate instance will be chosen based on this parameter.
      sbg:category: Execution
      sbg:toolDefaultValue: '1000'
    - id: '#cpu'
      label: Number of CPUs
      type:
      - 'null'
      - int
      description: |-
        Number of CPUs to use. Appropriate instance will be chosen based on this parameter.
      sbg:category: Execution
      sbg:stageInput:
      sbg:toolDefaultValue: '1'
    - id: '#force_samples'
      label: Force samples
      type:
      - 'null'
      - boolean
      inputBinding:
        prefix: --force-samples
        position: 1
        separate: true
        sbg:cmdInclude: true
      description: |-
        If the merged files contain duplicate samples names, proceed anyway. Duplicate sample names will be resolved by prepending index of the file as it appeared on the command line to the conflicting sample name.
      sbg:category: Configuration
      sbg:stageInput:
    - id: '#print_header'
      label: Print header
      type:
      - 'null'
      - boolean
      inputBinding:
        prefix: --print-header
        position: 2
        separate: true
        sbg:cmdInclude: true
      description: Print only the merged header and exit.
      sbg:category: Configuration
      sbg:stageInput:
    - id: '#use_header'
      label: Use provided header
      type:
      - 'null'
      - File
      inputBinding:
        prefix: --use-header
        position: 3
        separate: true
        sbg:cmdInclude: true
      description: Use the provided header.
      sbg:category: Configuration
      sbg:fileTypes: VCF
    - id: '#missing_genotypes'
      label: Assume missing genotypes
      type:
      - 'null'
      - boolean
      inputBinding:
        prefix: --missing-to-ref
        position: 4
        separate: true
        sbg:cmdInclude: true
      description: Assume genotypes at missing sites are 0/0.
      sbg:altPrefix: '-0'
      sbg:category: Configuration
      sbg:stageInput:
    - id: '#apply_filters'
      label: Apply filters
      type:
      - 'null'
      - type: array
        items: string
      inputBinding:
        prefix: --apply-filters
        position: 5
        separate: true
        itemSeparator: ','
        sbg:cmdInclude: true
      description: Require at least one of the listed FILTER strings (e.g. "PASS,.").
      sbg:altPrefix: -f
      sbg:category: Configuration
      sbg:stageInput:
    - id: '#filter_logic'
      label: Filters logic
      type:
      - 'null'
      - name: filter_logic
        type: enum
        symbols:
        - x
        - +
      inputBinding:
        prefix: --filter-logic
        position: 6
        separate: true
        sbg:cmdInclude: true
      description: remove filters if some input is PASS ("x"), or apply all filters
        ("+").
      sbg:altPrefix: -F
      sbg:category: Configuration
      sbg:stageInput:
      sbg:toolDefaultValue: +
    - id: '#gvcfs'
      label: Merge gVCF blocks
      type:
      - 'null'
      - File
      inputBinding:
        prefix: --gvcf
        position: 7
        separate: true
        sbg:cmdInclude: true
      description: |-
        Merge gVCF blocks, INFO/END tag is expected. If the reference fasta file FILE is not given and the dash (-) is given, unknown reference bases generated at gVCF block splits will be substituted with N’s. The --gvcf option uses the following default INFO rules: -i QS:sum,MinDP:min,I16:sum,IDV:max,IMF:max.
      sbg:altPrefix: -g
      sbg:category: Configuration
      sbg:fileTypes: FASTA
    - id: '#info_rules'
      label: Info rules
      type:
      - 'null'
      - type: array
        items: string
      inputBinding:
        prefix: --info-rules
        position: 8
        separate: true
        itemSeparator: ','
        sbg:cmdInclude: true
      description: |-
        Rules for merging INFO fields (scalars or vectors) or - to disable the default rules. METHOD is one of sum, avg, min, max, join. Default is DP:sum,DP4:sum if these fields exist in the input files. Fields with no specified rule will take the value from the first input file. The merged QUAL value is currently set to the maximum. This behaviour is not user controllable at the moment.
      sbg:altPrefix: -i
      sbg:category: Configuration
      sbg:stageInput:
    - id: '#merge'
      label: Merge option
      type:
      - 'null'
      - name: merge
        type: enum
        symbols:
        - snps
        - indels
        - both
        - all
        - none
        - id
      inputBinding:
        prefix: --merge
        position: 9
        separate: true
        sbg:cmdInclude: true
      description: |-
        The option controls what types of multiallelic records can be created: none - no new multiallelics, output multiple records instead; snps - allow multiallelic SNP records; indels - allow multiallelic INDEL records; both - both SNP and INDEL records can be multiallelic; all - SNP records can be merged with INDEL records; id - merge by id.
      sbg:altPrefix: -m
      sbg:category: Configuration
      sbg:toolDefaultValue: both
    - id: '#no_version'
      label: No version
      type:
      - 'null'
      - boolean
      inputBinding:
        prefix: --no-version
        position: 11
        separate: true
        sbg:cmdInclude: true
      description: Do not append version and command line to the header.
      sbg:category: Configuration
      sbg:stageInput:
    - id: '#output_name'
      label: Output name
      type:
      - 'null'
      - string
      description: Output name.
      sbg:category: Execution

    outputs:
    - id: '#output_file'
      label: Merged VCF file
      type:
      - 'null'
      - File
      outputBinding:
        secondaryFiles:
        - .tbi
        glob:
          class: Expression
          engine: '#cwl-js-engine'
          script: |-
            {
              file_array = [].concat($job.inputs.input_files)
              fname = file_array[0].path.replace(/^.*[\\\/]/, '')
              filename = file_array[0].path.replace(/^.*[\\\/]/, '')
              if(fname.split('.').pop().toLowerCase() == 'gz'){ 
                fname = file_array[0].path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "")
              }
              
              if($job.inputs.output_name){
                out = $job.inputs.output_name
                if ($job.inputs.output_type == 'UncompressedVCF'){out += ".merged.vcf"}
                else if ($job.inputs.output_type == 'CompressedVCF'){out += ".merged.vcf.gz"}
                else if ($job.inputs.output_type == 'UncompressedBCF'){out += ".merged.bcf"}
                else if ($job.inputs.output_type == 'CompressedBCF'){out += ".merged.bcf.gz"}
                else {out += ".merged.vcf"}
              }
              else if ($job.inputs.output_type == 'UncompressedVCF'){
                fname_list = fname.split('.')
                fname_list.pop() // Remove extension
                out = fname_list.join('.') + '.merged' + '.vcf'
              }
              else if ($job.inputs.output_type == 'CompressedVCF'){
                fname_list = fname.split('.')
                fname_list.pop() // Remove extension
                out = fname_list.join('.') + '.merged' + '.vcf.gz'
              }
              else if ($job.inputs.output_type == 'UncompressedBCF'){
                fname_list = fname.split('.')
                fname_list.pop() // Remove extension
                out = fname_list.join('.') + '.merged' + '.bcf'
              }
              else if ($job.inputs.output_type == 'CompressedBCF'){
                fname_list = fname.split('.')
                fname_list.pop() // Remove extension
                out = fname_list.join('.') + '.merged' + '.bcf.gz'
              }
              else out = fname.split('.vcf')[0] + '.merged.vcf'
               
              if($job.inputs.input_files.length == 1){return filename}
              else{return out}
            }
        sbg:inheritMetadataFrom: '#input_files'
      description: Merged multiple VCF file from non-overlapping sample sets.
      sbg:fileTypes: BCF, VCF, BCF.GZ, VCF.GZ

    baseCommand:
    - class: Expression
      engine: '#cwl-js-engine'
      script: |-
        {
            var file_array = [].concat($job.inputs.input_files)
         if (file_array.length == 1){return "echo pass"}
         else{return "bash gzip_vcf.sh && bcftools merge "}

        }
    arguments:
    - prefix: --output
      position: 0
      valueFrom:
        class: Expression
        engine: '#cwl-js-engine'
        script: |-
          {
            file_array = [].concat($job.inputs.input_files)
            fname = file_array[0].path.replace(/^.*[\\\/]/, '')
            filename = file_array[0].path.replace(/^.*[\\\/]/, '')
            if(fname.split('.').pop().toLowerCase() == 'gz'){ 
              fname = file_array[0].path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "")
            }
            
            if($job.inputs.output_name){
              out = $job.inputs.output_name
              if ($job.inputs.output_type == 'UncompressedVCF'){out += ".merged.vcf"}
              else if ($job.inputs.output_type == 'CompressedVCF'){out += ".merged.vcf.gz"}
              else if ($job.inputs.output_type == 'UncompressedBCF'){out += ".merged.bcf"}
              else if ($job.inputs.output_type == 'CompressedBCF'){out += ".merged.bcf.gz"}
              else {out += ".merged.vcf"}
            }
            else if ($job.inputs.output_type == 'UncompressedVCF'){
              fname_list = fname.split('.')
              fname_list.pop() // Remove extension
              out = fname_list.join('.') + '.merged' + '.vcf'
            }
            else if ($job.inputs.output_type == 'CompressedVCF'){
              fname_list = fname.split('.')
              fname_list.pop() // Remove extension
              out = fname_list.join('.') + '.merged' + '.vcf.gz'
            }
            else if ($job.inputs.output_type == 'UncompressedBCF'){
              fname_list = fname.split('.')
              fname_list.pop() // Remove extension
              out = fname_list.join('.') + '.merged' + '.bcf'
            }
            else if ($job.inputs.output_type == 'CompressedBCF'){
              fname_list = fname.split('.')
              fname_list.pop() // Remove extension
              out = fname_list.join('.') + '.merged' + '.bcf.gz'
            }
            else out = fname.split('.vcf')[0] + '.merged.vcf'
             
            if($job.inputs.input_files.length == 1){return filename}
            else{return out}
          }
      separate: true

    hints:
    - class: sbg:CPURequirement
      value:
        class: Expression
        engine: '#cwl-js-engine'
        script: "{\n  if($job.inputs.cpu){\n    return $job.inputs.cpu}\n  else{\n\
          \  \treturn 1}\n}"
    - class: sbg:MemRequirement
      value:
        class: Expression
        engine: '#cwl-js-engine'
        script: |-
          {
            if($job.inputs.memory){
              return $job.inputs.memory}
            else{
            	return 1000}
          }
    - class: DockerRequirement
      dockerPull: images.sbgenomics.com/luka_topalovic/bcftools:1.9
      dockerImageId: 21caaa02f72e
    id: midaya/fhs-imputed/bcftools-merge/0
    abg:revisionNotes:
    description: |-
      **BCFtools Merge**: Merge multiple VCF/BCF files from non-overlapping sample sets to create one multi-sample file. 

      **BCFtools** is a set of utilities that manipulate variant calls in the Variant Call Format (VCF) and its binary counterpart BCF. All commands work transparently with both VCFs and BCFs, both uncompressed and BGZF-compressed. Most commands accept VCF, bgzipped VCF and BCF with filetype detected automatically even when streaming from a pipe. Indexed VCF and BCF will work in all situations. Un-indexed VCF and BCF and streams will work in most, but not all situations. In general, whenever multiple VCFs are read simultaneously, they must be indexed and therefore also compressed. [1]

      A list of **all inputs and parameters** with corresponding descriptions can be found at the bottom of the page.

      ### Common Use Cases

      For example, when merging file A.vcf.gz containing samples S1, S2 and S3 and file B.vcf.gz containing samples S3 and S4, the output file will contain four samples named S1, S2, S3 and S4.
      ```
      $bcftools merge A.vcf.gz B.vcf.gz
      ```

      Merge two VCF files with different samples for SNPs only, using the **Merge** (`--merge`) option.
      ```
      $bcftools merge --merge snps A.vcf.gz B.vcf.gz
      ```

      Merge two VCF files (with one sample identical in both files) for all records with **Force samples** (`--force-samples`) option.
      ```
      $bcftools merge --merge all --force_samples A.vcf.gz B.vcf.gz
      ```

      ### Changes Introduced by Seven Bridges

      * BCFtools works in all cases with gzipped and indexed VCF/BCF files. To be sure BCFtools works in all cases, we added subsequent `bgzip` and `index` commands if a VCF file is provided on input. If VCF.GZ is given on input only indexing will be done. Output type can still be chosen with the `output type` command.
      * If only file file is provided on input, since there is no merging, that file will be output of the tool.

      ### Common Issues and Important Notes

      * Note that it is the responsibility of the user to ensure that the sample names are unique across all files. If they are not, the program will exit with an error unless the **force samples** (`--force-samples`) option is used. The sample names can also be given explicitly using the print header (`--print-header`) option.

      * Note that only records from different files can be merged, but not from the same file. For "vertical" merge take a look at BCFtools concat. At least two files must be given to merge.

      ### Performance Benchmarking

      It took 4 minutes to execute this tool on AWS c4.2xlarge instance using inputs of 12.4 MB and 56 KB. The price is negligible ($0.02).

      *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*

      ### References
      [1 - BCFtools page](https://samtools.github.io/bcftools/bcftools.html)
    sbg:appVersion:
    - sbg:draft-2
    sbg:categories:
    - VCF-Processing
    sbg:cmdPreview: echo pass --output input_files-1.vcf
    sbg:content_hash: a772d96a4bac2c172383e646f0417fc033e7df09787fd9caed191a34dd4cc32c7
    sbg:contributors:
    - midaya
    sbg:copyOf: admin/sbg-public-data/bcftools-merge/4
    sbg:createdBy: midaya
    sbg:createdOn: 1603148116
    sbg:id: midaya/fhs-imputed/bcftools-merge/0
    sbg:image_url:
    sbg:job:
      allocatedResources:
        cpu: 8
        mem: 10000
      inputs:
        apply_filters:
        cpu:
        filter_logic:
        force_samples: false
        info_rules:
        input_files:
        - class: File
          secondaryFiles: []
          path: /path/to/input_files-1.vcf
          size: 0
        memory:
        merge: snps
        missing_genotypes: false
        no_version: false
        output_name: ''
        output_type: CompressedVCF
        print_header: false
        regions:
        regions_from_file:
          class: File
          secondaryFiles: []
          path:
          size: 0
        tag: ''
        threads:
    sbg:latestRevision: 0
    sbg:license: MIT License
    sbg:links:
    - id: http://samtools.github.io/bcftools/
      label: Homepage
    - id: https://github.com/samtools/bcftools
      label: Source code
    - id: https://github.com/samtools/bcftools/wiki
      label: Wiki
    - id: https://github.com/samtools/bcftools/archive/1.9.zip
      label: Download
    sbg:modifiedBy: midaya
    sbg:modifiedOn: 1603148116
    sbg:project: midaya/fhs-imputed
    sbg:projectName: FHS
    sbg:publisher: sbg
    sbg:revision: 0
    sbg:revisionNotes: Copy of admin/sbg-public-data/bcftools-merge/4
    sbg:revisionsInfo:
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1603148116
      sbg:revision: 0
      sbg:revisionNotes: Copy of admin/sbg-public-data/bcftools-merge/4
    sbg:sbgMaintained: false
    sbg:toolAuthor: Petr Danecek, Shane McCarthy, John Marshall
    sbg:toolkit: bcftools
    sbg:toolkitVersion: '1.9'
    sbg:validationErrors: []
  out:
  - id: output_file
  sbg:x: -281
  sbg:y: -144
- id: clean_vcf
  label: clean_vcf
  in:
  - id: vcf_gz_file
    source: bcftools_merge/output_file
  - id: sample_list
    source: sample_list
  run:
    class: CommandLineTool
    cwlVersion: v1.1
    label: clean_vcf
    $namespaces:
      sbg: https://sevenbridges.com

    requirements:
    - class: ShellCommandRequirement
    - class: DockerRequirement
      dockerPull: quay.io/mdaya/clean_vcf:1.0

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
        Output VCF file containing variants that have a PASS filter and have at least 1 variant allele
      type: File
      secondaryFiles:
      - pattern: .tbi
        required: true
      outputBinding:
        glob: '*_clean.vcf.gz'
      sbg:fileTypes: .vcf.gz

    baseCommand:
    - bash /home/analyst/clean_vcf.sh
    id: midaya/jaas/clean-vcf/3
    sbg:appVersion:
    - v1.1
    sbg:content_hash: ab2fc58c506209842ed94dbac62d8257d12d5faf78bbb196caac58a627d0ca9a6
    sbg:contributors:
    - midaya
    sbg:createdBy: midaya
    sbg:createdOn: 1605918007
    sbg:id: midaya/jaas/clean-vcf/3
    sbg:image_url:
    sbg:latestRevision: 3
    sbg:modifiedBy: midaya
    sbg:modifiedOn: 1605963819
    sbg:project: midaya/jaas
    sbg:projectName: JAAS
    sbg:publisher: sbg
    sbg:revision: 3
    sbg:revisionNotes: Changed docker version
    sbg:revisionsInfo:
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605918007
      sbg:revision: 0
      sbg:revisionNotes: Copy of midaya/fhs-imputed/clean-vcf/9
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605963781
      sbg:revision: 1
      sbg:revisionNotes: Fixed output file
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605963798
      sbg:revision: 2
      sbg:revisionNotes: Changed docker version
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605963819
      sbg:revision: 3
      sbg:revisionNotes: Changed docker version
    sbg:sbgMaintained: false
    sbg:validationErrors: []
  out:
  - id: out_vcf_gz_file
  sbg:x: -65
  sbg:y: -130
- id: clean_geno_vcf
  label: clean_geno_vcf
  in:
  - id: in_gz_vcf
    source: clean_vcf/out_vcf_gz_file
  run:
    class: CommandLineTool
    cwlVersion: v1.1
    label: clean_geno_vcf
    $namespaces:
      sbg: https://sevenbridges.com

    requirements:
    - class: ShellCommandRequirement
    - class: DockerRequirement
      dockerPull: quay.io/mdaya/clean_vcf:1.0

    inputs:
    - id: in_gz_vcf
      label: in_gz_vcf
      doc: Input VCF from which variants with large missingness should be removed
      type: File
      secondaryFiles:
      - pattern: .tbi
        required: true
      inputBinding:
        position: 1
        shellQuote: false
      sbg:fileTypes: .vcf.gz
    - id: max_missing
      label: max_missing
      doc: --max-missing flag in VCFTools
      type: float?
      default: 0.99
      inputBinding:
        position: 2
        shellQuote: false
      sbg:toolDefaultValue: '0.99'

    outputs:
    - id: output_vcf
      label: output_vcf
      doc: VCF file with genotypes with large missingness, removed
      type: File?
      secondaryFiles:
      - pattern: .tbi
        required: true
      outputBinding:
        glob: '*_missing_geno.vcf.gz'

    baseCommand:
    - bash /home/analyst/clean_missing_geno_vcf.sh
    id: midaya/gwas-adrn-nontopmed-white/clean-geno-vcf/4
    sbg:appVersion:
    - v1.1
    sbg:content_hash: a108e5fcc19b9ee8c4672f4fbacfd3dcb00289ceadcc7fefe9194acb7dfc10a92
    sbg:contributors:
    - midaya
    sbg:createdBy: midaya
    sbg:createdOn: 1605905519
    sbg:id: midaya/gwas-adrn-nontopmed-white/clean-geno-vcf/4
    sbg:image_url:
    sbg:latestRevision: 4
    sbg:modifiedBy: midaya
    sbg:modifiedOn: 1605968374
    sbg:project: midaya/gwas-adrn-nontopmed-white
    sbg:projectName: GWAS_ADRN_nonTOPMed_white
    sbg:publisher: sbg
    sbg:revision: 4
    sbg:revisionNotes: changed file type
    sbg:revisionsInfo:
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605905519
      sbg:revision: 0
      sbg:revisionNotes:
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605906141
      sbg:revision: 1
      sbg:revisionNotes: Initial version
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605916049
      sbg:revision: 2
      sbg:revisionNotes: ''
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605963894
      sbg:revision: 3
      sbg:revisionNotes: Fixed output port
    - sbg:modifiedBy: midaya
      sbg:modifiedOn: 1605968374
      sbg:revision: 4
      sbg:revisionNotes: changed file type
    sbg:sbgMaintained: false
    sbg:validationErrors: []
  out:
  - id: output_vcf
  sbg:x: 131
  sbg:y: -127
id: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/midaya/gwas-adrn-nontopmed-white/merge-clean-missing-geno-vcf/2/raw/
sbg:appVersion:
- v1.1
- sbg:draft-2
sbg:content_hash: ac84b097316ae20d5353ac66640a655b89429dfe6afe7536e366b97cb892d09de
sbg:contributors:
- midaya
sbg:createdBy: midaya
sbg:createdOn: 1605966493
sbg:id: midaya/gwas-adrn-nontopmed-white/merge-clean-missing-geno-vcf/2
sbg:image_url: |-
  https://platform.sb.biodatacatalyst.nhlbi.nih.gov/ns/brood/images/midaya/gwas-adrn-nontopmed-white/merge-clean-missing-geno-vcf/2.png
sbg:latestRevision: 2
sbg:modifiedBy: midaya
sbg:modifiedOn: 1605968698
sbg:project: midaya/gwas-adrn-nontopmed-white
sbg:projectName: GWAS_ADRN_nonTOPMed_white
sbg:publisher: sbg
sbg:revision: 2
sbg:revisionNotes: Changed output type to compressed vcf
sbg:revisionsInfo:
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1605966493
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1605966756
  sbg:revision: 1
  sbg:revisionNotes: Initial version
- sbg:modifiedBy: midaya
  sbg:modifiedOn: 1605968698
  sbg:revision: 2
  sbg:revisionNotes: Changed output type to compressed vcf
sbg:sbgMaintained: false
sbg:validationErrors: []
