#!/bin/bash -i
#SBATCH --job-name=DeepIDP-2L              # Job name
#SBATCH --ntasks=1                   # Run on a single CPU
#SBATCH --mem=12G                     # Requested memory
#SBATCH --output=DeepIDP-2L_%A_%a.log         # Standard output and error log
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

SW_LEADER="Liu"
SW_NAME="DeepIDP-2L"

DB1="/projects/CAID2/programs/$SW_LEADER/Pytorch_gpu:/opt/miniconda/envs/Pytorch_gpu"
IMG="/software/containers/caid/defs/$SW_NAME/$SW_NAME.sif"

singularity run \
    -H "$PWD":/home \
    -B "$DB1" \
    --writable-tmpfs \
    "$IMG" \
    -i input.fasta \
    -o outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" `date`
echo "------------------------------------------------------------------------"
