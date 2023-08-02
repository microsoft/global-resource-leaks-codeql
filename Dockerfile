# Use the official Ubuntu base image  
FROM ubuntu:22.04
  
# Update the system and install required packages  
RUN apt-get update && \  
    apt-get install --yes software-properties-common  
    
# Install required softwares (curl & zip & wget)
RUN apt install curl -y
RUN apt install zip -y
RUN apt install wget -y

# update
RUN apt-get update -y

# Install python
RUN apt-get install -y wget unzip git python3 python3-pip

# Install panda
RUN pip3 install pandas

# Install git
RUN apt-get install -y git

# Install vim 
RUN apt-get install -y vim 

# Install dotnet

RUN apt-get update && \
    apt-get install -y dotnet-sdk-6.0 && \
    apt-get install -y aspnetcore-runtime-6.0
  
# Install CodeQL CLI  
RUN wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip && \  
    unzip codeql-linux64.zip && \  
    rm codeql-linux64.zip && \  
    mv codeql /usr/local/bin  

## Create a new user

RUN useradd -ms /bin/bash oopsla && \
    apt-get install -y sudo && \
    adduser oopsla sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER oopsla
 
# Set up a working directory  
WORKDIR /home/oopsla 

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

ENV JAVA8_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA8_HOME

RUN sudo chown -R oopsla:oopsla /home/oopsla 

# Clone the CodeQL repository  
RUN git clone --recursive https://github.com/github/codeql.git /home/oopsla/codeql-repo  

ENV PATH=$PATH:/usr/local/bin/codeql

# Copying all the scripts and manually added attributes

##RUN git clone https://github.com/microsoft/global-resource-leaks-codeql.git
RUN git clone --single-branch --branch artifact https://github.com/microsoft/global-resource-leaks-codeql.git
RUN cp -R global-resource-leaks-codeql/scripts .
RUN cp -R global-resource-leaks-codeql/docs .
RUN cp global-resource-leaks-codeql/README.md .
RUN cp -R global-resource-leaks-codeql/RLC-Codeql-Queries /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries
RUN sudo chown -R oopsla:oopsla scripts && chmod -R +x scripts/* 
RUN sudo chown -R oopsla:oopsla /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries && chmod -R +x /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries/* 

RUN mkdir /home/oopsla/csharp-open-source-projects && \
    mkdir /home/oopsla/csharp-open-source-projects/codeql-databases && \
    cd /home/oopsla/csharp-open-source-projects && \
    git clone https://github.com/apache/lucenenet.git && \
    cd lucenenet && \
    git checkout b5ea527c5bd125dd1db34d8b914e1a5d72e08ffa && \
    cd /home/oopsla/csharp-open-source-projects && \
    git clone https://github.com/dotnet/efcore.git && \
    cd efcore && \
    git checkout df614b8c6b1dcc1caabe707ef8c887111392cdaa && \
    cd /home/oopsla

##RUN mkdir scripts 
##COPY scripts scripts
##RUN sudo chown -R oopsla:oopsla scripts && chmod -R +x scripts/* 
##
##RUN mkdir /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries 
##COPY RLC-Codeql-Queries /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries
##RUN sudo chown -R oopsla:oopsla /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries && chmod -R +x /home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries/* 
##
##RUN mkdir docs 
##COPY docs docs 
##RUN sudo chown -R oopsla:oopsla docs && chmod -R +x docs/* 
##
##COPY README.md README.md
