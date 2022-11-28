import argparse
import logging
import os
import shutil
import time
from datetime import datetime
from os.path import isdir, join
from pathlib import Path
from typing import Dict

import numpy as np
import pandas as pd
from tqdm import tqdm

from caid import check_output_of_method_on_sequence
from containers import build_containers, create_out_dirs_and_inputs
from sbatch import run_method_on_sequence, run_methods

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s',
                    filename="caid2_execution.log", filemode="w")
logger = logging.getLogger(__name__)

SCRIPT_DIR = Path(__file__).parent.resolve()
SINGULARITY_IMG_PTH = "/software/containers/caid/defs"
EXECUTION_START_PTH = "/projects/CAID2/execution"
FASTA_FILES_PTH = "/projects/CAID2/caid2_dataset/fastas"


def init_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
            usage="%(prog)s [OPTION]...",
            description="Start the execution of the CAID2 pipeline",
    )

    parser.add_argument(
            "-t", "--test", action="store_true", default=False, required=False,
            help="Run the pipeline on just one sequence (DP02342.fasta)"
    )

    parser.add_argument(
            "-r", "--resume", action="store_true", default=False, required=False,
            help="Resume the execution of the pipeline. This will only get the results of the last execution without executing the methods again."
    )

    parser.add_argument(
            "-x", "--re-execute", action="store_true", default=False, required=False,
            help="Re-execute the pipeline on failed sequences"
    )

    parser.add_argument(
            "-m", "--methods", nargs="+", default=[], required=False,
            help="Run only the methods specified. If not specified, all the methods will be executed. (Method name is the exact name, cap sensitive)"
    )

    parser.add_argument(
            "-i", "--run-id", default=None, required=False,
            help="Run ID of the execution. If not specified, a new one will be generated."
    )

    parser.add_argument(
            "-v", "--version", action="version",
            version=f"{parser.prog} version 1.0.0"
    )

    return parser


DO_NOT_RUN_METHODS = ["AUCpred", "CLIP", "flDPlr2", "flDPnn2", "flDPtr", "IDP-Fusion", "PreDisorder", "DisoBindPred",
                      "DISOPRED3", "MoRFchibi", "Dusiored", "IUPred3", "PredIDR", "rawMSA", "AUCpred",
                      "DisoPred", "SPOT-Disorder2"]

rename_predictors = {
        "espritz_D"                  : "ESpritz-D",
        "espritz_X"                  : "ESpritz-X",
        "espritz_N"                  : "ESpritz-N",
        "DRPBind_DNA_DeepDRPBind"    : "DeepDRPBind-DNA",
        "DRPBind_RNA_DeepDRPBind"    : "DeepDRPBind-RNA",
        "DRPBind_protein_DeepDRPBind": "DeepDRPBind-protein",
        "DRPBind_protein_DRPBind"    : "DRPBind-protein",
        "DRPBind_DNA_DRPBind"        : "DRPBind-DNA",
        "DRPBind_RNA_DRPBind"        : "DRPBind-RNA",
}


def get_failed_sequences():
    failed_sequences = set()
    df = pd.read_csv(join(SCRIPT_DIR, "results", "results.csv"))
    for _, method, disprot_id, _, no_output, vaild, _ in df.itertuples(index=False):
        if not vaild or no_output:
            failed_sequences.add((method, disprot_id))
    return failed_sequences


def run_failed_sequences(exec_pth):
    failed_sequences = get_failed_sequences()
    submitted_jobs = dict()
    for method, disprot_id in tqdm(failed_sequences, desc="Re-running failed sequences"):
        if method not in DO_NOT_RUN_METHODS:
            logger.info("Re-executing {} on {}".format(method, disprot_id))
            print("Re-executing {} on {}".format(method, disprot_id))
            submitted_jobs.update(run_method_on_sequence(exec_pth, method, disprot_id))
    return submitted_jobs


def load_reference_sequences():
    reference_sequences = set()
    with open(join(SCRIPT_DIR, "reference"), "r") as f:
        for line in f:
            if len(line) > 0:
                reference_sequences.add(line.strip())
    return reference_sequences


