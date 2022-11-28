import logging
import os
import time
from functools import lru_cache
from os.path import isdir, join
from pathlib import Path
from subprocess import PIPE, Popen

from tqdm import tqdm

logger = logging.getLogger(__name__)


@lru_cache(maxsize=None)
def status_of_job(job_id):
    process = Popen(["sacct", "--parsable2", "--format=JobId,State", "-j{}".format(job_id)], stdout=PIPE)
    process.wait()
    if process.returncode == 0:
        lines = process.stdout.read().decode("utf-8")
        task_state = dict()
        for line in lines.split("\n"):
            if "JobID" not in line and ".batch" not in line and len(line) > 2:
                j_t, status = line.split("|")
                status = status.split(" ")[0].strip()
                # Single job
                if "_" not in j_t:
                    return status
                # Array job
                j, t = j_t.split("_")
                if "[" in t:
                    s, e = t.lstrip("[").rstrip("]").split("-")
                    for i in range(int(s), int(e) + 1):
                        task_state.setdefault(i, status)
                else:
                    task_state.setdefault(int(t), status)
        return task_state
    else:
        raise Exception("Error while checking the status of job {}".format(job_id))


class SlurmJob:
    def __init__(self, job_id, task_id=None):
        self._job_id = job_id
        self._task_id = int(task_id) if task_id else None
        self._status = None

    @property
    def status(self):
        if self._task_id is None:
            return status_of_job(self._job_id)
        else:
            return status_of_job(self._job_id)[self._task_id]

    @property
    def job_id(self):
        return "{}_{}".format(self._job_id, self._task_id) if self._task_id is not None else self._job_id

    def completed(self):
        s = self.status
        return s == "COMPLETED" or s == "FAILED" or s == "TIMEOUT" or s == "CANCELLED"

    def __repr__(self):
        return "SlurmArrayJob(job_id={}, task_id={})".format(self._job_id, self._task_id)


def run_methods(exec_pth, methods=list, test=False):
    submitted_jobs = dict()
    methods_to_run = methods if methods else os.listdir(exec_pth)

    for method in tqdm(methods_to_run, desc="Running methods"):
        exec_pth_method = Path(join(exec_pth, method))
        if Path.is_dir(exec_pth_method):
            os.chdir(exec_pth_method)

            process = Popen(["sbatch", "--job-name={}".format(method), "--parsable",
                             "--array=1-{}".format(len([x for x in os.listdir() if isdir(x)]) if not test else 1),
                             "/home/aledc/caid2-execution/sbatch_scripts/{}.sh".format(method)], stdout=PIPE)

            process.wait()
            if process.returncode == 0:
                job_id = process.stdout.read().decode('utf-8').strip()
                files = list(sorted([d for d in os.listdir() if isdir(d)]))
                for task_id, filename in enumerate(files if not test else [files[0]]):
                    disprot_id = filename.split(".")[0]
                    submitted_jobs.setdefault((method, disprot_id), SlurmJob(job_id, task_id + 1))
            # Go back to the directory of the method
            os.chdir(exec_pth_method)
            if not test:
                time.sleep(20)

    return submitted_jobs


def run_method_on_sequence(exec_pth, method, disprot_id):
    submitted_job = dict()

    exec_pth_method = Path(join(exec_pth, method))

    if Path.is_dir(exec_pth_method):
        os.chdir(exec_pth_method)

    process = Popen(["sbatch", "--job-name={}".format(method), "--parsable",
                     "--export", "query={}".format(disprot_id),
                     "/home/aledc/caid2-execution/sbatch_scripts/{}.sh".format(method)], stdout=PIPE)

    process.wait()
    if process.returncode == 0:
        job_id = process.stdout.read().decode('utf-8').strip()
        submitted_job.setdefault((method, disprot_id), SlurmJob(job_id))

    return submitted_job
