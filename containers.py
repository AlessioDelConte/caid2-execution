import logging
import os
import shutil
from os.path import join
from pathlib import Path
from subprocess import Popen

from tqdm import tqdm

logger = logging.getLogger(__name__)


def build_containers(singularity_img_path):
    for method in tqdm(os.listdir(singularity_img_path), desc="Building containers"):
        if Path.is_dir(Path("{}/{}".format(singularity_img_path, method))):
            if "{}.sif".format(method) not in os.listdir("{}/{}".format(singularity_img_path, method)):
                # Going to the directory of the method
                os.chdir("{}/{}".format(singularity_img_path, method))
                logger.debug("Going to {}".format(os.getcwd()))
                # Building the container
                process = Popen(
                        ["sudo", "/opt/bin/singularity", "build", "{}.sif".format(method), "{}.def".format(method)])
                process.wait()


def create_out_dirs_and_inputs(exec_pth, singularity_img_pth, fasta_pth, methods=list, test=False):
    methods_to_run = methods if methods else os.listdir(singularity_img_pth)

    for method in methods_to_run:
        if Path.is_dir(Path("{}/{}".format(singularity_img_pth, method))):
            exec_pth_method = Path(join(exec_pth, method))
            Path.mkdir(exec_pth_method, exist_ok=True)

            for fasta_file in tqdm(os.listdir(fasta_pth), desc="Creating dirs and inputs for {}".format(method)):
                if test and fasta_file != "DP02342.fasta":
                    continue
                disprot_id = fasta_file.split(".")[0]
                Path.mkdir(Path(join(exec_pth_method, disprot_id)), exist_ok=True)
                shutil.copyfile(join(fasta_pth, fasta_file), join(exec_pth, method, disprot_id, "input.fasta"))
