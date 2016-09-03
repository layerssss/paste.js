export PATH := node_modules/.bin:$(PATH)

paste.js: paste.coffee node_modules
	coffee --compile paste.coffee

node_modules: package.json
	npm install

watch: paste.js node_modules
	concurrently "browser-sync start --server --no-ui --port ${PORT} --files paste.js index.html" "watch-run -p paste.coffee make"

pages:
	git push origin HEAD:gh-pages
