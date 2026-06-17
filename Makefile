PREFIX?=/usr/local
OS?=freebsd

BINDIR=$(PREFIX)/bin

SCRIPTS=sm-capture sm-preflight sm-config-test sm-init-dirs

FC=gfortran
FFLAGS=-O2 -Wall
PROCESS_BIN=sm-process
PROCESS_SRC=src/fortran/process/sm_process.f90

all: $(PROCESS_BIN)

$(PROCESS_BIN): $(PROCESS_SRC)
	$(FC) $(FFLAGS) -o $(PROCESS_BIN) $(PROCESS_SRC)

install: $(PROCESS_BIN)
	install -d $(DESTDIR)$(BINDIR)
	@for script in $(SCRIPTS); do \
		sed 's|@PREFIX@|$(PREFIX)|g' scripts/$$script.in > $(DESTDIR)$(BINDIR)/$$script; \
		chmod 755 $(DESTDIR)$(BINDIR)/$$script; \
		echo "Installed $(DESTDIR)$(BINDIR)/$$script"; \
	done

	install -m 755 $(PROCESS_BIN) $(DESTDIR)$(BINDIR)/$(PROCESS_BIN)
	echo "Installed $(DESTDIR)$(BINDIR)/$(PROCESS_BIN)"

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
	rm -f $(PROCESS_BIN)

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
