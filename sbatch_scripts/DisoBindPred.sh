#!/bin/bash -i
#SBATCH --job-name=DisoBindPred              # Job name
#SBATCH --ntasks=16                   # Run on a single CPU
#SBATCH --mem=30G                     # Requested memory
#SBATCH --output=DisoBindPred_%A_%a.log         # Standard output and error log
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
    -B /projects/CAID2/caid2_dataset/a3m:/a3m \
    -B /db/mmseqs/:/mmseqs \
    -B /db/hhblits/uniclust30_2018_08:/uniclust30_2018_08 \
    /software/containers/caid/defs/DisoBindPred/DisoBindPred.sif \
    -i input.fasta -o outputs --a3m /a3m

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
