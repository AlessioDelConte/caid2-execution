#!/bin/bash -i
#SBATCH --job-name=DisoPred           # Job name
#SBATCH --ntasks=8                    # Run on a single CPU
#SBATCH --mem=24G                     # Requested memory
#SBATCH --output=DisoPred_%A_%a.log      # Standard output and error log
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
    -B /local/blastdb/uniprot20_2015_06:/db \
    /software/containers/caid/defs/DisoPred/DisoPred.sif \
    -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
