#!/bin/bash
#file organizer by senani-derradji

cyan="\033[36m"
green="\033[32m"
red="\033[31m"
reset="\033[0m"

read -p "📂 Enter the Folder Path :" dir

if [ ! -d "$dir" ]; then
	echo "This Directory Deos No Exist !"
	exit 1
fi

mkdir -p "$dir/images"  "$dir/videos"  "$dir/archives"  "$dir/docs" "$dir/other"

for file in "$dir"/*; do
 
	if [ -f $file ]; then
		case "${file##*.}" in
			  jpg|jpeg|png|gif|bmp) 
				  mv $file "$dir/images/"
				  echo -e "${cyan} $file ${red}--->${green} $dir/images" ;;
			  mp4|mkv|avi|mov) 
				  mv $file "$dir/videos/"
				  echo -e "${cyan} $file ${red}--->${green} $dir/videos" ;;
			  pdf|doc|docx|txt|xls|xlsx|ppt|pptx) 
				  mv $file "$dir/docs/" 
				  echo -e "${cyan} $file ${red}--->${green} $dir/docs" ;;
		          zip|tar|gz|rar) 
				  mv "$file" "$dir/archives/" 
				  echo -e "${cyan} $file ${red}--->${green} $dir/archives" ;;
			  *) 
				  mv $file "$dir/other"
				  echo -e "${cyan} $file ${red}--->${green} $dir/other" ;;
		esac
	fi
done

echo "✅ Files have been organized successfully!"


