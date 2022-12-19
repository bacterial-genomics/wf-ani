process SUMMARY {

    publishDir "${params.outpath}",
        mode: "${params.publish_dir_mode}",
        pattern: "ANI.Summary.tab"
    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${task.process}${filename}" }

    label "process_low"

    container "ubuntu:focal"

    input:
        path stats

    output:
        path "ANI.Summary.tab"
        path ".command.out"
        path ".command.err"
        path "versions.yml", emit: versions
        
    shell:
        '''
        source bash_functions.sh
        
        # Verify each file has data
        for f in !{stats}; do
            lines=$(grep -o '%'$'\t''[0-9]' ${f} | wc -l)
            if [ ${lines} -ne 6 ]; then
                echo "ERROR: ${f} lacks data to extract" >&2
                exit 1
            fi
        done

        # Summarize ANI values
        echo -n '' > ANI.Summary.tab
        for f in !{stats}; do
            PAIR=$(basename ${f} .stats.tab | sed 's/ani\\.//1')
            S1=${PAIR##*,}
            S2=${PAIR%%,*}

            # bidirectional values
            FRAG=$(grep ',' ${f} | cut -f 2 | cut -d '/' -f 1 | awk '{print $1/2}')
            MEAN=$(grep ',' ${f} | cut -f 3 | sed 's/%//1')
            STDEV=$(grep ',' ${f} | cut -f 4 | sed 's/%//1')

            # unidirectional values
            F1=$(grep -v -e ',' -e 'StDev' ${f} | sed -n 1p | cut -f 2 | cut -d '/' -f 1)
            M1=$(grep -v -e ',' -e 'StDev' ${f} | sed -n 1p | cut -f 3 | sed 's/%//1')
            D1=$(grep -v -e ',' -e 'StDev' ${f} | sed -n 1p | cut -f 4 | sed 's/%//1')

            F2=$(grep -v -e ',' -e 'StDev' ${f} | sed -n 2p | cut -f 2 | cut -d '/' -f 1)
            M2=$(grep -v -e ',' -e 'StDev' ${f} | sed -n 2p | cut -f 3 | sed 's/%//1')
            D2=$(grep -v -e ',' -e 'StDev' ${f} | sed -n 2p | cut -f 4 | sed 's/%//1')

            echo -e "$S1\t$S2\t$FRAG\t$MEAN\t$STDEV\t$F1\t$M1\t$D1\t$F2\t$M2\t$D2" >> ANI.Summary.tab
        done

        A='Sample\tSample\tFragments_Used_for_Bidirectional_Calc[#]\tBidirectional_ANI[%]\tBidirectional_StDev[%]'
        B='\tFragments_Used_for_Unidirectional_Calc[#]\tUnidirectional_ANI[%]\tUnidirectional_StDev[%]'
        sed -i "1i ${A}${B}${B}" ANI.Summary.tab
        
        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
            ubuntu: $(awk -F ' ' '{print $2,$3}' /etc/issue | tr -d '\\n')
        END_VERSIONS
        '''
}
