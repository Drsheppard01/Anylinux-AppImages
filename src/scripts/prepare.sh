#!/bin/sh

set -euxo pipefail

# Creating file structure
mkdir -p /build/data/

# Creating app.desktop file
cat <<- 'EOF' > /build/data/domain.Author.AppName.desktop
Version=1.0
Encoding=UTF-8
Name=
Exec=chrome %U
Terminal=false
Icon=
StartupWMClass=
Type=Application
Categories=Network;WebBrowser;
Keywords=web;browser;internet;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;
Actions=new-window;new-private-window
EOF

# Creating app.metainfo.xml file
cat <<- 'EOF' > /build/data/app.metainfo.xml
<?xml version="1.0" encoding="utf-8"?>
<component type="desktop-application">
  <id>domain.Author.AppName</id>
  <name>AppName</name>
  <summary></summary>
  <metadata_license>https://www.freedesktop.org/software/appstream/docs/chap-Quickstart.html#qsr-app-contents</metadata_license>
  <project_license>https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html#tag-project_license</project_license>
  <content_rating type="oars-1.0"/>
    <content_attribute id="">https://hughsie.github.io/oars/generate.html</content_attribute>
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
  <launchable type="desktop-id">domain.Author.AppName.desktop</launchable>
  <branding>
    <color type="primary" scheme_preference="light">#d5b0e7</color>
    <color type="primary" scheme_preference="dark">#501a5c</color>
  </branding>
  <supports>
    <control>pointing</control>
    <control>keyboard</control>
    <control>touch</control>
  </supports>
  <requires>
    <display_length compare="ge">360</display_length>
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
    <release date="2025-10-13" type="stable" version="0.21.2"></release>
  </releases>
</component>
EOF

# creating CI/CD workflow
mkdir -p .github/workflows
cat <<EOF > .github/workflows/build.yml
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
          - runs-on: ubuntu-24.04-arm
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
