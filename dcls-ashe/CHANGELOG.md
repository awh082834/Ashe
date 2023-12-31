# dcls/ashe: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.4.8 - [12.29.23]

### Added
ErrorStrategy set to ignore for Rotate.nf (DNAapler) so that if rotation genes are not found it will not terminate whole analysis
1000 bp length threshold added to the Chopper modules for filtering

## v1.4.7.1 - [09.12.23]

### Added
database.nf includes check for previously copied databases. They will copy to bin folder on first run however after that it will check if they exist in the bin or not. 

## v1.4.7 - [09.11.23]

### Added
New Processes; Rotate and Databases. Rotate is used to rotate circular assemblies prior to polish. Databases used to copy databases used to bin dir.

### Fixed
Database handling for ECTyper, Mash, and Homopolish.

## v1.4.6.2 - [08.30.23]
Added and ignore error strategy to Flye in order to process blanks without pipeline crashing.

## v1.4.6.2 - [08.30.23]
Moved Database flags to required in schema and config updates.

## v1.04.6.1 - [08.08.23]
Removed capture of unnecessary files

## v1.04.6 - [08.02.23]

### `Removed` 
Removed flags for Homopolish, ECTyper, and Mash databases. These will be manually added to the bin directory and the process will handle it. 

## V1.04.5 - [07.26.23]

### `Fixed`
Fixed database and mash handling for Homopolish, Mash, and ECTyper.
Fixed final report format errors

## v1.04.4 - [06.16.22]

### `Added`
Addition of ectyper_db and mash_db to the run command, both databases used for species typing. Databases will have to be downloaded by user in order to lighten load on Github repo.

### `Removed`
Removal of databases for ECTyper and Mash from bin directory of pipeline.

## v1.04.3 - [06.15.22]

### `Added`
Addition of --polish_db parameter on run command, used for bacteria.msh to be passed to Homopolish. 
    This was done to isolate the large database file for uploading to Github. It will be on the user to download and pass off the database.

### `Removed`
Removal of bacteria.msh from bin.
 
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
