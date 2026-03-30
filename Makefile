#
# Makefile for PREDICTING THE EQUITY RISK PREMIUM
#
# Julia rewrite — March 2026
# --------------------------------------------------------------------------------------------------------

SHELL := /bin/bash

# --------------------------------------------------------------------------------------------------------
# Pretty-printing
define colorecho
	@tput setaf 6
	@echo $1
	@tput sgr0
endef

WHITE := '\033[1;37m'
NC    := '\033[0m'

TIME_START := $(shell date +%s)
define TIME-END
	@time_end=`date +%s` ; \
	time_exec=`awk -v "TS=${TIME_START}" -v "TE=$$time_end" 'BEGIN{TD=TE-TS;printf "%02dm:%02ds\n",TD/60,TD%60}'` ; \
	echo -e \\t${WHITE}cumulative time elapsed ... $${time_exec} ... $@ ${NC}
endef
# --------------------------------------------------------------------------------------------------------

## --------------------------------------------------------------------------------------------------------
## ALL
all: output/predict.csv readme.md

## COMPUTE CAY FROM FRED DATA
input/cay_computed.csv: src/CAY.jl src/FredUtils.jl
	$(call colorecho,"Construct cay from FRED data ...")
	julia --project=. src/CAY.jl
	@echo

## GENERATE PREDICTORS
tmp/predict.csv: src/DataImport.jl src/FredUtils.jl input/cay_computed.csv output/msi.csv
	$(call colorecho,"Import and merge all return predictors ...")
	mkdir -p tmp
	julia --project=. src/DataImport.jl
	@echo

## RUN REGRESSIONS
output/predict.csv: src/RiskPremium.jl tmp/predict.csv
	$(call colorecho,"Estimate predictive regression ...")
	julia --project=. src/RiskPremium.jl
	@echo

## OUTPUT RESULTS
readme.md: src/readme_input.txt output/predict.pdf tmp/reg_update.txt
	$(call colorecho,"Update readme file ...")
	cat src/readme_input.txt tmp/reg_update.txt > readme.md
	@echo

## TEST: validate against R reference
test: test/test_cay.jl test/test_dataimport.jl test/test_regression.jl
	$(call colorecho,"Running validation tests ...")
	julia --project=. test/test_dataimport.jl
	julia --project=. test/test_regression.jl
	@echo

## --------------------------------------------------------------------------------------------------------
## help (this call)
.PHONY: help test clean
help: Makefile
	@sed -n 's/^##//p' $<

## clean
clean:
	rm -rf output/predict.csv output/predict.pdf
	rm -rf log/*.log*
	rm -rf tmp/*
	rm -rf readme.md

## --------------------------------------------------------------------------------------------------------