def merge_results(execution_id):
    references = load_reference_sequences()
    predictors_dir = join(SCRIPT_DIR, "results", execution_id)
    predictors = list(filter(lambda x: not isdir(x) and x != "merged", os.listdir(predictors_dir)))
    merged_dir = join(predictors_dir, "merged")
    shutil.rmtree(merged_dir, ignore_errors=True)
    os.makedirs(merged_dir, exist_ok=True)

    for predictor in tqdm(list(predictors), desc="Merging results"):
        predictor_new_name = predictor if predictor not in rename_predictors else rename_predictors[predictor]
        predictor_new_name = predictor_new_name.replace("_", "-")
        with open(join(merged_dir, "{}.caid".format(predictor_new_name)), "w") as f:
            for result in os.listdir(join(predictors_dir, predictor)):
                disprot_id = result.split(".")[0]
                if disprot_id in references:
                    result_pth = str(join(predictors_dir, predictor, result))
                    df = pd.read_csv(result_pth, sep='\t', skiprows=1, header=None)
                    f.write(">{}\n".format(disprot_id))
                    df.to_csv(f, sep='\t', index=False, header=False, float_format="%.3f")
    shutil.copytree(merged_dir, '/projects/CAID2/predictions', dirs_exist_ok=True)


if __name__ == '__main__':
    logger.info("Starting caid2 execution pipeline at {}".format(datetime.now()))

    parser = init_argparse()
    args = parser.parse_args()

    if args.test:
        logger.info("Running the pipeline on just one sequence (DP02342.fasta)")

    if args.resume:
        logger.info("Resuming the execution of the pipeline")

    if args.methods:
        logger.info("Running only the methods specified: {}".format(args.methods))

    if not args.resume:
        logging.info("Starting building containers")
        build_containers(SINGULARITY_IMG_PTH)
        logging.info("Containers built")

        if not args.run_id:
            now = datetime.now()
            run_id = now.strftime("%d-%m-%Y_%H-%M")
        else:
            if Path(join(EXECUTION_START_PTH, args.run_id)).exists():
                run_id = args.run_id
            else:
                raise ValueError("Run ID {} does not exist".format(args.run_id))

        execution_pth = Path(join(EXECUTION_START_PTH, run_id))
        Path.mkdir(execution_pth, parents=True, exist_ok=True)

        latest_exec_path = Path(join(EXECUTION_START_PTH, "latest"))
        if latest_exec_path.exists():
            os.unlink(join(EXECUTION_START_PTH, "latest"))
        latest_exec_path.symlink_to(execution_pth, target_is_directory=True)

        if not args.run_id:
            create_out_dirs_and_inputs(latest_exec_path, SINGULARITY_IMG_PTH, FASTA_FILES_PTH, methods=args.methods,
                                       test=args.test)

        running_jobs = dict()
        if args.run_id:
            running_jobs = np.load(join(latest_exec_path, "running_jobs.npy"), allow_pickle=True).item()

        running_jobs.update(run_methods(latest_exec_path, methods=args.methods, test=args.test))

        np.save(join(latest_exec_path, "running_jobs.npy"), running_jobs)

    else:
        logging.info("Resuming execution")
        latest_exec_path = Path(join(EXECUTION_START_PTH, "latest"))
        execution_pth = Path(join(EXECUTION_START_PTH, os.path.basename(os.path.realpath(latest_exec_path))))

        running_jobs: Dict = np.load(join(latest_exec_path, "running_jobs.npy"), allow_pickle=True).item()

        if args.re_execute:
            logger.info("Re-executing the pipeline on failed sequences")
            running_jobs.update(run_failed_sequences(execution_pth))
            np.save(join(latest_exec_path, "running_jobs.npy"), running_jobs)

    execution_id = os.path.basename(execution_pth)
    job_finished = []

    df = pd.DataFrame()

    while len(running_jobs) > 0:
        to_remove = []
        for (method, disprot_id), job in tqdm(running_jobs.items()):
            if job.completed():
                no_output, valid, exec_time = check_output_of_method_on_sequence(execution_pth, method, disprot_id,
                                                                                 job.job_id)
                df2 = pd.DataFrame({"execution_id": execution_id,
                                    "method"      : method,
                                    "disprot_id"  : disprot_id,
                                    "job_id"      : job.job_id,
                                    "no_output"   : no_output,
                                    "valid"       : valid,
                                    "exec_time"   : exec_time}, index=[0])
                df = pd.concat([df, df2], ignore_index=True, sort=False)

                to_remove.append((method, disprot_id))

        df.to_csv(join(SCRIPT_DIR, "results", "results.csv"), index=False, mode="w", header=False)

        for job in to_remove:
            job_finished.append(running_jobs.pop(job))

        print("{} - Jobs remaining: {}\tJobs done: {}".format(datetime.now().strftime("%d-%m-%y %H:%M:%S"),
                                                              len(running_jobs), len(job_finished)))

        if len(running_jobs) > 0:
            time.sleep(500)

    logger.info("All jobs finished")

    logger.info("Merging results")
    merge_results(execution_id="22-07-2022_15-59")
    logger.info("Results merged")
    logger.info("Finished caid2 execution pipeline at {}".format(datetime.now()))
