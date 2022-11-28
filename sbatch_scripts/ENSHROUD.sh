#!/bin/bash -i
#SBATCH --job-name=ENSHROUD              # Job name
#SBATCH --ntasks=6                   # Run on a single CPU
#SBATCH --mem=12G                     # Requested memory
#SBATCH --output=ENSHROUD_%A_%a.log         # Standard output and error log
#SBATCH --partition=long,ultra

echo "------------------------------------------------------------------------"
echo "Job started on" $(date)
echo "------------------------------------------------------------------------"

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
      query=$(basename "$(ls /projects/CAID2/caid2_dataset/fastas | sed -n "${SLURM_ARRAY_TASK_ID}p")" .fasta)
fi
echo "QUERY: $query"
cd $query || exit 1
rm -rf outputs timings.csv

singularity run --cleanenv --writable-tmpfs -H "$PWD":/home \
    -B /local/blastdb/uniprot20_2015_06/:/opt/ENSHROUD/uniprot20_2015_06/ \
    /software/containers/caid/defs/ENSHROUD/ENSHROUD.sif -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
