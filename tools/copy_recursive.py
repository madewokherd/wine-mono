# Copy a directory recursively WITHOUT the race condition in cp -r.

# This also ignores symbolic links.

import errno
import os
import shutil
import sys

if sys.version >= (3,):
	file_exists_error = FileExistsError
	def is_file_exists_error(e):
		return True
else:
	file_exists_error = OSError
	def is_file_exists_error(e):
		return e.errno == errno.EEXIST

def copy_recursive(src, destdir):
	dest = os.path.join(destdir, os.path.basename(src))
	if os.path.isdir(src):
		try:
			os.mkdir(dest)
		except file_exists_error as e:
			if not is_file_exists_error(e):
				raise
		for filename in os.listdir(src):
			path = os.path.join(src, filename)
			copy_recursive(path, dest)
	elif os.path.islink(src):
		pass
	elif os.path.isfile(src):
		shutil.copy(src, dest)
	else:
		raise Exception('unknown file type for: '+src)

if len(sys.argv) < 3:
	print('Usage: copy_recursive.py FILE DIRECTORY')

copy_recursive(sys.argv[1], sys.argv[2])

