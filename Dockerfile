#
#  From this base-image / starting-point
#
FROM ubuntu:20.04

#
#  Authorship
#
LABEL org.opencontainers.image.authors="William.Haese-Hill@glasgow.ac.uk"

#
# Install packages without interactive dialogue
#
ARG DEBIAN_FRONTEND=noninteractive

#
# Pull in packages from testing
#
RUN apt-get update -qq

#
# Install dependencies
# we need blast2 for ABACAS2 as it does not use BLAST+ yet
#
RUN apt-get install build-essential hmmer lua5.1 ncbi-blast+ blast2 snap \
                    unzip mummer infernal exonerate mafft fasttree \
                    circos libsvg-perl libgd-svg-perl python-setuptools \
                    libc6-i386 lib32stdc++6 lib32gcc1 netcat genometools \
                    last-align libboost-iostreams-dev libgslcblas0 libgsl-dev \
                    libcolamd2 liblpsolve55-dev libstdc++6 aragorn tantan \
                    libstorable-perl libbio-perl-perl libsqlite3-dev git \
                    --yes
RUN ln -fs /usr/bin/fasttree /usr/bin/FastTree
RUN ln -s /usr/lib/snap/snap /usr/local/bin/snap

#
# Install AUGUSTUS
#
RUN apt-get install augustus --yes
RUN apt-get install libboost-all-dev libmysql++-dev libbamtools-dev samtools \
                    libhts-dev \
                    --yes
RUN cd /opt && \
    git clone https://github.com/Gaius-Augustus/Augustus.git && \
    cd Augustus && \
    git fetch --all --tags && \
    git checkout tags/v3.4.0 -b v3.4.0 && \
    make && \
    make install

#
# Install GenomeTools
#
RUN apt-get install genometools --yes

#
# get GO OBO file
#
ADD http://geneontology.org/ontology/go.obo /opt/go.obo
RUN chmod 755 /opt/go.obo

#
# get Pfam pHMMs
#
RUN mkdir -p /opt/pfam
ADD http://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz /opt/pfam/Pfam-A.hmm.gz
RUN cd /opt/pfam && \
    gunzip Pfam-A.hmm.gz && \
    hmmpress Pfam-A.hmm && \
    rm -f Pfam-A.hmm

#
# copy data dir
#
RUN mkdir -p /opt/data
ADD ./data /opt/data

#
# install RATT
#
RUN cd /opt && \
    git clone https://github.com/ThomasDOtto/ratt RATT
RUN apt-get install tabix --yes

#
# install python
#
RUN apt-get install software-properties-common --yes
RUN add-apt-repository ppa:deadsnakes/ppa --yes
RUN apt-get install python3.9 python3-setuptools libpython3.9-dev libz-dev libbz2-dev \
                    liblzma-dev libcurl4-openssl-dev pkg-config \
                    --yes

#
# install Liftoff
#
ADD https://github.com/lh3/minimap2/releases/download/v2.17/minimap2-2.17_x64-linux.tar.bz2 /opt/minimap2.tar.bz2
RUN cd /opt && \
    tar -jxvf minimap2.tar.bz2 && \
    rm -rf minimap2.tar.bz2&& \
    cp minimap2-2.17_x64-linux/minimap2 /usr/local/bin/minimap2 && \
    chmod 755 /usr/local/bin/minimap2
RUN apt-get -y install python3-pip
RUN cd /opt && \
    git clone https://github.com/agshumate/Liftoff liftoff && \
    cd liftoff && \
    python3 setup.py install
# Numpy 1.24 currently breaks Liftoff
RUN pip3 install "numpy<1.24"


#
# install ABACAS (keep up to date from build directory)
#
ADD ./ABACAS2 /opt/ABACAS2

#
# install nucmer v4
#
ADD https://github.com/mummer4/mummer/releases/download/v4.0.0rc1/mummer-4.0.0rc1.tar.gz /opt/mummer-4.0.0rc1.tar.gz
RUN cd /opt && \
    tar xzf mummer-4.0.0rc1.tar.gz && \
    cd mummer-4.0.0rc1/ && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    rm -f mummer-4.0.0rc1.tar.gz

