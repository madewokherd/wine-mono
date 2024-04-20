#!/usr/bin/env python3

import os
import shutil
import tempfile
import urllib.request

need_gecko = True
need_mono = False

basedir = os.path.join(os.getcwd(), "wine-addons")

existing_files = set(os.listdir(basedir))

addons_url = 'https://gitlab.winehq.org/wine/wine/-/raw/master/dlls/appwiz.cpl/addons.c?ref_type=heads&inline=false'

with urllib.request.urlopen(addons_url) as response:
	addons_contents = response.read().decode('ascii')

gecko_version = None
mono_version = None

for line in addons_contents.splitlines():
	if line.startswith('#define GECKO_VERSION '):
		gecko_version = line.split()[2].strip('"')
		print('Gecko version: ' + gecko_version)
	if line.startswith('#define MONO_VERSION '):
		mono_version = line.split()[2].strip('"')
		print('Mono version: ' + mono_version)

needed_files = {}

if need_gecko:
	needed_files['wine-gecko-' + gecko_version + '-x86.msi'] = 'https://dl.winehq.org/wine/wine-gecko/' + gecko_version + '/wine-gecko-' + gecko_version + '-x86.msi'
	needed_files['wine-gecko-' + gecko_version + '-x86_64.msi'] = 'https://dl.winehq.org/wine/wine-gecko/' + gecko_version + '/wine-gecko-' + gecko_version + '-x86_64.msi'
if need_mono:
	needed_files['wine-mono-' + mono_version + '-x86.msi'] = 'https://dl.winehq.org/wine/wine-mono/' + mono_version + '/wine-mono-' + mono_version + '-x86.msi'

def download(url, filename):
	print("Downloading "+url)
	with urllib.request.urlopen(url) as response:
		with tempfile.NamedTemporaryFile(delete=False) as tmpfile:
			try:
				shutil.copyfileobj(response, tmpfile)
				shutil.move(tmpfile.name, filename)
			except:
				os.unlink(tmpfile.name)
				raise

for f in needed_files:
	if f in existing_files:
		continue
	download(needed_files[f], os.path.join(basedir, f))

for f in existing_files:
	if f not in needed_files:
		print("Removing "+f)
		os.unlink(os.path.join(basedir, f))

