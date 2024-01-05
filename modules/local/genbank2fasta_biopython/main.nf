process GENBANK2FASTA_BIOPYTHON {

    label "process_low"
    tag( "${meta.id}" )
    container "gregorysprenger/biopython@sha256:77a50d5d901709923936af92a0b141d22867e3556ef4a99c7009a5e7e0101cc1"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.f*", includeInputs:true), emit: fasta_files
    path(".command.{out,err}")
    path("versions.yml")                             , emit: versions

    shell:
    '''
    source bash_functions.sh

    for file in !{input}; do
      if [[ "${file}" =~ .*.(gbff|gbf|gbk|gb)(.gz)? ]]; then
        msg "Converting ${file}.."
        export file

        python -c '
        import os
        import gzip
        from Bio import SeqIO

        genbank = os.environ["file"]
        fasta = genbank.split('.')[0]
        fasta = fasta + ".fna"

        if genbank.endswith('.gz'):
          ifh = gzip.open(genbank)
        else
          ifh = open(genbank)

        ofh = open(fasta, 'w')

        SeqIO.write(SeqIO.parse(ifh, "genbank"), ofh, "fasta")

        # Close files
        ifh.close()
        ofh.close()
        '

        # Clean up genbank files
        rm ${file}
      fi
    done

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
      python: $(python --version 2>&1 | awk '{print $2}')
      biopython: $(python -c 'import Bio; print(Bio.__version__)' 2>&1)
    END_VERSIONS
    '''
}
