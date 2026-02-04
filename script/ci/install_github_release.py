#!/usr/bin/env python3
import argparse
import json
import os
import re
import shutil
import sys
import tarfile
import tempfile
import urllib.request
import zipfile


def _request(url: str) -> urllib.request.Request:
    req = urllib.request.Request(url)
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Accept", "application/vnd.github+json")
    return req


def fetch_json(url: str) -> dict:
    with urllib.request.urlopen(_request(url)) as resp:
        return json.load(resp)


def download(url: str, dest: str) -> None:
    with urllib.request.urlopen(_request(url)) as resp, open(dest, "wb") as fh:
        shutil.copyfileobj(resp, fh)


def select_asset(assets: list[dict]) -> dict:
    linux_re = re.compile(r"linux", re.IGNORECASE)
    arch_re = re.compile(r"(amd64|x86_64)", re.IGNORECASE)
    for asset in assets:
        name = asset.get("name", "")
        if linux_re.search(name) and arch_re.search(name):
            if name.endswith((".tar.gz", ".tgz", ".tar.xz", ".txz", ".tar.bz2", ".tbz2", ".zip")):
                return asset
    raise RuntimeError("No suitable linux/amd64 release asset found")


def find_binary(root: str, binary_name: str) -> str:
    for dirpath, _, filenames in os.walk(root):
        for filename in filenames:
            if filename == binary_name:
                return os.path.join(dirpath, filename)
    raise RuntimeError(f"Binary '{binary_name}' not found in extracted archive")


def extract(archive_path: str, dest_dir: str) -> str:
    if archive_path.endswith((".zip",)):
        with zipfile.ZipFile(archive_path) as zf:
            zf.extractall(dest_dir)
    else:
        with tarfile.open(archive_path, "r:*") as tar:
            tar.extractall(dest_dir)
    return dest_dir


def main() -> int:
    parser = argparse.ArgumentParser(description="Install latest GitHub release binary.")
    parser.add_argument("--repo", required=True, help="owner/repo name on GitHub")
    parser.add_argument("--binary", required=True, help="binary name to install")
    parser.add_argument("--dest", required=True, help="destination directory to place binary")
    args = parser.parse_args()

    release = fetch_json(f"https://api.github.com/repos/{args.repo}/releases/latest")
    asset = select_asset(release.get("assets", []))
    url = asset["browser_download_url"]

    os.makedirs(args.dest, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = os.path.join(tmpdir, os.path.basename(url))
        download(url, archive_path)
        extract_dir = extract(archive_path, os.path.join(tmpdir, "extract"))
        binary_path = find_binary(extract_dir, args.binary)
        dest_path = os.path.join(args.dest, args.binary)
        shutil.copy2(binary_path, dest_path)
        os.chmod(dest_path, 0o755)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
