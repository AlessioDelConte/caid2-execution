#!/bin/bash -i 
#SBATCH --job-name=PreDisorder              # Job name 
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=16G                     # Requested memory
#SBATCH --output=PreDisorder_%A_%a.log         # Standard output and error log
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

SW_LEADER="Cheng"
SW_NAME="PreDisorder"

DB="/local/blastdb/uniref90:/tmp/blastdb/uniref90"
IMG="/software/containers/caid/defs/$SW_NAME/$SW_NAME.sif"

singularity run \
    -H "$PWD":/home \
    -B "$DB" \
    --writable-tmpfs \
    "$IMG" \
    -i input.fasta \
    -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
