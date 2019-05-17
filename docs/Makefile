.SUFFIXES: .md .html

all: part0.html part1.html part1b.html part1c.html part1d.html part2.html part2b.html part_privacy.html part3.html part4.html slides.html

.md.html:
	pandoc -B menu.html -s --css=github.css --to=html5 --highlight-style=haddock \
       --self-contained -o $@ $<

watch:
	while true; do \
		make $(WATCHMAKE); \
		inotifywait -qre close_write .; \
	done
