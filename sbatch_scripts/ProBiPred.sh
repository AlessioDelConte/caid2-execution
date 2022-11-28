#!/bin/bash -i
#SBATCH --job-name=ProBiPred              # Job name
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=16G                     # Requested memory
#SBATCH --output=ProBiPred_%A_%a.log         # Standard output and error log
#SBATCH --partition=long,ultra,mega

echo "------------------------------------------------------------------------"
echo "Job started on" $(date)
echo "------------------------------------------------------------------------"

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
      query=$(basename "$(ls /projects/CAID2/caid2_dataset/fastas | sed -n "${SLURM_ARRAY_TASK_ID}p")" .fasta)
fi
echo "QUERY: $query"
cd $query || exit 1
rm -rf outputs timings.csv

PROBIPRED_SIF="/software/containers/caid/defs/ProBiPred/ProBiPred.sif"
PROBIPRED_MODELS="/projects/CAID2/programs/Krautheimer/models:/opt/ProBiPred_CAID/models"

singularity run --writable-tmpfs -H "$PWD":/home -B $PROBIPRED_MODELS $PROBIPRED_SIF -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
