#!/bin/bash -i
#SBATCH --job-name=Dispredict3              # Job name
#SBATCH --ntasks=4                   # Run on a single CPU
#SBATCH --mem=12G                     # Requested memory
#SBATCH --output=Dispredict3_%A_%a.log         # Standard output and error log
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

DISPREDICT3="/software/containers/caid/defs/Dispredict3/Dispredict3.sif"


singularity run --writable-tmpfs --cleanenv -H "$PWD":/home \
    -B /projects/CAID2/programs/Hoque/DisPredict3/models:/opt/models/ \
    $DISPREDICT3 \
    -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
