
process SUBSET_GENOTYPE {
    tag "${samplename}.${sample_subset_file}"
    label 'process_medium'
    publishDir "${params.outdir}/subset_genotype/", mode: "${params.copy_mode}", pattern: "${samplename}.${sample_subset_file}.subset.vcf.gz"
    
    
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "/software/hgi/containers/eqtl.img"
    } else {
        log.info 'change the docker container - this is not the right one'
        container "quay.io/biocontainers/multiqc:1.10.1--py_0"
    }


    input:
        path(donor_vcf)
        val(file__reduced_dims)


    output:
    
        path("${samplename}.subset.vcf.gz"), emit: samplename_subsetvcf

    script:
        file__reduced_dims = file__reduced_dims.join(",")
        samplename='subset'
        """
            tabix -p vcf ${donor_vcf} || echo 'not typical VCF'
            bcftools view ${donor_vcf} -s ${file__reduced_dims} -Oz -o ${samplename}.subset.vcf.gz
            rm ${donor_vcf}.tbi || echo 'not typical VCF'
        """
}
