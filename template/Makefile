.PHONY: test

test:
	jpm test

server:
	fswatch -o src test | xargs -n1 -I{} 'jpm run server' 
