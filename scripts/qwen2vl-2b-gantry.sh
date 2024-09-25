#!/usr/bin/env bash

set -ex

# check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it."
    exit
fi


EXTRA_ARGS="-c pdelfin/train/config/qwen2vl-2b-lora.yaml --num_proc 64 --save.path \"s3://ai2-oe-data/jakep/experiments/qwen2vl-pdf/v1/models/\${BEAKER_USER_ID}\""

run_name=$(basename "$0" .sh)

# --cluster 'ai2/jupiter*' \
# --cluster 'ai2/pluto*' \
# --cluster 'ai2/allennlp-cirrascale' \
# --priority high \

CLUSTER='jupiter'

gantry run \
    --description "${run_name}"\
    --task-name "${run_name}"\
    --allow-dirty \
    --host-networking \
    --workspace ai2/oe-data-pdf \
    --beaker-image 'jakep/jakep-pdf-finetunev1.1' \
    --venv 'base' \
    --pip gantry-requirements.txt \
    --priority normal \
    --gpus 8 \
    --preemptible \
    --cluster "ai2/${CLUSTER}*" \
    --budget ai2/oe-data \
    --env LOG_FILTER_TYPE=local_rank0_only \
    --env OMP_NUM_THREADS=8 \
    --env BEAKER_USER_ID=$(beaker account whoami --format json | jq '.[0].name' -cr) \
    --env-secret AWS_ACCESS_KEY_ID=S2_AWS_ACCESS_KEY_ID \
    --env-secret AWS_SECRET_ACCESS_KEY=S2_AWS_SECRET_ACCESS_KEY \
    --env-secret WANDB_API_KEY=WANDB_API_KEY \
    --shared-memory 10GiB \
    --yes \
    -- /bin/bash -c "source scripts/beaker/${CLUSTER}-ib.sh && accelerate launch --multi_gpu --num_processes \${BEAKER_ASSIGNED_GPU_COUNT} --mixed_precision bf16 -m pdelfin.train.train ${EXTRA_ARGS}"