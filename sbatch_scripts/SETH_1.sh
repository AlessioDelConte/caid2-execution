#!/bin/bash -i
#SBATCH --job-name=SETH_1              # Job name
#SBATCH --ntasks=2                   # Run on a single CPU
#SBATCH --mem=24G                     # Requested memory
#SBATCH --output=SETH_1_%A_%a.log         # Standard output and error log
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

singularity run --cleanenv --writable-tmpfs -H "$PWD":/home -B /local/models/Ilzhofer/models:/opt/models /software/containers/caid/defs/SETH_1/SETH_1.sif -i input.fasta

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
