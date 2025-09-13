FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python3 \
    python3-pip \
    python3-venv \
    verilator \
    ca-certificates \
    pkg-config \
    libffi-dev \
    libblas-dev \
    liblapack-dev \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN python3 -m venv venv
ENV PATH="/workspace/venv/bin:$PATH"
RUN pip install --upgrade pip && \
    pip install git+https://github.com/pygae/clifford.git

CMD ["bash"]
