#
# Makefile for PREDICTING THE EQUITY RISK PREMIUM
#
# Julia rewrite — March 2026
## --------------------------------------------------------------------------------------------------------

## --------------------------------------------------------------------------------------------------------
## LOAD A FEW OPTIONS
-include ./rules.mk
## --------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------
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
readme.md: src/readme_in.md output/predict.pdf tmp/reg_update.txt
	$(call colorecho,"Update readme file ...")
	cat src/readme_in.md tmp/reg_update.txt > readme.md
	@echo

## TEST: validate against R reference
test: test/test_cay.jl test/test_dataimport.jl test/test_regression.jl
	$(call colorecho,"Running validation tests ...")
	julia --project=. test/test_dataimport.jl
	julia --project=. test/test_regression.jl
	@echo

##
## --------------------------------------------------------------------------------------------------------
## help (this call)
.PHONY : help test
help : Makefile
	@sed -n 's/^##//p' $<

## clean
.PHONY : clean
clean:
	rm -rf ./output/predict.csv ./output/predict.pdf
	rm -rf ./log/*.log*
	rm -rf ./tmp/*
	rm -rf readme.md

##
# --------------------------------------------------------------------------------------------------------
