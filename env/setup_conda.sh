#!/bin/bash
# setup_conda.sh - Set up conda environment for MetaBinGv4

set -e

echo "=== Setting up Conda Environment for MetaBinGv4 ==="

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "Error: Conda is not installed. Please install Miniconda or Anaconda first."
    echo "Download from: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# Create environment.yml if it doesn't exist
if [ ! -f environment.yml ]; then
    cat > environment.yml << 'EOF'
name: metabingv4
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - ncbi-datasets-cli
  - jq
  - unzip
  - python=3.8
  - blast            
EOF
    echo "Created environment.yml file"
fi

# Create or update the conda environment
echo "Creating/updating conda environment 'metabingv4'..."
conda env create -f environment.yml 2>/dev/null || conda env update -f environment.yml

echo "Setup complete! Activate the environment with:"
echo "  conda activate metabingv4"
