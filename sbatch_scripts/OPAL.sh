#!/bin/bash -i
#SBATCH --job-name=OPAL              # Job name
#SBATCH --ntasks=2                   # Run on a single CPU
#SBATCH --mem=7G                     # Requested memory
#SBATCH --output=OPAL_%A_%a.log         # Standard output and error log
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

singularity run --cleanenv --writable-tmpfs -H "$PWD":/home \
    -B /local/blastdb/gsponer_db:/opt/MCS1.03/db \
    -B /local/blastdb:/db/uniref90 \
    -B /projects/CAID2/caid2_dataset/pssm:/pssm \
    /software/containers/caid/defs/OPAL/OPAL.sif \
    --pssm /pssm

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
