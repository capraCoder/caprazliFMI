# Base image: RStudio + R (Official Rocker image)
FROM rocker/rstudio:latest

# METADATA
LABEL maintainer="Kafkas M. Caprazli <caprazli@gmail.com>"
LABEL version="2.0.0"
LABEL description="Caprazli FMI Pipeline Container"

# 1. Install System Dependencies (Linux libraries needed for R packages)
# 'libxml2' and 'libcurl' are needed for Tidyverse/TropFishR
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Install R Packages (The Science Engine)
# We install 'remotes' first to ensure we can fetch specific versions if needed
RUN R -e "install.packages(c('ggplot2', 'dplyr', 'readr', 'TropFishR', 'remotes'), repos='http://cran.rstudio.com/')"

# 3. Setup Working Directory
WORKDIR /home/rstudio/caprazliFMI

# 4. Copy Your Code into the Container
COPY . /home/rstudio/caprazliFMI

# 5. Default Command: Run the Analysis automatically if container starts
CMD ["Rscript", "R/run_analysis.R"]