"""Restore missing Studio from the official, versioned Roblox CDN packages.

Does not modify accounts/registry/security settings. Packages and old builds remain.
"""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import shutil
import urllib.request
import zipfile

ROOT = Path(r"D:\Roblox")
CACHE = ROOT / "Kurulum" / "studio-packages"
version = json.load(urllib.request.urlopen(
    "https://clientsettingscdn.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE", timeout=30
))["clientVersionUpload"]
destination = ROOT / "Versions" / version
destination.mkdir(parents=True, exist_ok=True)
manifest = urllib.request.urlopen(f"https://setup.rbxcdn.com/{version}-rbxPkgManifest.txt", timeout=30).read()
(CACHE / "manifest.txt").write_bytes(manifest)
lines = manifest.decode().splitlines()
assert lines[0] == "v0"
packages = [(lines[i], lines[i+1], int(lines[i+2])) for i in range(1, len(lines), 4)]
directories = {
    "ApplicationConfig.zip": "", "RobloxStudio.zip": "", "Libraries.zip": "", "LibrariesQt5.zip": "",
    "BuiltInPlugins.zip": "BuiltInPlugins", "BuiltInStandalonePlugins.zip": "BuiltInStandalonePlugins",
    "Plugins.zip": "Plugins", "StudioFonts.zip": "StudioFonts", "WebView2.zip": "",
    "WebView2RuntimeInstaller.zip": "WebView2RuntimeInstaller", "shaders.zip": "shaders",
    "ssl.zip": "ssl", "redist.zip": "",
}

def restore(package):
    name, digest, size = package
    archive = CACHE / name
    if not archive.exists() or archive.stat().st_size != size or hashlib.md5(archive.read_bytes()).hexdigest() != digest:
        partial = archive.with_suffix(".download")
        for attempt in range(3):
            try:
                with urllib.request.urlopen(f"https://setup.rbxcdn.com/{version}-{name}", timeout=60) as response, partial.open("wb") as target:
                    while block := response.read(1024*1024):
                        target.write(block)
                assert partial.stat().st_size == size, f"Incomplete download: {name}"
                assert hashlib.md5(partial.read_bytes()).hexdigest() == digest, f"Digest mismatch: {name}"
                os.replace(partial, archive)
                break
            except Exception:
                if attempt == 2:
                    raise
    relative = directories.get(name)
    if relative is None:
        assert name.startswith(("content-", "extracontent-", "studiocontent-")), name
        relative = name.removesuffix(".zip").replace("-", "/", 1)
    target = destination / relative
    with zipfile.ZipFile(archive) as package_zip:
        for member in package_zip.infolist():
            if member.is_dir() and member.filename in ("/", "\\", ""):
                continue  # Official packages contain an empty root directory entry.
            # Package-root slash is metadata, never a host absolute destination.
            normalized = member.filename.replace("\\", "/").lstrip("/")
            resolved = (target / normalized).resolve()
            assert resolved.is_relative_to(destination.resolve()), f"Unsafe archive path: {member.filename}"
            if member.is_dir():
                resolved.mkdir(parents=True, exist_ok=True)
            else:
                resolved.parent.mkdir(parents=True, exist_ok=True)
                with package_zip.open(member) as source, resolved.open("wb") as output:
                    shutil.copyfileobj(source, output)
    print(f"RESTORED {name} ({size} bytes, CDN MD5 verified)", flush=True)
    return {"Package": name, "Bytes": size, "MD5": digest, "Directory": relative}

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    restored = list(pool.map(restore, packages))
report = {"Version": version, "Root": str(destination), "Packages": restored, "Source": "https://setup.rbxcdn.com", "Launched": False}
(CACHE / "restoration.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps({"Ready": str(destination / "RobloxStudioBeta.exe")}), flush=True)
