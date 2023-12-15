# xtradeb/docker/Makefile

DISTRO    = ubuntu
RELEASE   = jammy
ARCH      =
IMAGE     = xtradeb-$(RELEASE)$(_arch_tag)-$(USER)
CONTAINER = $(IMAGE)-con
HOSTNAME := $(shell hostname -s)
TOP      := $(shell cd .. && pwd)
CTX      := $(firstword $(SCRATCH) $(XDG_RUNTIME_DIR))/tmp.context

SRC        = /home/xtradeb/src
VOL_MOUNTS = -v $(TOP):/external/xtradeb:ro -v $(SRC):/external/src:ro

APT_MIRROR = cloudfront.debian.net
QEMU_PATH  = /usr/bin

ifeq "$(filter debian ubuntu, $(DISTRO))" ""
$(error invalid distribution "$(DISTRO)")
endif

ifeq "$(DISTRO)" "debian"
ifeq "$(filter bullseye bookworm trixie unstable, $(RELEASE))" ""
$(error invalid Debian release "$(RELEASE)")
endif
endif

ifeq "$(DISTRO)" "ubuntu"
ifeq "$(filter jammy kinetic lunar mantic noble, $(RELEASE))" ""
$(error invalid Ubuntu release "$(RELEASE)")
endif
endif

ifneq "$(ARCH)" ""
ifeq "$(filter amd64 arm64 armhf i386 ppc64el riscv64 s390x, $(ARCH))" ""
$(error invalid architecture "$(ARCH)")
endif
endif

_arch_tag  := $(if $(ARCH),-$(ARCH))
build_stamp = build-$(RELEASE)-$(HOSTNAME)$(_arch_tag).stamp

ifneq "$(ARCH)" ""
docker_arch := $(subst armhf,arm/v7,$(subst ppc64el,ppc64le,$(ARCH)))
platform_opt = --platform=linux/$(docker_arch)
qemu_arch   := $(subst arm64,aarch64,$(subst armhf,arm,$(subst ppc64el,ppc64le,$(ARCH))))
QEMU_INTERP  = $(QEMU_PATH)/qemu-$(qemu_arch)-static
QEMU_BINFMT  = $(qemu_arch)-binfmt-P
else
platform_opt =
QEMU_BINFMT  = dummy
endif

CCACHE_DIR := $(firstword $(wildcard $(SCRATCH)/xtradeb/ccache$(_arch_tag) /dept/ter/speech/$(USER)/xtradeb/ccache$(_arch_tag)))
ifneq "$(CCACHE_DIR)" ""
VOL_MOUNTS += -v $(CCACHE_DIR):/external/ccache --tmpfs=/external/tmp
endif

# Don't use "docker attach", as the container will be stopped when the
# shell exits. We want that to happen only for the initial shell.
#
run: $(build_stamp)
	@if docker container inspect $(CONTAINER) >/dev/null 2>&1; then \
		set -x; \
		docker container exec -it $(CONTAINER) /bin/bash; \
	else \
		set -x; \
		docker container run -it --rm $(platform_opt) \
			--name=$(CONTAINER) \
			--hostname=$(CONTAINER) \
			--cap-add=SYS_PTRACE \
			$(VOL_MOUNTS) \
			$(IMAGE); \
	fi

build: $(build_stamp)

$(build_stamp): Dockerfile Makefile
	rm -rf $(CTX)
	mkdir $(CTX)
ifdef QEMU_INTERP
	cp --preserve=times $(QEMU_INTERP) $(CTX)/$(QEMU_BINFMT)
endif
	cp -p $< $(CTX)
	cp -p hybrid-*.sh $(CTX)
	touch $(CTX)/dummy
	docker build $(platform_opt) \
		--build-arg QEMU_BINFMT=$(QEMU_BINFMT) \
		--build-arg DISTRO_RELEASE=$(DISTRO):$(RELEASE) \
		--build-arg APT_MIRROR=$(APT_MIRROR) \
		--tag $(IMAGE) \
		$(CTX)
	rm -rf $(CTX)
	docker container run --rm $(platform_opt) $(IMAGE) true
	touch $@

clean:
	-docker image rm $(IMAGE)
	rm -f $(build_stamp)
	rm -rf $(CTX)

.PHONY: run build clean

# end xtradeb/docker/Makefile
