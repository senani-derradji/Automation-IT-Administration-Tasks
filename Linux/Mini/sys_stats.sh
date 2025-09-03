#!/bin/bash

# Variables
tm=$(date +"%H:%M:%S")
dt=$(date +"%d %b")

used_disk=$(df -h "/" | awk 'NR==2 {print $3}')
free_disk=$(df -h "/" | awk 'NR==2 {print $4}')
size_disk=$(df -h "/" | awk 'NR==2 {print $2}')

cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')

mem_used=$(free -h | awk '/Mem:/ {print $3}')
mem_total=$(free -h | awk '/Mem:/ {print $2}')

col_width=20

cyan="\033[36m"
green="\033[32m"
blue="\033[34m"
red="\033[31m"
reset="\033[0m"


echo -e "$(cat <<EOF
=================================================
|                 ${cyan}System Report${reset}                  |
=================================================
| DATE                  | DISK                   |
-------------------------------------------------
| Time: ${cyan}$tm${reset}         | USED : ${green}$used_disk${reset}            |
| Date: ${cyan}$dt${reset}           | FREE : ${green}$free_disk${reset}           |
|                       | SIZE : ${green}$size_disk${reset}             |
-------------------------------------------------
| ${cyan}CPU Usage${reset}          | ${green}$cpu_usage${reset}                      |
| ${cyan}Memory Used${reset}        | ${green}$mem_used${reset} ${blue}/${reset} ${red}$mem_total${reset}             |
=================================================
EOF
)"