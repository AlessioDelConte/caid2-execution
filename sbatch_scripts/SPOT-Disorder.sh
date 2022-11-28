#!/bin/bash -i
#SBATCH --job-name=SPOT-Disorder              # Job name
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=16G                     # Requested memory
#SBATCH --output=SPOT-Disorder_%A_%a.log         # Standard output and error log
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
    -B /db/blastdb/uniref90:/db/uniref90 \
    -B /projects/CAID2/caid2_dataset/pssm:/pssm \
    /software/containers/caid/defs/SPOT-Disorder/SPOT-Disorder.sif -i input.fasta -o outputs --pssm /pssm

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
