.PHONY: test

test:
	jpm test

watch:
	fswatch -o src test | xargs -n1 -I{} make 
