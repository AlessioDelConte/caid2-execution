#!/bin/bash -i
#SBATCH --job-name=IDP-Fusion              # Job name
#SBATCH --ntasks=1                   # Run on a single CPU
#SBATCH --mem=4G                     # Requested memory
#SBATCH --output=IDP-Fusion_%A_%a.log         # Standard output and error log
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
SW_NAME="IDP-Fusion"

DB1="/db/hhblits/uniclust30_2018_08:/opt/$SW_NAME/db/"
DB2="/projects/CAID2/caid2_dataset:/hhblits"
DB3="/projects/CAID2/programs/$SW_LEADER/Pytorch_gpu:/opt/miniconda/envs/Pytorch_gpu"
DB4="/projects/CAID2/programs/$SW_LEADER/Pytorch_old:/opt/miniconda/envs/Pytorch_old"
IMG="/software/containers/caid/defs/$SW_NAME/$SW_NAME.sif"

singularity run --writable-tmpfs \
    -H "$PWD":/home \
    -B "$DB1" \
    -B "$DB2" \
    -B "$DB3" \
    -B "$DB4" \
    --writable-tmpfs \
    "$IMG" \
    -i input.fasta \
    -o outputs \
    --hhr /hhblits/hhr \
    --hhm /hhblits/hhm \
    --a3m /hhblits/a3m

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
