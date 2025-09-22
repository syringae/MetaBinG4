# -----------------------
# Project Makefile for metabing
# -----------------------

# -----------------------
# Directories
# -----------------------
SRC_DIR := src
BIN_DIR := bin
ENV_DIR := env

# -----------------------
# Targets
# -----------------------
TAXONOMY_DOWNLOADER := $(BIN_DIR)/taxonomy_downloader
GENPATHFILES        := $(BIN_DIR)/genPathFiles
BUILDDB             := $(BIN_DIR)/DB_compress
UNIQUEDB            := $(BIN_DIR)/DB_unique
TRANSLATE           := $(BIN_DIR)/translate
LRS                 := $(BIN_DIR)/classify_LRS
LRS_EM              := $(BIN_DIR)/classify_LRS_EM
SRS_GPU             := $(BIN_DIR)/classify_SRS_GPU
CONDA_ENV           := $(ENV_DIR)/metabingv4_env_created

# -----------------------
# Compiler settings
# -----------------------
CXX := g++
CC := gcc
CFLAGS := -O3 -Wall
NVCC := nvcc
NVCCFLAGS := -O3

.PHONY: all clean env install

# -----------------------
# Default target
# -----------------------
all: $(TAXONOMY_DOWNLOADER) $(GENPATHFILES) $(BUILDDB) $(UNIQUEDB) $(TRANSLATE) $(LRS) $(LRS_EM) $(SRS_GPU)

$(TAXONOMY_DOWNLOADER): $(SRC_DIR)/taxonomy.c $(SRC_DIR)/taxonomy.h | $(BIN_DIR)
	@echo "[INFO] Compiling taxonomy_downloader..."
	@$(CC) $(CFLAGS) -o $@ $(SRC_DIR)/taxonomy.c

$(GENPATHFILES): $(SRC_DIR)/genPathFiles.cpp $(SRC_DIR)/helpers.h | $(BIN_DIR)
	@echo "[INFO] Compiling genPathFiles..."
	@$(CXX) -std=c++11 $(CFLAGS) -o $@ $(SRC_DIR)/genPathFiles.cpp

$(BUILDDB): $(SRC_DIR)/DTB_compress.cpp $(SRC_DIR)/helpers.h | $(BIN_DIR)
	@echo "[INFO] Compiling DB_compress..."
	@$(CXX) -std=c++11 $(CFLAGS) -o $@ $(SRC_DIR)/DTB_compress.cpp

$(UNIQUEDB): $(SRC_DIR)/DTB_unique.cpp $(SRC_DIR)/helpers.h | $(BIN_DIR)
	@echo "[INFO] Compiling DB_unique..."
	@$(CXX) -std=c++11 $(CFLAGS) -o $@ $(SRC_DIR)/DTB_unique.cpp

$(TRANSLATE): $(SRC_DIR)/translate.cpp $(SRC_DIR)/helpers.h | $(BIN_DIR)
	@echo "[INFO] Compiling translate..."
	@$(CXX) -std=c++11 $(CFLAGS) -o $@ $(SRC_DIR)/translate.cpp

$(LRS): $(SRC_DIR)/classify_lrs.cpp $(SRC_DIR)/seqreader.cpp $(SRC_DIR)/helpers.h | $(BIN_DIR)
	@echo "[INFO] Compiling classify_LRS..."
	@$(CXX) -fopenmp -std=c++17 $(CFLAGS) -o $@ $(SRC_DIR)/classify_lrs.cpp $(SRC_DIR)/seqreader.cpp

$(LRS_EM): $(SRC_DIR)/classify_lrs_EM.cpp $(SRC_DIR)/seqreader.cpp $(SRC_DIR)/helpers.h | $(BIN_DIR)
	@echo "[INFO] Compiling classify_LRS_EM..."
	@$(CXX) -fopenmp -std=c++17 $(CFLAGS) -o $@ $(SRC_DIR)/classify_lrs_EM.cpp $(SRC_DIR)/seqreader.cpp

$(SRS_GPU): $(SRC_DIR)/classify_srs_gpu.cu | $(BIN_DIR)
	@echo "[INFO] Compiling classify_SRS_GPU..."
	@$(NVCC) $(NVCCFLAGS) -o $@ $< -lcudart -lcublas

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# -----------------------
# Conda environment
# -----------------------
env: $(CONDA_ENV)

$(CONDA_ENV): $(ENV_DIR)/environment.yml $(ENV_DIR)/setup_conda.sh
	@echo "[INFO] Creating conda environment..."
	@bash $(ENV_DIR)/setup_conda.sh
	@touch $@

# -----------------------
# Install scripts locally (no sudo required)
# -----------------------
install: all
	@echo "[INFO] Installing binaries to $(HOME)/.local/bin"
	@mkdir -p $(HOME)/.local/bin
	@cp -f $(BIN_DIR)/* $(HOME)/.local/bin
	@chmod +x $(HOME)/.local/bin/*
	@echo "[INFO] Binaries installed to $(HOME)/.local/bin"
	@echo "[INFO] Make sure ~/.local/bin is in your PATH"

# -----------------------
# Clean up
# -----------------------
clean:
	@echo "[INFO] Removing compiled binaries..."
	@rm -f $(TAXONOMY_DOWNLOADER) $(GENPATHFILES) $(BUILDDB) $(UNIQUEDB) $(TRANSLATE) $(LRS) $(LRS_EM) $(SRS_GPU)
	@echo "[INFO] Removing conda environment flag..."
	@rm -f $(CONDA_ENV)
	@echo "[INFO] Removing installed binaries from ~/.local/bin..."
	@rm -f $(HOME)/.local/bin/taxonomy_downloader
	@rm -f $(HOME)/.local/bin/genPathFiles
	@rm -f $(HOME)/.local/bin/DB_compress
	@rm -f $(HOME)/.local/bin/DB_unique
	@rm -f $(HOME)/.local/bin/translate
	@rm -f $(HOME)/.local/bin/classify_LRS
	@rm -f $(HOME)/.local/bin/classify_LRS_EM
	@rm -f $(HOME)/.local/bin/classify_SRS_GPU
	@echo "[INFO] Clean completed."
