#!/bin/bash
DIR=$(dirname "$0")
vivado -nolog -nojournal $DIR/work/fpga-curves/fpga-curves.xpr
