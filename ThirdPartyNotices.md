# Third-Party Notices

This document contains licensing information for third-party libraries used in totalUI. These libraries are **NOT** covered by the totalUI license and retain their original licenses.

## Libraries in totalUI/Libraries/

The following third-party libraries may be installed in the `totalUI/Libraries/` folder. These are **NOT** included in the repository and must be downloaded separately (see [LIBRARIES.md](LIBRARIES.md)).

---

### LibStub

**Source**: https://www.wowace.com/projects/libstub

**License**: Public Domain

```
LibStub is a minimalistic versioning library that allows other libraries
to easily register themselves and upgrade their versions when needed.

This library is in the Public Domain.
```

---

### Ace3

**Source**: https://www.wowace.com/projects/ace3

**License**: BSD-3-Clause / MIT (varies by module)

```
Ace3 is a collection of libraries that provide a framework for WoW addon development.

Individual Ace3 libraries may be licensed under BSD-3-Clause or MIT licenses.
See the individual library folders for specific license information.
```

**Modules**:
- AceAddon-3.0
- AceConfig-3.0
- AceConsole-3.0
- AceDB-3.0
- AceDBOptions-3.0
- AceEvent-3.0
- AceGUI-3.0
- AceHook-3.0
- AceLocale-3.0
- AceTimer-3.0

---

### LibSharedMedia-3.0

**Source**: https://www.wowace.com/projects/libsharedmedia-3-0

**License**: LGPL-2.1

```
LibSharedMedia-3.0 is a library to manage and share media resources
(fonts, textures, sounds) between addons.

This library is licensed under the GNU Lesser General Public License v2.1.
```

---

### LibActionButton-1.0 (Optional - Phase 1)

**Source**: https://www.wowace.com/projects/libactionbutton-1-0

**License**: BSD-3-Clause

```
LibActionButton provides a comprehensive action button implementation for WoW addons.

This library is licensed under the BSD 3-Clause License.
See the library's LICENSE file for full details.
```

---

## Attribution Requirements

When using totalUI with these libraries installed:

1. **LibStub**: No attribution required (Public Domain)
2. **Ace3**: Attribution recommended but not required
3. **LibSharedMedia-3.0**: Must comply with LGPL-2.1 if distributing
4. **LibActionButton-1.0**: BSD license attribution recommended

## Notes

- Third-party libraries are **NOT** included in the totalUI repository
- Users must download these libraries separately (see LIBRARIES.md)
- totalUI works without these libraries in degraded/fallback mode
- Each library retains its original license
- totalUI's restrictive license does **NOT** apply to these libraries

For questions about library licensing, please contact the respective library maintainers.
