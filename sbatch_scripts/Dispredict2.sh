#!/bin/bash -i
#SBATCH --job-name=Dispredict2              # Job name
#SBATCH --ntasks=2                   # Run on a single CPU
#SBATCH --mem=8G                     # Requested memory
#SBATCH --output=Dispredict2_%A_%a.log         # Standard output and error log
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

DISPREDICT2="/software/containers/caid/defs/Dispredict2/Dispredict2.sif"

singularity run -H "$PWD":/home --writable-tmpfs \
    -B /projects/CAID/programs/hoque/Models:/opt/DisPredict_v2.0/Software/Models \
    -B /projects/CAID2/caid2_dataset/pssm:/pssm \
    $DISPREDICT2 \
    -i input.fasta -o outputs --pssm /pssm

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
