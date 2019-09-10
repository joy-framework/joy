.PHONY: test

test:
	jpm test

watch:
	fswatch -o src lib test | xargs -n1 -I{} make

server:
	fswatch -o src lib test | xargs -n1 -I{} ./restart-server.sh
