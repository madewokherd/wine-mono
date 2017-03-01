# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant file for setting up a build environment for Wine Mono.

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"

  # Uncomment to increase guest resources from the default
  #config.vm.provider "virtualbox" do |v|
  #  v.memory = 2048
  #  v.cpus = 4
  #end

  # Use virtualbox shared folders only for build output.
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".git/", "/build-*/", "/image/", "/tests-*/", "/winemono.msi", "/output/"]
  config.vm.synced_folder ".", "/vagrant/output", create: "true"

  config.vm.provision "shell", privileged: "true", inline: <<-SHELL
    dpkg --add-architecture i386
    apt-get update
	# --no-install-recommends to avoid corefonts which needs eula
    apt-get install -y --no-install-recommends wine
	apt-get install -y mono-mcs autoconf libtool gettext gcc-mingw-w64-x86-64 gcc-mingw-w64-i686 g++-mingw-w64-x86-64 g++-mingw-w64-i686 python libtool-bin cmake
  SHELL
end
