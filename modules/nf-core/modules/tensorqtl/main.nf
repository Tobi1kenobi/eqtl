
process TENSORQTL_CPU{
    label 'process_medium'
    tag {condition}
    
  // /lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/singularity_images/nf_tensorqtl_1.2.img
    publishDir  path: "${params.outdir}/TensorQTL_eQTLS/${condition}",
                overwrite: "true"
  

  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    // container "/lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/singularity_images/nf_tensorqtl_1.2.img"
    container "${params.eqtl_container}"
  } else {
    container "${params.eqtl_docker}"
  }


  input:
    tuple(val(condition),path(aggrnorm_counts_bed),path(genotype_pcs_tsv))
    // each path(genotype_pcs_tsv)
    each path(plink_files_prefix)

  output:
    // path("mapqtl_${oufnprfx}.cis_eqtl.tsv.gz"), emit: qtl_tsv
    // path("mapqtl_${oufnprfx}.cis_eqtl_dropped.tsv.gz"), emit: dropped_tsv
    // path("mapqtl_${oufnprfx}.cis_eqtl_qval.tsv.gz"), emit: qval_tsv
    path("Cis_eqtls.tsv"), emit: qtl_bin
    path("Cis_eqtls_qval.tsv"), emit: q_qtl_bin
    path('nom_output')

  script:
    """
      tensorqtl_analyse.py --plink_prefix_path ${plink_files_prefix}/plink_genotypes --expression_bed ${aggrnorm_counts_bed} --covariates_file ${genotype_pcs_tsv} -window ${params.windowSize} -nperm ${params.numberOfPermutations}
    """
}

process TENSORQTL_GPU{
    label 'gpu'
    
  // /lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/singularity_images/nf_tensorqtl_1.2.img
    publishDir  path: "${params.outdir}/TensorQTL_eQTLS/",
                overwrite: "true"

  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    // container "/lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/singularity_images/nf_tensorqtl_1.2.img"
    container "${params.eqtl_container}"
  } else {
    container "${params.eqtl_docker}"
  }

    input:
        tuple input_list
        each path(plink_files_prefix)

    output:
    path("*/Cis_eqtls.tsv"), emit: qtl_bin
    path("*/Cis_eqtls_qval.tsv"), emit: q_qtl_bin
    path('*/nom_output')

    script:
    """
    for input_tuple in input_list
    do
        mkdir ${input_tuple[0]}
        tensorqtl_analyse.py --plink_prefix_path ${params.plink_files_prefix}/plink_genotypes --expression_bed $${input_tuple[1]} --covariates_file ${input_tuple[2]} -window ${params.windowSize} -nperm ${params.numberOfPermutations} -o ${input_tuple[0]}
    done
    """
}

workflow TENSORQTL_eqtls{
    take:
        condition_bed
        plink_genotype
        
    main:
      if (params.utilise_gpu){
        TENSORQTL_GPU(
            condition_bed.buffer( size: 200, remainder: true ),
            plink_genotype)
     } else {
        TENSORQTL_CPU(
            condition_bed,
            plink_genotype)
      }
}