# xtradeb/docker/Makefile

DISTRO    = ubuntu
RELEASE   = jammy
ARCH      =
IMAGE     = xtradeb-$(RELEASE)$(_arch_tag)-$(USER)
CONTAINER = $(IMAGE)-con
HOSTNAME := $(shell hostname -s)
TOP      := $(shell cd .. && pwd)
CTX      := $(firstword $(wildcard $(SCRATCH) $(HOME)/tmp))/tmp.context

SRC        = /home/xtradeb/src
VOL_MOUNTS = \
	-v $(TOP):/external/xtradeb:ro \
	-v $(SRC):/external/src:ro \
	--tmpfs=/external/tmp:exec

APT_MIRROR =

ifeq "$(filter debian ubuntu, $(DISTRO))" ""
$(error invalid distribution "$(DISTRO)")
endif

ifeq "$(DISTRO)" "debian"
ifeq "$(RELEASE)" "sid"
$(error please use "unstable" instead of "sid")
endif
ifeq "$(filter bullseye bookworm trixie forky unstable, $(RELEASE))" ""
$(error invalid Debian release "$(RELEASE)")
endif
endif

ifeq "$(DISTRO)" "ubuntu"
ifeq "$(filter jammy kinetic lunar mantic noble oracular plucky questing resolute stonking, $(RELEASE))" ""
$(error invalid Ubuntu release "$(RELEASE)")
endif
endif

ifneq "$(ARCH)" ""
ifeq "$(filter amd64 arm64 armhf i386 loong64 ppc64el riscv64 s390x, $(ARCH))" ""
$(error invalid architecture "$(ARCH)")
endif
endif

_arch_tag  := $(if $(ARCH),-$(ARCH))
build_stamp = build-$(RELEASE)-$(HOSTNAME)$(_arch_tag).stamp

ifneq "$(ARCH)" ""
docker_arch := $(subst armhf,arm/v7,$(subst ppc64el,ppc64le,$(ARCH)))
platform_opt = --platform=linux/$(docker_arch)
else
platform_opt =
endif

#MEM_MODE = 1
MEM_STORAGE_DIR = $(XDG_RUNTIME_DIR)/containers-storage
mem_opt := $(if $(MEM_MODE),--root=$(MEM_STORAGE_DIR))
IMAGE_DIR = $(HOME)/.cache/xtradeb-image
image_file = $(IMAGE_DIR)/$(IMAGE).tar.zst

CCACHE_DIR := $(firstword $(wildcard $(SCRATCH)/xtradeb/ccache$(_arch_tag) $(HOME)/xtradeb/ccache$(_arch_tag)))
ifneq "$(CCACHE_DIR)" ""
VOL_MOUNTS += -v $(CCACHE_DIR):/external/ccache
endif

# Refer to podman-run(1)
export PODMAN_USERNS = keep-id:uid=1024,gid=100

# Don't use "docker attach", as the container will be stopped when the
# shell exits. We want that to happen only for the initial shell.
#
ifdef MEM_MODE
run: export XDG_CONFIG_HOME = $(MEM_STORAGE_DIR)/config
run: export XDG_DATA_HOME   = $(MEM_STORAGE_DIR)/data
endif
run: in_mem_mode = $(if $(MEM_MODE),true,false)
run: $(build_stamp) $(if $(MEM_MODE),$(image_file))
ifdef MEM_MODE
	@umask 077; mkdir -p $(MEM_STORAGE_DIR)/tmp
	@mkdir -p $(XDG_CONFIG_HOME)/containers $(XDG_DATA_HOME)/share
# We use "vfs" because "overlay" makes dir renames fail with EXDEV
	@(echo '[storage]'; echo 'driver = "vfs"') \
	> $(XDG_CONFIG_HOME)/containers/storage.conf
endif
	@if docker $(mem_opt) container inspect $(CONTAINER) >/dev/null 2>&1; then \
		set -x; \
		docker $(mem_opt) container exec -it $(CONTAINER) /bin/bash; \
	else \
		if $(in_mem_mode); then \
			(set -x; zstd -cd $(image_file) \
			 | TMPDIR=$(MEM_STORAGE_DIR)/tmp podman $(mem_opt) load \
			) || exit; \
		fi; \
		ret=0; \
		(set -x; docker $(mem_opt) container run -it --rm $(platform_opt) \
			--env=APT_MIRROR=$(APT_MIRROR) \
			--env=CONTAINER_HOST_ARCH="$$(uname -m)" \
			--name=$(CONTAINER) \
			--hostname=$(CONTAINER) \
			--network=host \
			--pids-limit=-1 \
			--user=root \
			--cap-add=SYS_PTRACE \
			$(VOL_MOUNTS) \
			$(IMAGE) \
		) || ret=$$?; \
		if $(in_mem_mode); then \
			docker $(mem_opt) container ls --noheading | grep -q . \
			|| (set -x; docker unshare rm -rf $(MEM_STORAGE_DIR)); \
		fi; \
		exit $$ret; \
	fi

build: $(build_stamp)

$(build_stamp): Dockerfile hybrid-amd64-setup.sh setup.sh
	rm -rf $(CTX)
	mkdir $(CTX)
	cp -p $^ $(CTX)/
	TMPDIR=$(CTX) docker build $(platform_opt) \
		--build-arg DISTRO_RELEASE=$(DISTRO):$(RELEASE) \
		$(if $(APT_MIRROR),--build-arg APT_MIRROR=$(APT_MIRROR)) \
		--env=CONTAINER_HOST_ARCH="$$(uname -m)" \
		--network=host \
		--progress plain \
		--tag $(IMAGE) \
		$(CTX)
	rm -rf $(CTX)
ifdef MEM_MODE
	docker save $(IMAGE) | zstd -T0 > $(image_file)
else
	docker container run --rm $(platform_opt) $(IMAGE) true
endif
	touch $@

clean:
	-docker image rm $(IMAGE)
ifdef MEM_MODE
	rm -f $(image_file)
endif
	rm -f $(build_stamp)
	-chmod -R u+rw $(CTX)
	rm -rf $(CTX)

.PHONY: run build clean

# end xtradeb/docker/Makefile
