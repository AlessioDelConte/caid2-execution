#!/bin/bash -i
#SBATCH --job-name=DISOPRED3              # Job name
#SBATCH --ntasks=24                   # Run on a single CPU
#SBATCH --mem=44G                     # Requested memory
#SBATCH --output=DISOPRED3_%A_%a.log         # Standard output and error log
#SBATCH --partition=ultra

echo "------------------------------------------------------------------------"
echo "Job started on" $(date)
echo "------------------------------------------------------------------------"

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
      query=$(basename "$(ls /projects/CAID2/caid2_dataset/fastas | sed -n "${SLURM_ARRAY_TASK_ID}p")" .fasta)
fi
echo "QUERY: $query"
cd $query || exit 1
rm -rf outputs timings.csv

singularity run --cleanenv --writable-tmpfs -H "$PWD":/home -B /local/blastdb/uniref90/:/data /software/containers/caid/defs/DISOPRED3/DISOPRED3.sif -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