#
# install prinseq-lite
#
RUN apt-get install wget --yes
RUN cd /opt && \
    wget https://sourceforge.net/projects/prinseq/files/standalone/prinseq-lite-0.20.4.tar.gz && \
    tar xzf prinseq-lite-0.20.4.tar.gz && \
    cd prinseq-lite-0.20.4 && \
    chmod +x prinseq-lite.pl && \
    cp prinseq-lite.pl /usr/local/bin/ && \
    cd .. && \
    rm -rf prinseq-lite*

#
# install braker
#
RUN apt-get -y install cpanminus
RUN cpanm File::Spec::Functions && \
    cpanm Hash::Merge && \
    cpanm List::Util && \
    cpanm MCE::Mutex && \
    cpanm Module::Load::Conditional && \
    cpanm Parallel::ForkManager && \
    cpanm POSIX && \
    cpanm Scalar::Util::Numeric && \
    cpanm YAML && \
    cpanm Math::Utils && \
    cpanm File::HomeDir && \
    cpanm threads
RUN cd /opt && \
    git clone https://github.com/Gaius-Augustus/BRAKER.git --branch v2.1.6 && \
    cd BRAKER/scripts
ADD http://topaz.gatech.edu/GeneMark/etp.for_braker.tar.gz /opt/etp.for_braker.tar.gz
RUN cd /opt && \
    tar -xzf etp.for_braker.tar.gz && \
    rm -f etp.for_braker.tar.gz
RUN apt-get -y install cmake
RUN cd /opt && \
    git clone https://github.com/pezmaster31/bamtools.git && \
    cd bamtools && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make
ADD http://github.com/bbuchfink/diamond/releases/download/v0.9.24/diamond-linux64.tar.gz /opt/diamond-linux64.tar.gz
RUN cd /opt && \
    tar xzf diamond-linux64.tar.gz && \
    rm -f diamond-linux64.tar.gz
RUN cd /opt && \
    git clone https://github.com/gatech-genemark/ProtHint.git
RUN pip3 install biopython
RUN apt-get -y install cdbfasta
ADD https://genomethreader.org/distributions/gth-1.7.3-Linux_x86_64-64bit.tar.gz /opt/gth-1.7.3-Linux_x86_64-64bit.tar.gz
RUN cd /opt && \
    tar xzf gth-1.7.3-Linux_x86_64-64bit.tar.gz && \
    rm -f gth-1.7.3-Linux_x86_64-64bit.tar.gz

#
# install orthofinder
#
ADD https://github.com/davidemms/OrthoFinder/releases/download/2.5.4/OrthoFinder_source.tar.gz /opt/OrthoFinder_source.tar.gz
RUN pip3 install scipy
RUN cd /opt && \
    tar xzf OrthoFinder_source.tar.gz && \
    cd OrthoFinder_source && \
    chmod +x orthofinder.py

## Make sure to build with 'docker build --build-arg GM_KEY=<GM_KEY> .' to populate this arg.
ARG GM_KEY
RUN echo ${GM_KEY} > ~/.gm_key

#
# install gffread
#
RUN apt-get -y install gffread

#
# set environment variables
#
ENV AUGUSTUS_BIN_PATH /opt/Augustus/bin
ENV AUGUSTUS_SCRIPTS_PATH /opt/Augustus/scripts
ENV RATT_HOME /opt/RATT
ENV GT_RETAINIDS yes
ENV PERL5LIB /opt/RATT/:/opt/ABACAS2/:$PERL5LIB
ENV PATH /opt/gth-1.7.3-Linux_x86_64-64bit/bin:/opt/BRAKER/scripts/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/augustus/bin:/usr/share/augustus/scripts:/opt/OrthoFinder_source:/opt/RATT:/opt/ABACAS2:$PATH
ENV GENEMARK_PATH /opt/etp.for_braker/bin/gmes
ENV PYTHON3_PATH /usr/bin
ENV BAMTOOLS_PATH /opt/bamtools/build/src
ENV DIAMOND_PATH /opt
ENV PROTHINT_PATH /opt/ProtHint/bin
ENV BSSMDIR /opt/gth-1.7.3-Linux_x86_64-64bit/bin/bssm
ENV GTHDATADIR /opt/gth-1.7.3-Linux_x86_64-64bit/bin/gthdata
ENV ALIGNMENT_TOOL_PATH /opt/gth-1.7.3-Linux_x86_64-64bit/bin/
