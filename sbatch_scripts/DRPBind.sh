#!/bin/bash -i
#SBATCH --job-name=DRPBind              # Job name
#SBATCH --ntasks=4                   # Run on a single CPU
#SBATCH --mem=10G                     # Requested memory
#SBATCH --output=DRPBind_%A_%a.log         # Standard output and error log
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

singularity run --writable-tmpfs -H "$PWD":/home \
    -B /projects/CAID2/caid2_dataset:/dataset \
    -B /home/aledc/.matlab/R2022a_licenses:/licence \
    -B /software/packages/MATLAB:/opt/matlab \
    --env MLM_LICENSE_FILE=/licence/license_ecate_40523914_R2022a.lic \
    /software/containers/caid/defs/DRPBind/DRPBind.sif \
    --pssm /dataset/pssm --hhm /dataset/hhm --hsa2 /dataset/hsa2 --hsb2 /dataset/hsb2 --spd3 /dataset/spd3 --input input.fasta --out_dir outputs

echo "------------------------------------------------------------------------"
echo "Job ended on" $(date)
echo "------------------------------------------------------------------------"
