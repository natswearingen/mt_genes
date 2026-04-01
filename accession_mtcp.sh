#!/bin/bash

# Output folder
OUTDIR="mt_gene_fastas"
mkdir -p "$OUTDIR"

# Target genes
GENES=("COX1" "COX2" "COX3" "ND1" "ND2" "ND3" "ND4" "ND4L" "ND5" "CYTB")

# Initialize empty FASTA files for each gene
for gene in "${GENES[@]}"; do
    > "$OUTDIR/${gene}.fasta"
done

awk -v outdir="$OUTDIR" '
BEGIN {
    IGNORECASE=1
}

# Function to get gene name from header
function extract_gene(header) {
    if (match(header, /\[gene=([A-Za-z0-9]+)\]/, arr)) {
        gene = toupper(arr[1])
        if (gene == "CTYB") gene = "CYTB"
        return gene
    }
    return ""
}

# Function to get accession number from header
function extract_accession(header) {
    if (match(header, /lcl\|([^ ]+)/, arr)) {
        split(arr[1], a, "_cds")  # remove trailing "_cds..." part
        return a[1]
    }
    return ""
}

/^>/ {
    # Print previous record if it exists
    if (seq != "" && gene != "" && accession != "") {
        outfile = outdir "/" gene ".fasta"
        print ">" accession "_" gene >> outfile
        print seq >> outfile
    }

    # Reset for new record
    header = $0
    seq = ""
    gene = extract_gene(header)
    accession = extract_accession(header)

    next
}

{
    seq = seq $0
}

END {
    # Print the last record
    if (seq != "" && gene != "" && accession != "") {
        outfile = outdir "/" gene ".fasta"
        print ">" accession "_" gene >> outfile
        print seq >> outfile
    }
}
' *.fasta *.fa *.txt

echo "Done! FASTA files with accession-only headers are in $OUTDIR"
