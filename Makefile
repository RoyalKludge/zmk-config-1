.PHONY: default all clean flash $(builds)

zmk=${PWD}/zmk
uf2=${PWD}/uf2
config=${PWD}/config
zmk_image=zmkfirmware/zmk-dev-arm:2.4
docker_run=docker run --rm -h make.zmk -w /zmk -v "${zmk}:/zmk" \
	-v "${config}:/zmk-config" -v "${uf2}:/uf2" ${zmk_image}
builds=sweep sweep-peripheral

define _build
	${docker_run} sh -c '\
		west build --pristine --board "$(1)" app -- \
			-DSHIELD="$(2)" \
			-DZMK_CONFIG="/zmk-config" \
			-DCONFIG_ZMK_KEYBOARD_NAME="\"$(3)\"" \
		&& cp -av /zmk/build/zephyr/zmk.uf2 /uf2/$(3).uf2'
endef

default: sweep

sweep: zmk 
	$(call _build,nice_nano_v2,cradio_left,Sweep)

sweep-peripheral: zmk 
	$(call _build,nice_nano_v2,cradio_right,Sweep-P)

all: $(builds)

zmk:
	${docker_run} sh -c '\
		git clone https://github.com/zmkfirmware/zmk .; \
		git remote add -ft macros okke-formsa https://github.com/okke-formsma/zmk; \
		git merge okke-formsa/macros --no-edit; \
		west init -l app; \
		west update'

fresh:
	${docker_run} git checkout --force --quiet

test:
	${docker_run} west test

clean:
	rm -rf "${uf2}" "${zmk}"
