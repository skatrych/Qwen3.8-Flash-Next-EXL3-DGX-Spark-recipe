# syntax=docker/dockerfile:1.7

ARG CUDA_IMAGE=nvcr.io/nvidia/cuda:13.0.2-devel-ubuntu24.04@sha256:5dc1bca23d05bd37b011be68ec470c03b403a5da07ec3a86e41af9470e9d0cc6
FROM ${CUDA_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG EXLLAMAV3_COMMIT=329e051385505b6ba981138d86a90bffe032c831
ARG TORCH_VERSION=2.13.0

RUN sed -i 's|http://ports.ubuntu.com|https://ports.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:/usr/local/cuda/bin:${PATH} \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST=12.1 \
    MAX_JOBS=10 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN python3 -m venv "${VIRTUAL_ENV}" \
    && pip install --upgrade pip setuptools wheel ninja \
    && pip install "torch==${TORCH_VERSION}" --index-url https://download.pytorch.org/whl/cu130

WORKDIR /opt/exllamav3
RUN git clone https://github.com/vcruz305/exllamav3.git . \
    && git checkout --detach "${EXLLAMAV3_COMMIT}" \
    && test "$(git rev-parse HEAD)" = "${EXLLAMAV3_COMMIT}" \
    && git remote remove origin \
    && pip install --no-build-isolation ".[examples]" huggingface_hub \
    && printf '%s\n' "${EXLLAMAV3_COMMIT}" > /opt/exllamav3/EXLLAMAV3_COMMIT \
    && python -c 'from exllamav3 import ext; print("extension built:", ext.exllamav3_ext.__file__)'

ARG TABBYAPI_COMMIT=53da7919d4e45c63f4acbcbbc00cbe0f60a1ce65
COPY docker/tabbyapi-integration.patch /tmp/tabbyapi-integration.patch

WORKDIR /opt/tabbyapi
RUN git clone https://github.com/theroyallab/tabbyAPI.git . \
    && git checkout --detach "${TABBYAPI_COMMIT}" \
    && test "$(git rev-parse HEAD)" = "${TABBYAPI_COMMIT}" \
    && git apply /tmp/tabbyapi-integration.patch \
    && git remote remove origin \
    && pip install . uvloop \
    && printf '%s\n' "${TABBYAPI_COMMIT}" > /opt/tabbyapi/TABBYAPI_COMMIT

COPY docker/entrypoint.sh /usr/local/bin/exllamav3-container
COPY docker/doctor.py /usr/local/bin/exllamav3-doctor
COPY docker/drop_model_cache.py /usr/local/bin/drop-model-cache
COPY docker/resolve_model.py /usr/local/bin/resolve-hf-model

RUN chmod 0755 \
        /usr/local/bin/exllamav3-container \
        /usr/local/bin/exllamav3-doctor \
        /usr/local/bin/drop-model-cache \
        /usr/local/bin/resolve-hf-model \
    && mkdir -p /cache /data /model \
    && chmod 0777 /cache /data

ENV HOME=/data \
    HF_HOME=/huggingface \
    XDG_CACHE_HOME=/cache \
    TORCH_EXTENSIONS_DIR=/cache/torch_extensions \
    TRITON_CACHE_DIR=/cache/triton \
    MODEL_PATH=/model \
    EXL3_INT8_GEMV=0 \
    EXL3_MOE_COOP_WIDE=1 \
    EXL3_GR_INT8=1 \
    EXL3_MTP_HEAD_N=65536 \
    EXL3_NGRAM_STREAM=0

ENTRYPOINT ["/usr/local/bin/exllamav3-container"]
CMD ["chat"]
