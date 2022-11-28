#!/bin/bash -i
#SBATCH --job-name=AUCpred              # Job name
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=7G                     # Requested memory
#SBATCH --output=AUCpred_%A_%a.log         # Standard output and error log
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

AUCpred_DB="/local/blastdb:/opt/AUCpred/databases"
AUCpred_IMG="/software/containers/caid/defs/AUCpred/AUCpred.sif"

singularity run \
    -H "$PWD":/home \
    -B "$AUCpred_DB" \
    --writable-tmpfs \
    "$AUCpred_IMG" \
    -i input.fasta \
    -o outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" `date`
echo "------------------------------------------------------------------------"
