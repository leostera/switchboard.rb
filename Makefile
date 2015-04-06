all:
	gem build ./switchboard.gemspec

publish:
	gem push ./switchboard-*-.gem

clean:
	rm ./switchboard-*-.gem

.PHONY: publish
