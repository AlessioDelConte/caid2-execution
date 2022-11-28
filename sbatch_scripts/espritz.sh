#!/bin/bash -i
#SBATCH --job-name=espritz              # Job name
#SBATCH --ntasks=2                   # Run on a single CPU
#SBATCH --mem=7G                     # Requested memory
#SBATCH --output=espritz_%A_%a.log         # Standard output and error log
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

ESPRITZ="/software/containers/caid/defs/espritz/espritz.sif"

singularity run --writable-tmpfs --cleanenv -H "$PWD":/home $ESPRITZ -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
