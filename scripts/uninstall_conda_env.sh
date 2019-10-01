#!/bin/bash

CONDA_ENV_PY3=cut-n-run-pipeline
CONDA_ENV_PY2=cut-n-run-pipeline-python2
CONDA_ENV_OLD_PY3=cut-n-run-pipeline-python3

conda env remove -n ${CONDA_ENV_PY3} -y
conda env remove -n ${CONDA_ENV_PY2} -y
conda env remove -n ${CONDA_ENV_OLD_PY3} -y

