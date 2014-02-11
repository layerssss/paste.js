paste.js: paste.coffee
	coffee --compile $^
pages:
	git push origin HEAD:gh-pages
