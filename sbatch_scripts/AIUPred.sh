#!/bin/bash -i 
#SBATCH --job-name=AIUPred              # Job name
#SBATCH --ntasks=2                   # Run on a single CPU 
#SBATCH --mem=7G                     # Requested memory
#SBATCH --output=AIUPred_%A_%a.log         # Standard output and error log
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

singularity run --cleanenv --writable-tmpfs -H "$PWD":/home /software/containers/caid/defs/AIUPred/AIUPred.sif -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
