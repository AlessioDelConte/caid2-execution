#!/bin/bash -i
#SBATCH --job-name=CLIP              # Job name
#SBATCH --ntasks=8                   # Run on a single CPU
#SBATCH --mem=10G                     # Requested memory
#SBATCH --output=CLIP_%A_%a.log         # Standard output and error log
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

SW_LEADER="Kurgan"
SW_NAME="CLIP"
SW_VERSION="_20220530"
UNICLUST_VERSION="uniclust30_2017_10"

A3M_DIR="/projects/CAID2/caid2_dataset/a3m:/a3m"
DB1="/local/blastdb/$UNICLUST_VERSION:/opt/$SW_NAME""$SW_VERSION""_CAID2/db/hhblits/"
DB2="/local/blastdb/clip_db:/opt/$SW_NAME""$SW_VERSION""_CAID2/db/blast/db/"
IMG="/software/containers/caid/defs/$SW_NAME/$SW_NAME.sif"

singularity run --writable-tmpfs \
    -H "$PWD":/home \
    -B "$DB1" \
    -B "$DB2" \
    -B "$A3M_DIR" \
    --writable-tmpfs \
    "$IMG" \
    -i input.fasta \
    -o outputs \
    --a3m /a3m


echo "------------------------------------------------------------------------"
echo "Job ended on" `date`
echo "------------------------------------------------------------------------"
