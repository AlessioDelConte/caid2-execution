import logging
import os
import shutil
from itertools import takewhile
from os.path import isdir, isfile, join
from pathlib import Path

import pandas as pd
from pandas.errors import EmptyDataError

logger = logging.getLogger(__name__)
SCRIPT_DIR = Path(__file__).parent.resolve()


def read_caid_file(file_pth, method):
    disprot_id = os.path.basename(file_pth).split(".")[0]
    try:
        df = pd.read_csv(file_pth, sep="\t", header=None, skiprows=1)
    except EmptyDataError:
        raise Exception("No data found for {} on {}".format(method, disprot_id))

    df.columns = ["index", "resn", "score", "binary"]

    # Check that either the score or the binary column is not empty
    if df.score.isnull().all() and df.binary.isnull().all():
        raise Exception("No score or binary column for {} on {}".format(method, disprot_id))

    # Check that the score is in the range [0, 1] if it is not empty
    if not df.score.isnull().all():
        if not (df.score >= 0).all() or not (df.score <= 1).all():
            logger.warning("Score for {} on {} is not in the range [0, 1], fixing".format(method, disprot_id))
            df.score = df.score.clip(0, 1)

    # Check that the binary is either 0 or 1 if it is not empty
    if not df.binary.isnull().all():
        if not df.binary.isin([0, 1]).all():
            logger.warning("Binary for {} on {} is not 0 or 1, fixing".format(method, disprot_id))
            df.binary = df.binary.astype(int).clip(0, 1)

    return df


def write_caid_result(execution_id, method, disprot_id, result):
    Path.mkdir(Path(join(SCRIPT_DIR, "results", execution_id, method)), exist_ok=True, parents=True)
    result.to_csv(join(SCRIPT_DIR, "results", execution_id, method, "{}.caid".format(disprot_id)), sep="\t",
                  index=False, float_format="%.3f")


def get_time(timings_pth, method, disprot_id):
    if isfile(timings_pth):
        with open(timings_pth, "r") as f:
            time = None
            for line in f:
                if line.startswith("DP"):
                    time = int(line.split(",")[1].strip())
            if time:
                return time
            else:
                raise Exception("No time found for {} on {}".format(method, disprot_id))
    else:
        raise Exception("No timings file found for {} on {}".format(method, disprot_id))


def check_output_of_method_on_sequence(exec_pth, method, disprot_id, job_id):
    no_output, valid = False, True
    exec_time = None

    execution_id = os.path.basename(exec_pth)

    exec_pth_method = Path(join(exec_pth, method))
    os.chdir(exec_pth_method)

    logger.debug("Checking {} on {}".format(method, disprot_id))
    # Go in the directory of the disprot_id
    os.chdir(disprot_id)
    logger.debug("Now in {}".format(os.getcwd()))

    # Check output dir exists
    exec_pth_method = Path(join(exec_pth, method))

    job_log_path = Path(join(exec_pth_method, "{}_{}.log".format(method,
                                                                 job_id if "_" in job_id else
                                                                 "{}_{}".format(job_id, "4294967294"))))
    if not Path.is_dir(Path("outputs")):
        copy_log_from(job_log_path, execution_id, method, disprot_id)
        logger.error("Outputs dir not found for {} on {}".format(method, disprot_id))
        no_output = True
    else:
        os.chdir("outputs")

        caid_files = []
        # Get all the possible caid files inside the outputs dir
        for dirpath, dirnames, filenames in os.walk("."):
            caid_files.extend([Path(join(dirpath, f)).absolute() for f in filenames if f.endswith(".caid")])

        # If there are no caid files, something went wrong with the execution
        if len(caid_files) == 0:
            copy_log_from(job_log_path, execution_id, method, disprot_id)
            logger.error("No caid file found for {} on {}".format(method, disprot_id))
            no_output = True
            valid = False

        # Check in all subdirectories if the caid file(s) exists
        try:
            for caid_file_pth in caid_files:
                result = read_caid_file(caid_file_pth, method)

                method_tmp = method
                if os.path.basename(caid_file_pth.parent) != "outputs":
                    dirs = list(reversed(caid_file_pth.parent.parts))
                    suffix = '_'.join(takewhile(lambda x: x != "outputs", dirs))
                    method_tmp = "{}_{}".format(method, suffix) if suffix else method

                # Check that the caid file(s) are valid
                logger.info("{} on {} is valid".format(method_tmp, disprot_id))
                write_caid_result(execution_id, method_tmp, disprot_id, result)

            exec_time = get_time(Path(join(exec_pth_method, disprot_id, "timings.csv")), method, disprot_id)

        except Exception as e:
            copy_log_from(job_log_path, execution_id, method, disprot_id)
            valid = False
            logger.error("{} on {}: {}".format(method, disprot_id, e))

        # Go back to the directory of the method
        os.chdir(exec_pth_method)
    return no_output, valid, exec_time


def check_all_outputs(exec_pth, test=False):
    no_output, valid, invalid = [], [], []
    for method in os.listdir(exec_pth):
        exec_pth_method = Path(join(exec_pth, method))
        if Path.is_dir(exec_pth_method):
            os.chdir(exec_pth_method)
            for disprot_id in [disprot_id for disprot_id in os.listdir() if isdir(disprot_id)]:
                if test and disprot_id != "DP02342":
                    continue
                no_output, valid, invalid = check_output_of_method_on_sequence(exec_pth, method, disprot_id)

    return no_output, valid, invalid


def copy_log_from(log_pth, execution_id, method, disprot_id):
    if isfile(log_pth):
        # Create a directory inside the log directories with the execution id
        Path.mkdir(Path(join(SCRIPT_DIR, "logs", execution_id, method)), exist_ok=True, parents=True)

        shutil.copyfile(log_pth, join(SCRIPT_DIR, "logs", execution_id, method, "{}.log".format(disprot_id)))
    else:
        logger.error("No log file found in {}".format(log_pth))
