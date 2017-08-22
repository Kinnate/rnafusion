#!/usr/bin/env nextflow
/*
vim: syntax=groovy
-*- mode: groovy;-*-
========================================================================================
               N G I - R N A S E Q    F U S I O N D E T E C T
========================================================================================
 New RNA-Seq Best Practice Analysis Pipeline. Started May 2017.
 #### Homepage / Documentation
 https://github.com/SciLifeLab/NGI-RNAseq-Fusiondetect
 #### Authors
 Rickard Hammarén @Hammarn  <rickard.hammaren@scilifelab.se>
*/

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Pipeline version
version = '0.1'

// Configurable variables - same as NGI-RNAseq for now
params.project = false
params.genome = false
params.forward_stranded = false
params.reverse_stranded = false
params.unstranded = false
params.star_index = params.genome ? params.genomes[ params.genome ].star ?: false : false
params.fasta = params.genome ? params.genomes[ params.genome ].fasta ?: false : false
params.gtf = params.genome ? params.genomes[ params.genome ].gtf ?: false : false
params.bed12 = params.genome ? params.genomes[ params.genome ].bed12 ?: false : false
params.hisat2_index = params.genome ? params.genomes[ params.genome ].hisat2 ?: false : false
params.multiqc_config = "$baseDir/conf/multiqc_config.yaml"
params.splicesites = false
params.download_hisat2index = false
params.download_fasta = false
params.download_gtf = false
params.hisatBuildMemory = 200 // Required amount of memory in GB to build HISAT2 index with splice sites
params.saveReference = false
params.saveTrimmed = false
params.saveAlignedIntermediates = false
params.reads = "data/*{1,2}.fastq.gz"
params.outdir = './results'
params.email = false
params.STAR = false
params.FUSIONCATCHER = true
Channel
    .fromFilePairs( params.reads, size:  2 )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}" }
    .into { read_files_STAR-fusion; fusionInspector-reads; fusioncatcer-reads}



/*
 * STEP 1 - STAR-Fusion 
 */

process STAR_fusion{
        
    input:
    set val (name), file(read1), file(read2) from read_files_STAR-fusion   

    output:
    '*final.abridged*'
    'star-fusion.fusion_candidates.final.abridged.FFPM' into fusion_candidates
    
    when: STAR == true 
    
    """
    STAR-Fusion --genome_lib_dir ${star_fusion_refrence} -_left_fq ${read1} --right_fq ${read2}  --output_dir ${star-fusion_outdir}
    """
}


/*
 *  -  FusionInspector
 */

process FusionInspector{

    input:
    set val (name), file(read1), file(read2) from fusionInspector-reads 
    file fusion_candidates 
    
    output:

    when: STAR == true 
    
    """
    FusionInspector --fusions ${fusion_candidates} \
                --genome_lib ${STAR_fusion_refrence} \
                --left_fq ${read1} --right_fq ${read2} \
                --out_dir ${my_FusionInspector_outdir} \
                --out_prefix finspector \
                --prep_for_IGV       
    """
}



/*
 * Fusion Catcher
*/
    // Requires raw untrimmed files. Should not be merged!

process FusionCatcher{

    input:
    set val (name), file(read1), file(read2) from fusioncatcer-reads
    output:
    '*.txt' 
    when: FUSIONCATCHER == true
    
    """
    fusioncatcher \
    -d ${fusioncatcher_data_dir} \
    -i  ${read1},${read2} \
    --threads ${task.cpus} \
    --${SENSITIVITY} \
    -o ${SAMPLE_NAME}/
    """

}









