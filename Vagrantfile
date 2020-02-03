# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant file for setting up a build environment for Wine Mono.

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |v|
    v.cpus = `nproc`.to_i
    # meminfo shows KB and we need to convert to MB
    v.memory = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 4
  end

  # Use virtualbox shared folders only for build output.
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".git/", "/build-*/", "/image/", "/tests-*/", "/winemono.msi", "/output/"], rsync__args: ["--verbose", "--archive", "-z", "--links", "--update"]
  config.vm.synced_folder ".", "/vagrant/output", create: "true"

  config.vm.provision "shell", privileged: "true", inline: <<-SHELL
    dpkg --add-architecture i386
    echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
    apt-get update
	# --no-install-recommends to avoid corefonts which needs eula
    apt-get install -y --no-install-recommends wine-stable
	apt-get install -y mono-mcs autoconf libtool gettext gcc-mingw-w64-x86-64 gcc-mingw-w64-i686 g++-mingw-w64-x86-64 g++-mingw-w64-i686 python libtool-bin cmake dos2unix libgdiplus
  SHELL
end
