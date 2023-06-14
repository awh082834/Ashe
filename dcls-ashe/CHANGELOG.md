# dcls/ashe: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.03.2.2 - [06.09.23]

### `Added`
Added Chopper module to possibly filter on read quality, will continue to test to see if this is necessary

### `Removed`
Removed PDF report builder utilizing Rmarkdown. R is causing issues, this will be run outside of the pipeline on the output directory

## v1.03.2.1 - [05.19.23]

### `Added`
Added Read N50 and Contig N50 to final report generation to keep an eye on read metrics for cutoff exploration

## v1.03.2 - [04.21.23]

### `Added`
Added iteration parameter to the Flye process and increased iteratons of polishing to 2 rounds to help with species typing.

## v1.03.1 - [04.07.23]

### `Fixed`
Fixed issues with typing processes. Wrong isolates would be put through typing processes and saved in wrong output directories leading to wrong typing on report.  

## v1.03 - [04.06.23]

### `Added`
Added RefSeq sketch for ECTyper to be used in E. coli typing. Located in /bin.
Added SeqSero2 output to final report.

### `Changed`
Workflow name changed to Ashe.

## v1.02 - [03.31.23]

### `Changed`
Changed coverage calculation to correct method of total sequenced bases divided by length of genome

## v1.01 - [03.29.23]

### `Added`
Added depth metric to final report, Report.nf calculates average coverage from Flye assembly_info.txt file. This info file is now part of the collected reportGen channel.

## v1.0dev - [03.28.23]

Initial release of dcls/eualr in a stable state with completed modules, created with the [nf-core](https://nf-co.re/) template.