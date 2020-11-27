#  Copyright 2020 The Kale Authors
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Use tensorflow-1.14.0 as a base image, allowing the user to
# speficy if they want GPU support, by setting IMAGE_TYPE to "gpu".
ARG IMAGE_TYPE="gpu"
FROM gcr.io/kubeflow-images-public/tensorflow-2.1.0-notebook-${IMAGE_TYPE}:1.0.0

USER root

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates bash-completion tar less \
        python-pip python-setuptools build-essential python-dev \
        python3-pip python3-wheel && \
    rm -rf /var/lib/apt/lists/*

ENV SHELL /bin/bash
COPY bashrc /etc/bash.bashrc
RUN echo "set background=dark" >> /etc/vim/vimrc.local

# Install latest KFP SDK & Kale & JupyterLab Extension
RUN pip3 install --upgrade pip 
RUN pip3 install --upgrade "jupyterlab" 
RUN pip3 install --upgrade "kfp"
RUN pip3 install -U kubeflow-kale
RUN jupyter labextension install kubeflow-kale-labextension

RUN pip3 install kubeflow-fairing kubeflow-metadata fire joblib nbconvert pathlib pandas sklearn xgboost importlib kubernetes tensorflow keras 

COPY kfp.py /usr/local/lib/python3.6/dist-packages/kale/rpc/kfp.py
COPY transport_pool_.py /usr/local/lib/python3.6/dist-packages/containerregistry/transport/transport_pool_.py
COPY append.py /usr/local/lib/python3.6/dist-packages/kubeflow/fairing/builders/append/append.py

RUN echo "jovyan ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan
WORKDIR /home/jovyan
USER jovyan

CMD ["sh", "-c", \
     "jupyter lab --notebook-dir=/home/jovyan --ip=0.0.0.0 --no-browser \
      --allow-root --port=8888 --LabApp.token='' --LabApp.password='' \
      --LabApp.allow_origin='*' --LabApp.base_url=${NB_PREFIX}"]
