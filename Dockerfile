FROM rocker/r-ver:4.3.2

LABEL maintainer="CaprazliFMI"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install R packages (add packages as needed)
# RUN R -e "install.packages(c('tidyverse', 'data.table'), repos='https://cloud.r-project.org')"

# Default command
CMD ["R"]
