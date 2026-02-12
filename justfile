set shell := ["sh", "-cu"]
set windows-shell := ["powershell.exe", "-NoProfile", "-Command"]


build: prepare-bin
	@docker compose up --abort-on-container-exit
	@docker compose down

build-left: prepare-bin
	@docker compose run --rm -e BUILD_VARIANT=keymap -e BUILD_TARGET=left zmk-build

build-right: prepare-bin
	@docker compose run --rm -e BUILD_VARIANT=keymap -e BUILD_TARGET=right zmk-build

pobuild-all: prepare-bin
	@docker compose run --rm -e BUILD_VARIANT=all -e BUILD_TARGET=both zmk-build

build-fresh: prepare-bin
	@docker compose down --volumes
	@docker compose run --rm --build -e BUILD_VARIANT=all zmk-build
	@docker compose down

sync:
	@git pull

update:
	@git push --force

prepare-bin:
	@{{ if os() == "windows" { "if (Test-Path bin) { Remove-Item -Recurse -Force bin }; New-Item -ItemType Directory -Path bin | Out-Null" } else { "rm -rf bin && mkdir -p bin" } }}