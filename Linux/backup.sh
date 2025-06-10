#!/bin/bash

# Necessary Files and Folders , this PATHS is just for Testing
FILES=(
    /etc/ssh
    /etc/nginx
    /etc/mysql
    /etc/hosts
    /etc/fstab
)

# Path of logs and Vars of TelegramBot , ChatID (administrator) , Message
LOGSPATH="$HOME/Backup/backup_logs"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BOT_TOKEN="" # put ur bot here
CHAT_ID="" # put administrator CHATID here
MESSAGE="NewBackup:$DATE"

mkdir -p $HOME/Backup
sleep 0.2

# am puting this preveleges (666) just for skipping some errors xD, i mean it's just for testing
sudo touch $LOGSPATH
sudo chown $USER:$USER $LOGSPATH
sudo chmod 644 $LOGSPATH

echo "--------NEW BACKUP : $(date)--------" >> $LOGSPATH
echo "$(whoami) is Starting The Backup Script" >> $LOGSPATH

if curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${CHAT_ID}&text=$MESSAGE"; then
            echo "$Backup sent successfully : $CHAT_ID " >> $LOGSPATH
        else
            echo "$Backup Failed to sent : $CHAT_ID , Error : $?" >> $LOGSPATH
        fi

sleep 0.2
rm -rf $HOME/Backup/*.zip

# Loop for every file or folder in the list FILES
for FILE in "${FILES[@]}"; do

    if [ -e "$FILE" ]; then

        echo "$FILE exists" >> $LOGSPATH

        Backup="$HOME/Backup/${DATE}_$(basename $FILE).zip"
        echo "Creating Backup: $Backup"
        sudo zip -r --password "derradji" "$Backup" "$FILE"

        if ! [ $? -eq 0 ]; then
            echo "$FILE Compression Failed" >> $LOGSPATH
            compresult="false"
        else
            echo "$FILE Compressed Successfully" >> $LOGSPATH
            compresult="true"
        fi

        [ "$compresult" = "true" ] && echo -e "\033[0;32mCompression PATH : Done\033[0m" || echo -e "\033[0;31mCompression PATH : Error\033[0m"

        # sending the result of compression to administrator ChatID
        if curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
             -F chat_id="${CHAT_ID}" \
             -F document=@"${Backup}"; then
            echo "File $Backup sent successfully to $CHAT_ID " >> $LOGSPATH
            Tlgrmresult="true"
        else
            echo "File $Backup sending failed , Error : $?" >> $LOGSPATH
            Tlgrmresult="false"
        fi

        [ $Tlgrmresult = "true" ] && echo -e "\033[0;32mSending Files : Done\033[0m" || echo -e "\033[0;31mSending Files : Error\033[0m"

    else
        echo "$FILE does not exist , (compression skip)" >> $LOGSPATH
    fi

done
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${CHAT_ID}&text=________________Done________________"
echo -e "\033[0;34mBackup Script Finished at $(date)\033[0m"
exit 0