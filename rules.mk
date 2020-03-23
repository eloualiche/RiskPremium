#
# RULES for MAKEFILE for the entry and asset pricing Project
#
#
#
# Created       March 24th  2020
# Last modified March 24th  2020
#
#
# --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
ifndef RULES_MK
RULES_MK:=1# Allow repeated "-include".


# --------------------------------------------------------------------------------------------------------
# HOMEMADE SCRIPTS
define colorecho
      @tput setaf 6
      @echo $1
      @tput sgr0
endef
WHITE='\033[1;37m'
NC   ='\033[0m' # No Color

 # Timing: see here https://stackoverflow.com/questions/8483149/gnu-make-timing-a-build-is-it-possible-to-have-a-target-whose-recipe-executes
 TIME_START := $(shell date +%s)
 define TIME-END
 	@time_end=`date +%s` ; time_exec=`awk -v "TS=${TIME_START}" -v "TE=$$time_end" 'BEGIN{TD=TE-TS;printf "%02dm:%02ds\n", TD/(60),TD%60}'` ; echo -e \\t${WHITE}cumulative time elapsed ... $${time_exec} ... $@ ${NC}
endef
# --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
# This will depend on your configuration. Easiest is to symlin latest julia to /usr/bin/julia
SHELL    := /bin/bash
WRDS_USERNAME := XXXX # adjust your WRDS username here
R_OPTS   := --vanilla
# --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
endif