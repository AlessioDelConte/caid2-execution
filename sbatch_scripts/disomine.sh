#!/bin/bash -i
#SBATCH --job-name=disomine              # Job name
#SBATCH --ntasks=1                   # Run on a single CPU
#SBATCH --mem=4G                     # Requested memory
#SBATCH --output=disomine_%A_%a.log         # Standard output and error log
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

sif_path="/software/containers/caid/defs/disomine/disomine.sif"

singularity run --writable-tmpfs -H "$PWD":/home "$sif_path" -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" $(date)
echo "------------------------------------------------------------------------"
