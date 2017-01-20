#!/bin/bash
sudo Rscript -e 'if(!require("RImpala", character.only = TRUE, quietly = TRUE)) install.packages("RImpala", dependencies = TRUE, repos="https://cran.r-project.org")'
