#!/bin/bash -i 
#SBATCH --job-name=PredIDR              # Job name 
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=9G                     # Requested memory
#SBATCH --output=PredIDR_%A_%a.log         # Standard output and error log
#SBATCH --partition=long,ultra

echo "------------------------------------------------------------------------" 
echo "Job started on" $(date) 
echo "------------------------------------------------------------------------" 


if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    query=$(basename "$(ls /projects/CAID2/caid2_dataset/fastas | sed -n "${SLURM_ARRAY_TASK_ID}p")" .fasta)
fi


echo "QUERY: $query"
cd "$query" || exit 1

singularity run --cleanenv --writable-tmpfs -H "$PWD":/home \
 -B /local/blastdb/uniref50:/opt/SCRATCH-1D_1.2/pkg/PROFILpro_1.2/data/uniref50 /software/containers/caid/defs/PredIDR/PredIDR.sif -i input.fasta -o outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
