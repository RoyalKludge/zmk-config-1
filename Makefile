.PHONY: uf2 clean flash-left flash-right

board=nice_nano
shield=cradio
zmk_image=zmkfirmware/zmk-dev-arm:2.4
zmk=${PWD}/zmk
uf2=${PWD}/uf2
bootloader=/media/${USER}/NICENANO

define build
	docker run --rm \
		-v "${zmk}:/zmk" -v "${PWD}/config:/zmk-config" -v "${uf2}:/uf2" \
		-w /zmk/app "${zmk_image}" sh -c '\
			west build --pristine -b "${board}" \
			-- -DSHIELD="$(1)" -DZMK_CONFIG="/zmk-config" \
			&& cp build/zephyr/zmk.uf2 /uf2/$(1).uf2'
endef

define flash
	@ printf "\nWaiting for $(1) ${board} to appear at ${bootloader} ."
	@ while [ ! -f "${bootloader}/current.uf2" ]; do sleep 1; printf "."; done
	@ printf "\n";
	cp -av "${uf2}/$(1).uf2" "${bootloader}/"
endef

default: flash-left

uf2: zmk
	$(call build,${shield}_left)
	$(call build,${shield}_right)

flash-left: zmk
	$(call build,${shield}_left)
	$(call flash,${shield}_left)

flash-right: zmk
	$(call build,${shield}_right)
	$(call flash,${shield}_right)

zmk:
	docker run --rm -h make.zmk -w /zmk -v "${zmk}:/zmk" "${zmk_image}" sh -c '\
		git clone https://github.com/zmkfirmware/zmk .; \
		git remote add -ft macros okke-formsa https://github.com/okke-formsma/zmk; \
		git remote add -ft cradio-v2 davidphilipbarr https://github.com/davidphilipbarr/zmk; \
		git remote add -ft pr_tapdance kurtis-lew https://github.com/kurtis-lew/zmk; \
		git merge okke-formsa/macros --no-edit; \
		git merge davidphilipbarr/cradio-v2 --no-edit; \
		git merge kurtis-lew/pr_tapdance --no-edit; \
		west init -l app; \
		west update;'

clean:
	sudo rm -rf "${uf2}" "${zmk}"
