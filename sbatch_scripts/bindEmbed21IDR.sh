#!/bin/bash -i
#SBATCH --job-name=bindEmbded21IDR              # Job name
#SBATCH --ntasks=4                   # Run on a single CPU
#SBATCH --mem=15G                     # Requested memory
#SBATCH --output=bindEmbded21IDR_%A_%a.log         # Standard output and error log
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
    -B /projects/CAID2/programs/Ilzhofer/models:/opt/models \
    /software/containers/caid/defs/bindEmbed21IDR/bindEmbed21IDR.sif \
    -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" $(date)
echo "------------------------------------------------------------------------"
