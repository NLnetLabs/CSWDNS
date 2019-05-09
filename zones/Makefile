bangkok.lol.signed: bangkok.lol bangkok.lol.delegations bangkok.lol.dses Makefile
	ldns-read-zone -S YYYYMMDDxx bangkok.lol > bangkok.lol.new
	mv bangkok.lol.new bangkok.lol
	cat bangkok.lol bangkok.lol.delegations bangkok.lol.dses \
	| ldns-signzone -b -f bangkok.lol.signed - Kbangkok.lol.+013+22826 Kbangkok.lol.+013+20972
	mkdir -p /etc/nsd/zones
	cp -p bangkok.lol.signed /etc/nsd/zones/bangkok.lol.signed
	nsd-control reload

dses:
	@for D in `awk '/^[A-Za-z0-9-]+[	 ]/{ print $$1}' bangkok.lol.delegations` ; do \
		CDS=`dig $${D}.bangkok.lol CDS +short` ; \
		if [ ! -z "$$CDS" ] ; then \
            if grep "^$${D} 60 IN DS $${CDS}" bangkok.lol.delegations ; then continue; fi ; \
			if grep "^$${D} 60 IN DS $${CDS}" bangkok.lol.dses >/dev/null; then continue; fi ; \
            date ; \
			echo $${D} 60 IN DS $${CDS} ; \
			echo $${D} 60 IN DS $${CDS} >> bangkok.lol.dses; \
		fi \
	done

monitor-dses:
	@while true; do echo -n .; make -s dses; sleep 2; done

watch:
	while true; do \
		make $(WATCHMAKE); \
		inotifywait -qre close_write .; \
	done
