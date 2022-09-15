if [ "$#" -ne 2 ]; then
	echo "Script requires exactly 1 argument: path containing the ROOT files to merge. Exiting..."
	exit 0
fi

#sizeInMB=`du -ms $1 | awk '{print int($1)}'` # | sed 's|[^0-9\.]||g'` # extract total folder size in GB
sizeInMB=$(eos root://cmseos.fnal.gov/ ls -l $1 | awk '{sum+= int($5 / 1000000)} END{print sum}')
numOutFiles=$(( $sizeInMB / 1000 )) # divide total size by 1GB to obtain total number of out files
numOutFiles=$(( $numOutFiles + 1 )) # add one to account for integer division truncation
numInFiles=$(eos root://cmseos.fnal.gov/ ls -l $1 | wc -l)  # total number of input ROOT files

echo "Total size in MB ${sizeInMB}"
echo "Num output files ${numOutFiles}"
echo "Num in files ${numInFiles}"

if [ $numInFiles -eq 0 ]; then
	echo "No input ROOT files found. Exiting..."
	exit 0
fi
numInFilesPerOutFile=$((numInFiles / numOutFiles))
echo "Total size in MB ${sizeInMB}"
echo "Num output files ${numOutFiles}"
echo "Num in files ${numInFiles}"
echo "Join group size: ${numInFilesPerOutFile}"

for i in `seq 0 $(($numOutFiles-1))`; do
	offset=$(($i * numInFilesPerOutFile))
	offset=$(($offset + 1))
	uuid=$(uuidgen | cut -f1 -d'-')
	numParallelProcs=$(( ($numInFiles - $i * $numInFilesPerOutFile) / 3 ))
	numParallelProcs=$(( $numParallelProcs < 17 ? $numParallelProcs : 16 ))
        eos root://eosuser.cern.ch// mkdir -p /eos/user/c/ckapsiak/TnP_ntuples/$2
        files="$(eos root://cmseos.fnal.gov/ ls "$1" | grep "root" | tail -n +$offset | head -n $numInFilesPerOutFile | awk -v path="$1" '{print "root://cmseos.fnal.gov/" path "/" $0}' )"
	if [ $numParallelProcs -eq 0 ]; then
                echo hadd /eos/user/c/ckapsiak/TnP_ntuples/haddOut_${i}_${uuid}.root  $files
                hadd -f /eos/user/c/ckapsiak/TnP_ntuples/$2/haddOut_${i}_${uuid}.root  $files
	else
            echo hadd -f -j $numParallelProcs /eos/user/c/ckapsiak/TnP_ntuples/$2/haddOut_${i}_${uuid}.root  $files
            hadd -f -j $numParallelProcs /eos/user/c/ckapsiak/TnP_ntuples/$2/haddOut_${i}_${uuid}.root  $files
	fi
done
