#!/bin/bash
outdir=$1
projDir=$2
echo $outdir
for file in "$outdir"/characterization/amrfinder/*.tsv;
do
	sample_name=${file%.tsv}
	sample_name=${sample_name##*/}
	echo $sample_name
	amr_file="$outdir"/characterization/amrfinder/"$sample_name".tsv
	echo $amr_file
	bandage_file="$outdir"/bandage/"$sample_name".png
	echo $bandage_file
	metrics="$outdir"/LR_report.csv
	echo $metrics
	plasmid="$outdir"/characterization/mobRecon/"$sample_name"/mobtyper_results.txt
	echo $plasmid
	Rscript -e "rmarkdown::render(\"$projDir/bin/test.Rmd\",knit_root_dir = \"$outdir\", intermediates_dir = \"$outdir\", output_file=\"$sample_name.pdf\", output_dir=\"$outdir\",params=list(amr=\"$amr_file\", bandage=\"$bandage_file\",metrics=\"$metrics\",plasmid=\"$plasmid\",sample=\"$sample_name\"))"
done

