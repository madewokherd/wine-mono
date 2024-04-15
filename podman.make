
$(SRCDIR)/tools/ci/.podman-image-built: $(SRCDIR)/tools/ci/build.docker podman.make
	podman image build -f $(SRCDIR)/tools/ci/build.docker -t wine-mono-build
	touch "$@"

build-podman-image: $(SRCDIR)/tools/ci/.podman-image-built
.PHONY: build-podman-image
