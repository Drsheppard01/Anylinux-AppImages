---
layout: default
title: Home
permalink: /
---

# Anylinux AppImages

Designed to run seamlessly on any Linux distribution, including very very old distributions and musl-based ones. Our AppImages bundle all the needed dependencies and do not depend on host libraries to work, unlike most other AppImages, **all while being significantly smaller thanks to [DwarFS](https://github.com/mhx/dwarfs) and [optimized packages](https://github.com/pkgforge-dev/archlinux-pkgs-debloated)**.

Most of the AppImages are made with [sharun](https://github.com/VHSgunzo/sharun). We also use an alternative better [runtime](https://github.com/VHSgunzo/uruntime).

The uruntime [automatically falls back to using namespaces](https://github.com/VHSgunzo/uruntime?tab=readme-ov-file#built-in-configuration) if FUSE is not available at all, and if namespaces are not possible it falls back to extract and run, so we **truly have 0 requirements:**

For more useful documentation about Anylinux-AppImages, see the pages below:

- [FAQ](/docs/FAQ.md)
- [How to make these](/docs/BUILDING.md)
- [Hall of fame/shame](/docs/HALL-OF-FAME.md)
- [Size comparison](/docs/COMPARISON.md)
- [Build tools and scripts](src/)

Also see [other projects](https://github.com/VHSgunzo/sharun?tab=readme-ov-file#projects-that-use-sharun) that use sharun for more. **Didn't find what you were looking for?** Open an issue [here](https://github.com/drsheppard01/Anylinux-AppImages/issues) and we will see what we can do.
