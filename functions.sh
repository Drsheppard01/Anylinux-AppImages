#!/bin/sh
set -eu

## tools that will be used next

get_appimagetool() {
    wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage
    chmod +x appimagetool-$ARCH.AppImage
}

get_lib4bin() {
    wget https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin
    chmod +x lib4bin
}

get_uruntime() {
    wget -q https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH
    chmod +x uruntime-appimage-dwarfs-$ARCH
}

get_uruntime-lite() {
    wget -q https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH
    chmod +x uruntime-appimage-dwarfs-lite-$ARCH

}

make_appdir() {
    mkdir -p .AppDir/usr/{lib,bin}/
    mkdir -p .AppDir/usr/share/{icons,metainfo}
}

build() {
    CURRENTDIR="$(readlink -f "$(dirname "$0")")"
    git clone $REPO
}

sharun() {
    ln -s ./bin/$APP ./AppRun
    ./sharun -g
}

generate_app() {
    printf "$UPINFO" > data.upd_info
    llvm-objcopy --update-section=.upd_info=data.upd_info \
    --set-section-flags=.upd_info=noload,readonly ./uruntime
    printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc
    wget -q "$URUNTIME" -O ./uruntime
    chmod +x ./uruntime
    ./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S24 -B16 \
	--header uruntime \
	-i ./AppDir -o "$PACKAGE"-"$VERSION"-anylinux-"$ARCH".AppImage
}

generate_desktopfile() {
    cat >> ./$app.desktop << 'EOF'
    [Desktop Entry]
    Name=$APP
    Type=Application
    Icon=$icon
    Exec=$app 
    Categories=;
    Terminal=false
EOF
}

copy_udev-rules() {
    cat >> AppRun << 'EOF'
    if [ ! -f "/etc/udev/rules.d/$udevrules" ]; then
	echo "/etc/udev/rules.d/$udevrules file not found!"
	echo "Ignore if udev is not supported by your system"
	echo "To fix this, rerun this command with --getudev"
	notify-send -u critical "/etc/udev/rules.d/$udevrules file not found! To fix this, rerun this command with --getudev for the first time when setting up" || true # Send a user prompt but ignore errors, in case it doesn't exist
fi

if [ "$1" = '--getudev' ]; then
	if [ -f "/etc/udev/rules.d/$udevrules" ]; then
		echo "udev rule already found, skipping Rule Creation"
	else
		# Create udev rule file
		if command -v sudo >/dev/null 2>&1; then
			SUDOCMD="sudo"
		elif command -v doas >/dev/null 2>&1; then
			SUDOCMD="doas"
		else
			echo "ERROR: You need sudo or doas to use this function"
			exit 1
	    fi
	    echo "Adding New udev Rule"
	    "$SUDOCMD" mkdir -p /etc/udev/rules.d/
	    cat <<- 'EOF' | "$SUDOCMD" tee /etc/udev/rules.d/"$udevrules"
    #### your udev rules there
    EOF
	"$SUDOCMD" udevadm control --reload-rules
	echo "Udev rules successfully created"
	fi
fi
EOF
}
