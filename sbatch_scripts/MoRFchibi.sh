#!/bin/bash -i
#SBATCH --job-name=MoRFchibi              # Job name
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=24G                     # Requested memory
#SBATCH --output=MoRFchibi_%A_%a.log         # Standard output and error log
#SBATCH --partition=long,mega

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
    -B /local/blastdb/gsponer_db:/opt/db \
    /software/containers/caid/defs/MoRFchibi/MoRFchibi.sif \
    -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
