
paste.js: paste.coffee node_modules
	node_modules/.bin/coffee --compile paste.coffee

node_modules: package.json
	npm install

watch: paste.js node_modules
	node_modules/.bin/concurrently "node_modules/.bin/browser-sync start --server --no-ui --port ${PORT} --files paste.js index.html" "node_modules/.bin/watch-run -p paste.coffee make"

pages:
	git push origin HEAD:gh-pages
