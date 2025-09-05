# !bin/bash
# recycle_bin project

# just for first time | do it by urself
# sudo mkdir -p /etc/recycle
# sudo chmod 777 /etc/recycle


RECYCLE_BIN="/etc/recycle"
NOW="$(date +"%Y-%m-%d_%H-%M-%S")"


if [[ $1 == "--file"  ]]; then
	file=$2
	if [[ -f "$file"  ]]; then
		mv "$file" "$RECYCLE_BIN/$(basename "$file")_$NOW"
		echo -e "$file \033[32mare Moved to RecycleBin !"
	else
		echo -e "$file \033[31mare not found !"
	fi

elif [[ $1 == "--dir"  ]]; then
	dir=$2
	if [[ -d "$dir"  ]]; then
		mv "$dir" "$RECYCLE_BIN/$(basename "$dir")_$NOW"
                echo -e "$dir \033[32mare Moved to RecycleBin !"
	else
		echo -e "$dir \033[31mare not found !"
	fi

else
    echo -e "\033[32mUsage: \033[36mrmrc --file <file_name> | --dir <dir_name>"
fi


# CRONJOB FOR CLEAN THE RECYCLEBIN EVERY 10 DAYS
# sudo crontab -l 2>/dev/null | { cat; echo "0 0 */10 * * rm -rf /etc/recycle/*"; } | sudo crontab -

# ADD AS AN ALIAS
# pwd ($HOME/Automation-IT-Administration-Tasks/Linux/Mini)
# vim/nano $HOME/.bashrc
# add : alias rmrc="$HOME/Automation-IT-Administration-Tasks/Linux/Mini/recycle_bin.sh"
# source $HOME/.bashrc
