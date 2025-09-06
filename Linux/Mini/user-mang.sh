# !bin/bash
# User management Script

while true; do
	clear
	echo " ==================="
	echo "| SYSTEM MANAGEMENT |"
	echo " =================="
	echo "1) add user"
	echo "2) delete user"
	echo "3) create user password"
	echo "4) show all users"
	echo "5) add new group"
	echo "6) add user to group"
	echo "7) exit"
	read -p "select a number : " choice

	case $choice in
		1) 
			read -p "enter username : " username
			read -p "enter home dir (enter for default) : " homedir
			read -p "entre the shell (/bin/bash) : " usershell
			if [ -z "$homedir" ]; then
				useradd -m -s "$usershell" "$username"
			else
				useradd -m -d "$homedir" -s "$usershell" "$username"
			fi
			passwd "$username"
			echo "user $username added"
			;;
		2)
			read -p "username : " username
			read -p "do u want to delete home directory (y/n) : " confirm
			if [ "$confirm" == "y" || "$confirm" == "yes" ]; then
				userdel -r "$username"
			else
				userdel "$username"
			fi
			echo "user $username are deleted !"
			;;
		3)
			read -p "username : " username
			passwd $username
			echo "password of $username added !"
			;;
		4)
			echo "users list :"
			cut -d: -f1,3,4,7 /etc/passwd | column -t -s
			;;
		5)
			read -p "enter group name : " grpname
			groupadd "$grpname"
			echo "group $groname created !"
			;;
		6)
			read -p "enter username : " username
			read -p "enter groupname : " grpname
			usermod -aG "$grpname" "$username"
			echo "user $username are added to $grpname"
			;;
		7)
			echo "exit ...."
			exit 0
			;;
		*)
			echo "try a valid option !!"
			;;
	esac
	read -p "enter to continue ..."
done




