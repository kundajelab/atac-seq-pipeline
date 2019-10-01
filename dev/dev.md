# Dev

## Command line for version change
```bash
PREV_VER=dev-v0.1.0
NEW_VER=dev-v0.1.0
for f in $(grep -rl ${PREV_VER} --include=*.{wdl,md,sh})
do
  sed -i "s/${PREV_VER}/${NEW_VER}/g" ${f}
done
cd dev/workflow_opts
for f in $(grep -rl ${PREV_VER} --include=*.json)
do
  sed -i "s/${PREV_VER}/${NEW_VER}/g" ${f}
done
cd ../../
```

## Building templates on DX for each genome

Make sure that you have [`dxWDL-0.79.1.jar`](https://github.com/DNAnexus/dxWDL/releases/download/0.79.1/dxWDL-0.79.1.jar) on your `$HOME`. Install [DNAnexus Platform SDK](https://wiki.DNAnexus.com/downloads) with `pip install dxpy`. Log-in on DNAnexus with `dx login` and choose "ENCODE Uniform Processing Pipelines" (name of our official DNAnexus project for pipelines).

Run the following command line locally to build out DX workflows for this pipeline on our official one. This will overwrite (`-f` parameter does it).

```bash
# version
VER=dev-v0.1.0

# general
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/general -defaults dev/examples/dx/template_general.json

# hg38
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/hg38 -defaults dev/examples/dx/template_hg38.json

# hg19
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/hg19 -defaults dev/examples/dx/template_hg19.json

# mm10
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/mm10 -defaults dev/examples/dx/template_mm10.json

# mm9
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/mm9 -defaults dev/examples/dx/template_mm9.json

# test sample
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/test_ENCSR356KRQ_subsampled -defaults dev/examples/dx/ENCSR356KRQ_subsampled_dx.json

## DX Azure

# general
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines Azure" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/general -defaults dev/examples/dx_azure/template_general.json

# hg38
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines Azure" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/hg38 -defaults dev/examples/dx_azure/template_hg38.json

# hg19
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines Azure" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/hg19 -defaults dev/examples/dx_azure/template_hg19.json

# mm10
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines Azure" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/mm10 -defaults dev/examples/dx_azure/template_mm10.json

# mm9
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines Azure" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/mm9 -defaults dev/examples/dx_azure/template_mm9.json

# test sample
java -jar ~/dxWDL-0.79.1.jar compile cut_n_run.wdl -project "ENCODE Uniform Processing Pipelines Azure" -extras dev/workflow_opts/docker.json -f -folder /Cut-n-run/workflows/$VER/test_ENCSR356KRQ_subsampled -defaults dev/examples/dx_azure/ENCSR356KRQ_subsampled_dx_azure.json
```
