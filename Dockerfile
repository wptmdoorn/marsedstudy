## Dockerfile for MARS-ED study interface
# MAINTAINER: WILLIAM VAN DOORN
FROM ubuntu:18.04
#FROM rocker/r-ver:4.0.5

# Install tzdata and configure Timezone
# We do this in the first place to make sure tzdata will not stop R installation
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y tzdata
RUN ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install R
# Some of these packages such as apt-utils, sapt-transport-https or gnupg2 are required so that the R repo can be added and R installed
# Note that the R repo is specific for the Linux distro (Ubuntu 18.04 aka bionic in this case)
# Other packages such as curl will be used later to install ODBC
RUN apt-get update -y && apt-get install -y build-essential curl libssl1.0.0 libssl-dev gnupg2 software-properties-common dirmngr apt-transport-https apt-utils lsb-release ca-certificates
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt-get update -y 
#RUN apt remove r-base* --purge && apt-get install -y r-base=4.0.5-1.1804.0
ARG R_INSTALL_VERSION="4.0.5-1.1804.0"
RUN apt-get install -y  \
  r-base-core=${R_INSTALL_VERSION} \
  r-base-html=${R_INSTALL_VERSION} \
  r-doc-html=${R_INSTALL_VERSION} \
  r-base-dev=${R_INSTALL_VERSION} 

# system libraries of general use
# Install Ubuntu packages
RUN apt-get update && apt-get install -y \
    sudo \
    nano \ 
    unixodbc unixodbc-dev \ 
    libsodium-dev \
    libxml2-dev \
    libcurl4-openssl-dev \ 
    libfontconfig1-dev \
    libharfbuzz-dev \ 
    libfribidi-dev \
    libfreetype6-dev \ 
    libtiff5-dev

RUN odbcinst -j

## update system libraries
#RUN apt-get update && \
#    apt-get upgrade -y && \
#    apt-get clean

# Install R packages that are required
RUN R -e "install.packages('textshaping', dependencies=TRUE); if(!library(textshaping, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('odbc', dependencies=TRUE); if(!library(odbc, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shiny', dependencies=TRUE); if(!library(shiny, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shinyjs', dependencies=TRUE); if(!library(shinyjs, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shinyalert', dependencies=TRUE); if(!library(shinyalert, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('DT', dependencies=TRUE); if(!library(DT, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('htmlwidgets', dependencies=TRUE); if(!library(htmlwidgets, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('devtools', dependencies=TRUE); if(!library(devtools, logical.return=T)) quit(status=10)"
RUN R -e "require(devtools); install_version('markdown', version='1.1', dependencies=TRUE); if(!library(markdown, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('rvest', dependencies=TRUE); if(!library(rvest, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shinyauthr', dependencies=TRUE); if(!library(shinyauthr, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('tidyverse', dependencies=TRUE); if(!library(tidyverse, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shinyauthr', dependencies=TRUE); if(!library(shinyauthr, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shinycssloaders', dependencies=TRUE); if(!library(shinycssloaders, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('shinydashboard', dependencies=TRUE); if(!library(shinydashboard, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('sodium', dependencies=TRUE); if(!library(sodium, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('tibble', dependencies=TRUE); if(!library(tibble, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('lightgbm', dependencies=TRUE); if(!library(lightgbm, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('reshape2', dependencies=TRUE); if(!library(reshape2, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('lubridate', dependencies=TRUE); if(!library(lubridate, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('cyphr', dependencies=TRUE); if(!library(cyphr, logical.return=T)) quit(status=10)"
RUN R -e "install.packages('stats', dependencies=TRUE); if(!library(stats, logical.return=T)) quit(status=10)"
RUN R -e "require(devtools); install_version('dplyr', version='1.0.10'); if(!library(dplyr, logical.return=T)) quit(status=10)"
#RUN R -e "install.packages('ParBayesianOptimization', dependencies=TRUE)"

# Copy configuration files into the Docker image
#COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
#COPY /app /srv/shiny-server/

#copy the driver to container
COPY /driver /usr/lib/intersystems/odbc

#run install script
RUN /usr/lib/intersystems/odbc/ODBCinstall

# COPY & INSTALL DRIVER
COPY odbc/odbcinst.ini /etc/intersystemsodbcinst.ini
RUN odbcinst -i -d -f /etc/intersystemsodbcinst.ini

# COPY & INSTALL DSN
COPY odbc/odbc.ini /etc/intersystemsodbc.ini
RUN odbcinst -i -s -l -f /etc/intersystemsodbc.ini

COPY /src src/

WORKDIR /src

EXPOSE 3838
CMD ["sudo", "R", "-e", "shiny::runApp('.', host = '0.0.0.0', port=3838)"]