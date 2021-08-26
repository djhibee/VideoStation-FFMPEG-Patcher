#!/bin/bash

###############################
#	LIFECYCLE
###############################
function welcome_motd() {
	echo "[INFO] ffmpeg-patcher v1.2"

	motd=$(curl -s -L "https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/motd.txt?raw=true")
	if [ "${#motd}" -ge 1 ]; then
		echo "[INFO] Message of the day:"
		echo ""
		echo "$motd"
		echo ""
	fi
}

function save_and_patch() {
	cp -n /var/packages/VideoStation/target/lib/libsynovte.so /var/packages/VideoStation/target/lib/libsynovte.so.orig
	chown VideoStation:VideoStation /var/packages/VideoStation/target/lib/libsynovte.so.orig

	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' /var/packages/VideoStation/target/lib/libsynovte.so
}

function restart_videostation() {
	if [[ -d /var/packages/CodecPack/target/bin ]]; then
  		echo "[INFO] Restarting CodecPack..."
		synopkg restart CodecPack
	fi

	echo "[INFO] Restarting VideoStation..."
	synopkg restart VideoStation
}

function end_patch() {
	echo ""
	echo "[SUCCESS] Done patching, you can now enjoy your movies ;)"
}


################################
#	PATCH PROCEDURES
################################
function armv8_procedure() {
	echo "[INFO] Running ARMv8 procedure"
	echo "[INFO] Saving current ffmpeg as ffmpeg.orig"
	mv -n /var/packages/VideoStation/target/lib/ffmpeg /var/packages/VideoStation/target/lib/ffmpeg.orig

	echo "[INFO] Downloading patched ffmpeg files to /var/packages/VideoStation/target/lib"
	echo ""

	declare -a ffmpegfiles=(
		"libavcodec.so.56"
		"libavdevice.so.56"
		"libavfilter.so.5"
		"libavformat.so.56"
		"libavutil.so.54"
		"libpostproc.so.53"
		"libswresample.so.1"
		"libswscale.so.3"
	);

	if [[ ! -d /var/packages/VideoStation/target/lib/ffmpeg ]]; then
		echo "[INFO] Creating ffmpeg directory"
		mkdir /var/packages/VideoStation/target/lib/ffmpeg
	fi

	for file in "${ffmpegfiles[@]}"
	do
		echo "[INFO] Downloading $file ..."
		wget -q -O "/var/packages/VideoStation/target/lib/ffmpeg/$file" "https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/ffmpeg/$file?raw=true"
	done

	if [[ -d /var/packages/CodecPack/target/lib/ffmpeg27 ]]; then
		echo "[INFO] Creating symbolic link from CodecPack ffmpeg directory"
		mv /var/packages/CodecPack/target/lib/ffmpeg27 /var/packages/CodecPack/target/lib/ffmpeg27.orig
		ln -s /var/packages/VideoStation/target/lib/ffmpeg /var/packages/CodecPack/target/lib/ffmpeg27
	fi

  	save_and_patch
  	restart_videostation
	end_patch
}

function wrapper_procedure() {
	echo "[INFO] Running wrapping procedure"
	
	# only change advanced media ffmpeg versions and keep video station's one untouched
	# as in https://github.com/darknebular/Wrapper_VideoStation
	
  	if [[ -d /var/packages/CodecPack/target/bin ]]; then
  		cpackfiles=($(ls /var/packages/CodecPack/target/bin | grep ffmpeg))

  		for file in "${cpackfiles[@]}"
  		do
		      echo "[INFO] Patching CodecPack's $file..."
		      if  [[ $file = "ffmpeg33" ]] 
		      then
  				mv "/var/packages/CodecPack/target/bin/$file" "/var/packages/CodecPack/target/bin/$file.orig"
  				wget -O - https://raw.githubusercontent.com/darknebular/Wrapper_VideoStation/main/ffmpeg33-wrapper > "/var/packages/CodecPack/target/bin/$file"
				chmod 755 "/var/packages/CodecPack/target/bin/$file"
		      elif [[ $file = "ffmpeg41" ]] 
		      then
  				mv "/var/packages/CodecPack/target/bin/$file" "/var/packages/CodecPack/target/bin/$file.orig"
  				wget -O - https://raw.githubusercontent.com/darknebular/Wrapper_VideoStation/main/ffmpeg41-wrapper > "/var/packages/CodecPack/target/bin/$file"
				chmod 755 "/var/packages/CodecPack/target/bin/$file"
		      else
		      		echo "Do not change $file as not in the wrapper requirement list"
		      fi
		done
	fi

  	save_and_patch
  	restart_videostation
  	end_patch
}


################################
#	ENTRYPOINT
################################
forcewrapper=false

while getopts "f" option
do
	case $option in
		f)
			forcewrapper=true
			;;
	esac
done

if [[ $(cat /proc/cpuinfo | grep 'model name' | uniq) =~ "ARMv8" && $forcewrapper == false ]]; then
  	armv8_procedure
else
  	wrapper_procedure
fi
