#!/bin/bash -i
#SBATCH --job-name=DFLpred              # Job name
#SBATCH --ntasks=1                   # Run on a single CPU
#SBATCH --mem=5G                     # Requested memory
#SBATCH --output=DFLpred_%A_%a.log         # Standard output and error log
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

SW_LEADER="kurgan"
SW_NAME="DFLpred"

IMG="/software/containers/caid/defs/$SW_NAME/$SW_NAME.sif"

singularity run \
    -H "$PWD":/home \
    --writable-tmpfs \
    "$IMG" \
    -i input.fasta \
    -o outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" `date`
echo "------------------------------------------------------------------------"


