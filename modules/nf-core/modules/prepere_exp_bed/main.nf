
process PREPERE_EXP_BED {
  label 'process_low'
  tag "$condition, $nr_phenotype_pcs"
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
      container "${params.eqtl_container}"
      
  } else {
      container "${params.eqtl_docker}"
  }


  input:
    tuple(path(phenotype_pcs),val(condition),path(mapping_file),path(expression_file))
    each path(annotation_file)
    each path(genotype_pcs)

  output:
    tuple(val(condition),path("Expression_Data.bed.gz"),path('Covariates.tsv'), val(nr_phenotype_pcs), emit: exp_bed)

  script:
    nr_phenotype_pcs = phenotype_pcs.getSimpleName()
    if(params.sample_covariates==''){
      sample_covar =''
    }else{
      sample_covar ="--sample_covariates ${params.sample_covariates}"
    }
    if (params.TensorQTL.use_gt_dosage && params.TensorQTL.run) {
      pfile = "-pfile"
    }else{
    pfile = ""
        }
    """
      echo ${condition}
      prepere_bed.py --annotation_file ${annotation_file} --mapping_file ${mapping_file} --expression_file ${expression_file}
      prepere_covariates_file.py --genotype_pcs ${genotype_pcs} --phenotype_pcs ${phenotype_pcs} ${sample_covar} --sample_mapping ${mapping_file} ${pfile}
    """
}