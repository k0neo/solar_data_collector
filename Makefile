PREFIX?=/usr/local
OS?=freebsd

BINDIR=$(PREFIX)/bin

all:
	@echo "No compiled targets yet."
	@echo "Run 'make install OS=freebsd' or 'make install OS=linux'."

install:
	install -d $(DESTDIR)$(BINDIR)
	sed 's|@PREFIX@|$(PREFIX)|g' scripts/sm-capture.in > $(DESTDIR)$(BINDIR)/sm-capture
	chmod 755 $(DESTDIR)$(BINDIR)/sm-capture
	sed 's|@PREFIX@|$(PREFIX)|g' scripts/sm-preflight.in > $(DESTDIR)$(BINDIR)/sm-preflight
	chmod 755 $(DESTDIR)$(BINDIR)/sm-preflight

	@if [ "$(OS)" = "freebsd" ]; then \
		install -d $(DESTDIR)$(PREFIX)/etc; \
		install -m 644 etc/solar-monitor.freebsd.conf.sample $(DESTDIR)$(PREFIX)/etc/solar-monitor.conf.sample; \
		echo "Installed FreeBSD sample config to $(DESTDIR)$(PREFIX)/etc/solar-monitor.conf.sample"; \
	elif [ "$(OS)" = "linux" ]; then \
		install -d $(DESTDIR)/etc/solar-monitor; \
		install -m 644 etc/solar-monitor.linux.conf.sample $(DESTDIR)/etc/solar-monitor/solar-monitor.conf.sample; \
		echo "Installed Linux sample config to $(DESTDIR)/etc/solar-monitor/solar-monitor.conf.sample"; \
	else \
		echo "Unknown OS=$(OS). Use OS=freebsd or OS=linux."; \
		exit 1; \
	fi

clean:
	find src -name '*.o' -delete
	find src -name '*.mod' -delete

check:
	@for script in $(SCRIPTS); do \
		sh -n scripts/$$script.in || exit 1; \
	done
	@echo "Script syntax checks passed."

config-test:
	sh scripts/sm-config-test.in /usr/local/etc/solar-monitor.conf

preflight:
	@sm-preflight /usr/local/etc/solar-monitor.conf || { \
		echo ""; \
		echo "Preflight failed. If the RTL-SDR is not connected, this is expected."; \
		exit 1; \
	}

.PHONY: all install clean check config-test preflight
