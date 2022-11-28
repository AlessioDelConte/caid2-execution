#!/bin/bash -i
#SBATCH --job-name=flDPtr              # Job name
#SBATCH --ntasks=2                   # Run on a single CPU
#SBATCH --mem=4G                     # Requested memory
#SBATCH --output=flDPtr_%A_%a.log         # Standard output and error log
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


IMG_PATH="/software/containers/caid/defs/flDPtr/flDPtr.sif"

singularity run \
    -H "$PWD":/home \
    --writable-tmpfs \
    $IMG_PATH \
    -i input.fasta \
    -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
