#!/bin/bash

#install R
# sudo yum -y --exclude=kernel\* update
# sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
sudo yum -y install epel-release
sudo yum -y install wget texlive texlive-epsf texinfo texinfo-tex libcurl-devel R libssh2-devel libxml2-devel cairo-devel libXt-devel

sudo Rscript -e 'install.packages(c("repr", "IRdisplay", "crayon", "pbdZMQ", "devtools"), dependencies = TRUE, repos="https://cran.r-project.org")'

sudo Rscript -e 'devtools::install_github("IRkernel/IRkernel")'
sudo Rscript -e 'IRkernel::installspec()'

echo "R kernel for Jupyter installed"
