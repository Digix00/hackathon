.PHONY: run-dev stop-dev logs restart-dev db-shell tidy fmt clean reset-db \
        generate-docs generate-android generate-ios generate-code

# ==============================================================================
# Docker Compose Commands
# ==============================================================================

run-dev:
	$(MAKE) -C backend run-dev

stop-dev:
	$(MAKE) -C backend stop-dev

logs:
	$(MAKE) -C backend logs

restart-dev:
	$(MAKE) -C backend restart-dev

clean:
	$(MAKE) -C backend clean

reset-db:
	$(MAKE) -C backend reset-db

# ==============================================================================
# Utility Commands
# ==============================================================================

db-shell:
	$(MAKE) -C backend db-shell

tidy:
	$(MAKE) -C backend tidy

fmt:
	$(MAKE) -C backend fmt

# ==============================================================================
# Code Generation
# ==============================================================================

generate-docs:
	$(MAKE) -C backend generate-docs

generate-android:
	$(MAKE) -C backend generate-android

generate-ios:
	$(MAKE) -C backend generate-ios

generate-code:
	$(MAKE) -C backend generate-code
