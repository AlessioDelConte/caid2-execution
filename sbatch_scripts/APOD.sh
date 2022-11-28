#!/bin/bash -i
#SBATCH --job-name=APOD              # Job name
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=15G                     # Requested memory
#SBATCH --output=APOD_%A_%a.log         # Standard output and error log
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

APOD_NR="/projects/CAID2/programs/Kurgan/APOD_nr:/opt/APOD_20220524_CAID2/nr"
APOD_IMG="/software/containers/caid/defs/APOD/APOD.sif"

singularity run --writable-tmpfs --home "$PWD":/home -B "$APOD_NR" $APOD_IMG -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" `date`
echo "------------------------------------------------------------------------"
