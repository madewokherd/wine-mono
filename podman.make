
$(SRCDIR)/tools/ci/.podman-image-built: $(SRCDIR)/tools/ci/build.docker podman.make
	podman image build -f $(SRCDIR)/tools/ci/build.docker -t wine-mono-build
	touch "$@"

build-podman-image: $(SRCDIR)/tools/ci/.podman-image-built
.PHONY: build-podman-image

podman-dev: podman-image
	make dev-setup

podman-test: podman-tests podman-msi build/podman-removeuserinstalls-x86.exe
	make test-nobuild

podman-%: $(SRCDIR)/tools/ci/.podman-image-built
	$(SRCDIR)/tools/build-container-exec.sh make $(MAKEFLAGS) "$*"
