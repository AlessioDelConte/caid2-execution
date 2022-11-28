#!/bin/bash -i 
#SBATCH --job-name=SPOT-Disorder2              # Job name 
#SBATCH --ntasks=16                   # Run on a single CPU
#SBATCH --mem=30G                     # Requested memory
#SBATCH --output=SPOT-Disorder2_%A_%a.log         # Standard output and error log
#SBATCH --time=0-03:00:00             # Time limit hrs:min:sec
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

singularity run --writable-tmpfs -H "$PWD":/home \
           -B /db/blastdb/uniref90:/db/uniref90 \
           -B /db/hhblits:/db/hhblits \
           -B /projects/CAID/programs/zhou/SPOT1D_dat/dat:/opt/SPOT1D/dat \
           -B /projects/CAID/programs/zhou/SPOT-Contact-Helical-New_core/core:/opt/SPOT-Contact-Helical-New/core \
           -B /projects/CAID2/caid2_dataset:/dataset \
            /software/containers/caid/defs/SPOT-Disorder2/SPOT-Disorder2.sif \
            --pssm /dataset/pssm --hhm /dataset/hhm  --a3m /dataset/a3m --spd3 /dataset/spd3 --input input.fasta --out_dir outputs

echo "------------------------------------------------------------------------"
echo "Job finished on" $(date)
echo "------------------------------------------------------------------------"
