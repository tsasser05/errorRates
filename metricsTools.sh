#!/bin/bash


######################################################################
#
# MetricsTools for bash
#
#
######################################################################

######################################################################
#
# accessLogTimeSliceRE $DATESTR $FIRSTHOUR $LASTHOUR
#
# DATESTR   = DD/Mon/YYYY format for new access logs
# FIRSTHOUR = First hour
# LASTHOUR  = Last hour you want
#
# Returns a string suitable for use in egrep regular expressions.
#
# TIMESLICEACCESS is defined as a string.  Use $TIMESLICEACCESS 
# anywhere in your script.
#
# Example:
#
# #!/bin/bash
# . /opt/lib/metricsTools.sh
# accessLogTimeSliceRE "11/Aug/2010" 3 3
# echo "--->$TIMESLICEACCESS<---"
# egrep "$TIMESLICEACCESS" "access_log.2010-08-11.txt"
#
#
######################################################################

function accessLogTimeSliceRE () {
    DATESTR=$1
    FIRSTHOUR=$2
    LASTHOUR=$3

    RANGE=""
    TIMESLICEACCESS=""

    for HR in `for (( x=$FIRSTHOUR; x<=$LASTHOUR; x+=1 )); do printf "%02d " "$x"; done`; do
	RANGE="$RANGE|$HR"

    done

    RANGE=${RANGE#|}
    TIMESLICEACCESS="^\[$DATESTR:($RANGE):[0-9][0-9].*"

} # accessLogTimeSliceRE


######################################################################
#
# navLogTimeSliceRE $DATESTR $FIRSTHOUR $LASTHOUR
#
# DATESTR   = YYYY-MM-DD format for nav logs
# FIRSTHOUR = First hour
# LASTHOUR  = Last hour you want
#
# Returns a string suitable for use in egrep regular expressions.
#
# TIMESLICENAV is defined as a string.  Use $TIMESLICENAV anywhere
# in your script.
#
# Example:
#
# #!/bin/bash
# . /opt/lib/metricsTools.sh
# navLogTimeSliceRE "2010-07-29" 12 12
# echo "--->$TIMESLICENAV<---"
# egrep "$TIMESLICENAV" "nav.log"
#
#
######################################################################

function navLogTimeSliceRE () {
    DATESTR=$1
    FIRSTHOUR=$2
    LASTHOUR=$3

    RANGE=""
    TIMESLICENAV=""

    for HR in `for (( x=$FIRSTHOUR; x<=$LASTHOUR; x+=1 )); do printf "%02d " "$x"; done`; do
	RANGE="$RANGE|$HR"

    done

    RANGE=${RANGE#|}
    TIMESLICENAV="^$DATESTR ($RANGE):[0-9][0-9].*"

} # navLogTimeSliceRE


######################################################################
#
# getNavTimeSlice $SERVER $NAV $DATESTR $FIRSTHOUR $LASTHOUR
#
# SERVER    = FQDN of the server
# NAV       = nav instance you want to check.  Either 1 or 2 for tomcat.
# DATESTR   = YYYY-MM-DD
# FIRSTHOUR = First hour to pull
# LASTHOUR  = Last hour to pull
#
# Prints all result lines to STDOUT.
#
# Example:
#
# getNavTimeSlice "FQDN" 1 "2010-08-13" 1 2
#
#
######################################################################

function getNavTimeSlice () {
    SERVER=$1
    NAV=$2
    DATESTR=$3
    FIRSTHOUR=$4
    LASTHOUR=$5

    navLogTimeSliceRE "$DATESTR" $FIRSTHOUR $LASTHOUR

    ssh $SERVER "egrep \"$TIMESLICENAV\" "/opt/tomcat/nav$NAV/logs/nav.log""

} # getNavTimeSlice ()


######################################################################
#
# getAccessTimeSlice $SERVER $NAV $DATESTR $LOGDATE $FIRSTHOUR $LASTHOUR
#
# SERVER    = FQDN of the server
# NAV       = nav instance you want to check.  Either 1 or 2 for tomcat.
# DATESTR   = DD/Mon/YYYY (in log)
# LOGDATE   = YYYY-MM-DD (for access_log.YYYY-MM-DD.txt)
# FIRSTHOUR = First hour to pull
# LASTHOUR  = Last hour to pull
#
# Prints all result lines to STDOUT.
#
# Example:
#
# getAccessTimeSlice "FQDN" 1 "12/Aug/2010" "2010-08-12" 1 2
#
#
######################################################################

function getAccessTimeSlice () {
    SERVER=$1
    NAV=$2
    DATESTR=$3
    LOGDATE=$4
    FIRSTHOUR=$5
    LASTHOUR=$6

    LOGFILE="access_log.$LOGDATE.txt"

    accessLogTimeSliceRE "$DATESTR" $FIRSTHOUR $LASTHOUR

    ssh $SERVER "egrep \"$TIMESLICEACCESS\" "/opt/tomcat/nav$NAV/logs/$LOGFILE""

} # getAccessTimeSlice ()

