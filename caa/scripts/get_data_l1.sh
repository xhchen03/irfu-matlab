#!/bin/sh
#
# Script for running c_get_batch_l1 using job_file as input.
# Job file has two columns: start_time [ISO time] and dt [sec]
#
# (c) 2005, Yuri Khotyaintsev
#
# $Id$

error()
{
	echo "$@" 1>&2
	usage_and_exit 1
}

usage()
{
	echo "Usage: $PROGRAM YYYY MM DD [NDAYS]"
}

usage_and_exit()
{
	usage
	exit $1
}

version()
{
	echo "$PROGRAM version $VERSION"
}

get_one_int()
{
	echo Processing $start_time dt=$dt sec ...
	echo "irf_log('log_out','$log_dir/$start_time.log'); caa_get_batch_l1('$start_time',$dt,'$out_dir'); exit" | $MATLAB > $log_dir/$start_time-get_data.log 2>&1	
}

PROGRAM=`basename $0`
VERSION=1.0
MATLABSETUP='TMP=/tmp LD_LIBRARY_PATH=$IS_MAT_LIB:$LD_LIBRARY_PATH'
MATLAB='/usr/local/matlab/bin/matlab -c 1712@flexlmtmw1.uu.se:1712@flexlmtmw2.uu.se:1712@flexlmtmw3.uu.se -nojvm -nodisplay'
#MATLAB=/bin/cat
INT_HOURS=3

if test $# -lt 3
then
	usage_and_exit 1
fi

if test -z $4
then
	NDAYS=1
else
	NDAYS=$4
fi

YYYY=$1
MM=$2
DD=$3

JOBNAME="L1-$YYYY$MM$DD"

out_dir=/data/caa/raw/$JOBNAME
log_dir=/data/caa/log-raw/$JOBNAME

echo Starting job $JOBNAME 
if ! [ -d $out_dir ]
then
	echo creating out_dir: $out_dir
	mkdir $out_dir
fi
if ! [ -d $log_dir ]
then
	echo creating log_dir: $log_dir
	mkdir $log_dir
fi

export $MATLABSETUP
DAYS=0
HOURS=0
while test $DAYS -lt $NDAYS
do
	while test $HOURS -lt 24
	do
		if test $HOURS -lt 10
		then
			HOURS="0$HOURS"
		fi
		start_time=$YYYY-$MM-$DD'T'$HOURS':00:00.000Z'
		dt="$INT_HOURS*60*60"

		get_one_int

		DAYS=$(($DAYS+1))
		HOURS=$(($HOURS+$INT_HOURS))
	done
done
	
echo done with job $JOBNAME
