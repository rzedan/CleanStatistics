#!/bin/bash
#
# CleanStatistics.sh v0.2
# This program read counters and return an easy output for analysis
# 
# Coded by Ricardo Zedan - ericzed
# E-mail: ricardozedan@gmail.com
#
# Global variables:
# Here the variables of paths where is stored the counters

count_path="/opt/occ/var/performance/"

#
# Functions 
#

usage() {
cat << EOF
$0 -p start_date end_date [-b] <b1> [-c]
    -p      Period; Sets the start date and end date
    -b      Second flag; takes in 1 argument
    -c      Third flag; takes in no arguments
EOF
}

show_confignode(){
echo "----------------------------"
echo "Show Node and Config options"
echo "----------------------------"
node_conf=($(cat `ls -1 ${count_path}counters_*log | tail -1` | grep -i "CXC" | awk -F"," '{print $2"+"$4}' | sort | uniq ; echo "All_Config"))
nodeconf_length=${#node_conf[@]}
    for ((i = 0; i != nodeconf_length; i++)); do
	echo "${node_conf[i]}" | tr "+" " "
    done
}

is_flag() {
    # Check if $1 is a flag; e.g. "-b"
    [[ "$1" =~ -.* ]] && return 0 || return 1
}

is_file(){
   # Check if the $1 is a regular counter: e.g. "counters_2017060100.log"
   [[ -f ${count_path}/counters_${1}.log ]] && return 1 || return 0
}

files_notequal(){
   [[ $2 -gt $1 ]] && return 1 || return 0
}

get_startdate(){
   eval start_time=($(cat ${count_path}counters_${1}.log | awk -F"," '{print $1}' | uniq | sed 's/ /\\ /g'))
   
   for ((i = 0; i < ${#start_time[@]}; i++))
      do 
      echo "${i} -> ${start_time[$i]}"
      done
}

get_enddate(){
   eval end_time=($(cat ${count_path}counters_${1}.log | awk -F"," '{print $1}' | uniq | sed 's/ /\\ /g'))

   for ((i = 0; i < ${#end_time[@]}; i++))
      do
      echo "${i} -> ${end_time[$i]}"
      done
}

get_servername(){
   eval server_name=($(awk -F"," '{print $2}' ${count_path}counters_${1}.log | sort | uniq))

   for ((i = 0; i < ${#server_name[@]}; i++))
      do
      echo "${i} -> ${server_name[$i]}"
      done
}

get_configname(){
   eval config_name=($(grep -i "${start_time[$choise_startdate]}" ${count_path}counters_${1}.log | grep -i "${server_name[$choise_servername]}" | awk -F"," '{print $4}' | grep -i CXC | uniq))

   for ((i = 0; i < ${#config_name[@]}; i++))
      do
      echo "${i} -> ${config_name[$i]}"
      done
      echo "a -> All Configs"
}

all_parser(){
declare -A matrix

count_database=($(grep -i "${start_time[$choise_startdate]}" ${count_path}counters_${p1}.log | grep -i ${server_name[$choise_servername]} | awk -F"," '{print $6}' | tr " " "_"))
count_numrows=3 # counter_name / count_start_time / count_end_time
count_numcols=${#count_database[@]}

for ((i=1;i<=count_numrows;i++)) do
    if [[ $i == 1 ]]
    then
    	for ((j=1;j<=count_numcols;j++)) do
        matrix[$i,$j]=${count_database[$j]}
    	done
    elif [[ $i == 2 ]]
    then
	lista=($(grep -i "${start_time[$choise_startdate]}" ${count_path}counters_${p1}.log | grep -i ${server_name[$choise_servername]} | awk -F"," '{print $7}'))
        for ((j=1;j<=count_numcols;j++)) do
        matrix[$i,$j]=${lista[$j]}
        done
    else 
	if [[ $i == 3 ]]
        then
        lista=($(grep -i "${end_time[$choise_enddate]}" ${count_path}counters_${p2}.log | grep -i ${server_name[$choise_servername]} | awk -F"," '{print $7}'))
        for ((j=1;j<=count_numcols;j++)) do
        matrix[$i,$j]=${lista[$j]}
        done
	fi
    fi
done

f1="%$((${#count_numrows}+1))s"
f2="%1s"

echo "Counter|${start_time[$choise_startdate]}|${end_time[$choise_enddate]}|"
#printf "$f1 ---->" ''
#for ((i=1;i<=count_numrows;i++)) do
    #printf "$f2" $i
#done

for ((j=1;j<=count_numcols;j++)) do
    #printf "$f1" $j
    for ((i=1;i<=count_numrows;i++)) do
        #printf "$f2" ${matrix[$i,$j]}
        printf "$f2|" ${matrix[$i,$j]}
    done
    echo
done
}

main_program(){
get_startdate ${p1}
echo -n "Choose the START time: "
read choise_startdate
echo "You choose START date and time as: ${start_time[$choise_startdate]}"
echo

get_enddate ${p2}
echo -n "Choose the END time: "
read choise_enddate
echo "You choose END date and time as: ${end_time[$choise_enddate]}"
echo

get_servername ${p1}
echo -n "Choose the SERVER: "
read choise_servername
echo "You choose SERVER as: ${server_name[$choise__servername]}"
echo

get_configname ${p1}
echo -n "Choose the CONFIG: "
read choise_configname
if [[ ${choise_configname} == a ]] || [[ ${choise_configname} == A ]]  
   then 
	eval config_name="a"
	echo "You choose CONFIG as: All configs"
   else
	echo "You choose CONFIG as: ${config_name[$choise_configname]}"
   fi
echo
all_parser
}

# Note:
# For p, we fool getopts into thinking a doesn't take in an argument
# For b, we can just use getopts normal behavior to take in an argument
while getopts "pb:sc" opt ; do
    case "${opt}" in
        p)
            # This is the tricky part.
            # $OPTIND has the index of the _next_ parameter; so "\$$((OPTIND))"
            # will give us, e.g., $2. Use eval to get the value in $2.

            eval "p1=\$$((OPTIND))"
            eval "p2=\$$((OPTIND+1))"

            # Note: We need to check that we're still in bounds, and that
            # p1,p2 aren't flags and the real counters file exists. 
	    # e.g.
            # ./occCleanStatistics.sh -p 2017060100 -b
            # should error, and not set p2 to be -b.

            if [[ $((OPTIND+1)) > $# ]] || is_flag "$p1" || is_flag "$p2" && [[ $((OPTIND+1)) > $# ]] || is_file "$p1" || is_file "$p2"
            then
                usage
                echo
                echo "-p requires start_date and end_date!"
                exit
            fi
	    
	   if [[ $((OPTIND+1)) > $# ]] || files_notequal "$p1" "$p2"
	   then
	        usage
                echo
                echo "-p requires start_date_hour should be before end_date_hour"
                exit
            fi

            #echo "-p has arguments $p1, $p2"
	    main_program
            ;;
        b)
            # Can get the argument from getopts directly
            echo "-b has argument $OPTARG"
            ;;
        s)
            # No arguments, life goes on
            #echo "-c"
	    get_servername ${teste} 
            ;;
        c)
            # No arguments, life goes on
            #echo "-c"
	    show_confignode
            ;;

	*)  usage
	    ;;
    esac
done
#main_program
