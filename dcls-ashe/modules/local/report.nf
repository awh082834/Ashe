process REPORT {
    tag "Building Report"

    label "process_low"

    input:
    val (reportList)
    
    output:
    path ("*.csv"), emit: finalReport

    script:
    """
    #!/usr/bin/env python
    import csv

    inputString = "$reportList"

    list = inputString.split(",")
    newList = []
    for elm in list:
        elm = elm.strip()
        elm = elm.replace("[","")
        elm = elm.replace("]","")
        newList.append(elm)


    #Create dictionary associating each file with the sample it belongs to
    def get_files(list):
        dict = {}
        for elm in list:
            if '/' in elm:
                splitA = elm.split('/')
                id = splitA[len(splitA)-2]
                if id not in dict:
                    pathList = []
                    pathList.append(elm)
                    dict[id] = pathList
                else:
                    tempList = dict[id]
                    tempList.append(elm)
                    dict[id] = tempList

        return dict

    #Builds the report using CSV writer
    def build_report(dict):
        with open('LR_report.csv', mode='w') as outFile:
            
            #Creates and Writes Headers
            fieldNames = ['Sample', 'ReadQ', 'Depth', 'Read N50', 'Length', 'Contigs', 'Contig N50', 'Species','Subspecies', 'Subspecies Note', 'Plasmids']
            writer = csv.writer(outFile, delimiter='\t')
            writer.writerow(fieldNames)

            #Template row to be edited over the course of the script
            #Allows for - to delineate a missing value
            row = ['-','-','-','-','-','-','-','-','-','-','-']

            #Iterate over dictionary of {Sample: [List of Files]}
            for key in dict.keys():
                id = key
                row[0] = id
                fileList = dict[key]

                #Iterate over file list for a given sample
                for elm in fileList:
                    
                    #If the file is a Quast transposed report....
                    if 'transposed_report.tsv' in elm:
                        with open(elm, mode='r') as quast:
                            lineCount = 1
                            for line in quast:
                                if lineCount == 1:
                                    lineCount +=1
                                else:
                                    lineList = line.split("\t")
                                    #assign contig count
                                    row[5] = lineList[1]
                                    #assign total length
                                    total_len = int(lineList[7])
                                    row[4] = lineList[7]
                                    row[6] = lineList[16]
                            quast.close()
                    
                    #If the file is a NanoPlot statistics report....
                    elif 'NanoStats.txt' in elm:

                        with open(elm, mode='r') as read_stat:
                            for line in read_stat:
                                if 'mean_qual' in line:
                                    row[1] = line.split()[1]
                                elif 'number_of_bases' in line:
                                    num_bases = float(line.split()[1])
                                elif 'n50' in line:
                                    row[2] = float(line.split()[1])
                            read_stat.close()

                    #If the file is a result of mob_typer....
                    elif 'mobtyper' in elm:
                        with open(elm, mode='r') as mob:
                            plasList = []
                            for line in mob:
                                if 'sample_id' not in line:
                                    lineList = line.split()
                                    plasList.append(lineList[0].split(':')[1])
                            row[8] = plasList
                            mob.close()

                    #If the file is the output of Mash Dist....
                    elif '_sorted' in elm:
                        with open(elm, mode='r') as species:
                            lines = species.readlines()
                            temp = lines[0].split()
                            temp = temp[0].split("-")
                            temp = temp[len(temp)-1].replace('.fna','')
                            temp = temp.split("_")
                            row[5] = temp[0] + "_" + temp[1]
                            species.close()

                    #If the file is the output of ECTyper....
                    elif '_ectype.tsv' in elm:
                        with open(elm, mode='r') as ectyper:
                            for line in ectyper:
                                if 'Name' not in line:
                                    lineList = line.split('\t')
                                    row[6] = lineList[4]
                                    row[7] = lineList[5]
                            ectyper.close()

                    #If the file is the output of EmmTyper....
                    elif 'emmType.tsv' in elm:
                        with open(elm, mode='r') as ectyper:
                            for line in ectyper:
                                lineList = line.split()
                                row[6] = lineList[2]
                            ectyper.close()

                    #If the file is an output from SeqSero2....
                    elif 'SeqSero_result.tsv' in elm:
                        with open(elm, mode='r') as seqsero:
                            for line in seqsero:
                                if 'Sample' not in line:
                                    lineList = line.split('\t')
                                    row[6] = lineList[8]
                            seqsero.close()

                #Calculation for rough average depth across the sequence
                row[2] = round(num_bases/total_len, 3)
                    
                #After each file of a given sample has been gone through
                #and the row list is fully edited it is written to the outfile
                writer.writerow(row)
                row = ['-','-','-','-','-','-','-','-','-']
    build_report(get_files(newList))  
    """
}