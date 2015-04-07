all:
	gem build ./switchboard.gemspec

publish:
	gem push ./switchboard-*-.gem

clean:
	rm *.gem

.PHONY: publish
