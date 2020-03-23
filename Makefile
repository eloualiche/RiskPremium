#
# Makefile for PREDICTING THE EQUITY RISK PREMIUM
#
# Created       on June  04th 2019
# Last modified on March 23rd 2020
## --------------------------------------------------------------------------------------------------------



## --------------------------------------------------------------------------------------------------------
## LOAD A FEW OPTIONS
-include ./rules.mk
## --------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------
## ALL
all: output/predict.csv readme.md

##
## DOWNLOAD THE DATA FROM WRDS
## Edit rules.mk to change your user name under WRDS_USERNAME
input/msi.sas7bdat: 
	$(call colorecho,"Download stock market index from crsp ...")
	rsync -aPvzh --stats --human-readable  ${WRDS_USERNAME}@wrds-cloud.wharton.upenn.edu:/wrds/crsp/sasdata/a_stock/msi.sas7bdat ./input/
	@echo

## GENERATE PREDICTORS
tmp/predict.csv: src/import_predictors.R input/cay_current.csv input/msi.sas7bdat
	$(call colorecho,"Import and merge all return predictors ...")
	R CMD BATCH $(R_OPTS) src/import_predictors.R log/import_predictors.log.R
	@echo

## RUN REGRESSIONS
output/predict.csv: src/rp_measure.R tmp/predict.csv
	$(call colorecho,"Estimate predictive regression ...")
	R CMD BATCH $(R_OPTS) src/rp_measure.R log/rp_measure.log.R
	@echo

## OUTPUT RESULTS
readme.md: src/readme_in.md output/predict.png tmp/reg_update.txt
	$(call colorecho,"Update readme file ...")
	cat src/readme_in.md tmp/reg_update.txt > readme.md
	@echo

##
## --------------------------------------------------------------------------------------------------------
## help (this call)
.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<

## clean
.PHONY : clean
clean:
	rm -rf ./output/*
	rm -rf ./log/*.log*
	rm -rf ./tmp/*	
	rm -rf readme.md

##
# --------------------------------------------------------------------------------------------------------



