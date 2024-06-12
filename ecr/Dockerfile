FROM galantelab/sider:release-1.1.3 AS sider_source

FROM ubuntu:20.04

LABEL maintainer="tmiller@mochsl.org.br"

RUN set -e; \
    \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      --no-install-recommends \
      bzip2 \
      ca-certificates \
      gcc \
      gzip \
      libbz2-dev \
      liblzma-dev \
      libncurses5-dev \
      make \
      unzip \
      zlib1g-dev \
      wget; \
    rm -rf /var/lib/apt/lists/*

RUN set -e; \
    \
    wget -q https://gdc.cancer.gov/system/files/public/file/gdc-client_v1.6.1_Ubuntu_x64.zip -O gdc-client.zip; \
    unzip gdc-client.zip; \
    install -Dpm755 gdc-client /usr/local/bin/; \
    rm -f gdc-client.zip gdc-client

RUN set -e; \
    \
    wget -q https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 -O- \
    | tar xj; \
    cd samtools-1.9/; \
    ./configure; \
    make; \
    make install; \
    cd -; \
    rm -rf samtools-1.9/

RUN set -e; \
    \
    wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -O awscliv2.zip; \
    unzip awscliv2.zip; \
    ./aws/install; \
    rm -rf aws/ awscliv2.zip

COPY --from=sider_source /usr/local/bin/sider /usr/local/bin/
COPY fetch_and_run.sh /usr/local/bin/

USER nobody:nogroup

WORKDIR /home/workdir
VOLUME /home/workdir

ENTRYPOINT ["fetch_and_run.sh"]
