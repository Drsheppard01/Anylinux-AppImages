#!/bin/sh

set -e

APPNAME=MyApp
AUTHOR=MyName
APPID=domain.${AUTHOR}.${APPNAME}
Project_License= # https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html#tag-project_license
Metadata_License=CC0-1.0 #https://www.freedesktop.org/software/appstream/docs/chap-Quickstart.html#qsr-app-contents

# Creating file structure
mkdir -p ./build/data/

# Creating app.desktop file
cat <<- 'EOF' > ./build/data/${APPID}.desktop
Version=1.0
Encoding=UTF-8
Name=${APPID}
Exec= %U
Terminal=false
Icon={APPID}.svg
StartupWMClass=${APPID}
Type=Application
Categories=
Keywords=
MimeType=;
Actions=
EOF

# Creating app.metainfo.xml file
cat <<- 'EOF' > ./build/data/app.metainfo.xml
<?xml version="1.0" encoding="utf-8"?>
<component type="desktop-application">
  <id>${APPID}</id>
  <name>${APPNAME}</name>
  <summary></summary>
  <metadata_license>${Metadata_License}</metadata_license>
  <project_license>${Project_License}</project_license>
  <content_rating type="oars-1.0"/>
    <content_attribute id=""></content_attribute> <!-- https://hughsie.github.io/oars/attributes.html -->
  </content_rating>

  <description>
    <p></p>
    <p>Features</p>
    <ul>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
    </ul>
  </description>
  <url type="homepage">Main webpage</url>
  <url type="bugtracker">/issues</url>
  <url type="translate">/translate</url>
  <url type="contact">/about</url>
  <url type="vcs-browser"></url>
  <url type="contribute"></url>
  <developer id="reverse dns">
    <name>developer</name>
  </developer>
  <launchable type="desktop-id">${APPID}.desktop</launchable>
  <branding>
    <color type="primary" scheme_preference="light"></color>
    <color type="primary" scheme_preference="dark"></color>
  </branding>
  <supports>
    <control>pointing</control>
    <control>keyboard</control>
    <control>touch</control>
  </supports>
  <requires>
    <display_length compare="ge">360</display_length> <!-- https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html#tag-relations-display_length It helps your app user know it's possible to run on Linux phones or not-->
  </requires>
  <screenshots>
    <screenshot type="default">
      <caption>The main screenshot</caption>
      <image type="source">https://raw.githubusercontent.com/jeffvli/feishin/development/media/preview_home.png</image>
    </screenshot>
  </screenshots>
  <categories>
    <category></category>
    <category></category>
    <category></category>
    <category></category>
  </categories>
  <releases>
    <release date="" type="stable" version=""></release>
  </releases>
</component>
EOF

# creating CI/CD workflow
mkdir -p .github/workflows
cat <<- EOF -> .github/workflows/build.yml
name: Anylinux-AppImage
concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true
on:
  push:
    branches: [ main ]
  workflow_dispatch: {}

jobs:
  build:
    name: "${{ matrix.name }} (${{ matrix.arch }})"
    runs-on: ${{ matrix.runs-on }}
    strategy:
      matrix:
        include:
          - runs-on: ubuntu-latest
            name: Build AppImage
            arch: x86_64
          # comment out these 3 lines if aarch64 is not wanted
          - runs-on: ubuntu-latest-arm
            name: Build AppImage
            arch: aarch64
    container: ghcr.io/pkgforge-dev/archlinux:latest
    steps:
      - uses: actions/checkout@v6
      - name: Preparing Container
        uses: pkgforge-dev/anylinux-setup-action@v2
      - name: Install Dependencies
        run: /bin/sh ./get-dependencies.sh
      - name: Make AppImage
        run: /bin/sh ./make-appimage.sh
      - name: Upload artifact
        uses: actions/upload-artifact@v7
        with:
          name: AppImage-${{ matrix.arch }}
          path: dist

  release:
    if: ${{ github.ref_name == 'main' }}
    needs: [build]
    permissions: write-all
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v8
        with:
          pattern: AppImage-*
          merge-multiple: true
      - name: Release AppImage
        uses: pkgforge-dev/make-stable-appimage-release@v1
EOF
