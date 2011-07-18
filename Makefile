SRC_DIR = src
DBG_DIR = debug

LIB_FILES = ${shell find ${SRC_DIR}/lib/ -type f}

QUNIT_FILES =\
  ${SRC_DIR}/test/test.html\
  ${SRC_DIR}/test/qunit/qunit.js\
  ${SRC_DIR}/test/qunit/qunit.css

haml = haml -q $(1) $(2)
sass = sass --style compressed --no-cache $(1) $(2)
coffee = cat $(1) | coffee -cbsp > $(2)
svg = convert\
  -background transparent\
  -resize $(2)x$(3)\
  ${SRC_DIR}/image/svg/$(1).svg ${DBG_DIR}/img/$(1)_$(2)x$(3).png

.PHONY: all
all:\
  ${DBG_DIR}\
  ${DBG_DIR}/manifest.json\
  ${DBG_DIR}/app.html\
  ${DBG_DIR}/app.js\
  ${DBG_DIR}/ui.js\
  ${DBG_DIR}/ui.css\
  ${DBG_DIR}/app.css\
  ${DBG_DIR}/cs_addlink.js\
  ${DBG_DIR}/cs_search.js\
  ${DBG_DIR}/lib/\
  ${DBG_DIR}/img/\
  ${DBG_DIR}/test/\
  ${DBG_DIR}/test/test.js\
  ${DBG_DIR}/write/\
  ${DBG_DIR}/write/write.html\
  ${DBG_DIR}/write/write.css\
  ${DBG_DIR}/write/write.js\
  ${DBG_DIR}/write/cs_write.js\
  ${DBG_DIR}/zombie.html\
  ${DBG_DIR}/zombie.js

.PHONY: clean
clean:
	rm -rf ${DBG_DIR}

${DBG_DIR}:
	mkdir ${DBG_DIR}

${DBG_DIR}/manifest.json: ${SRC_DIR}/manifest.json
	cp ${SRC_DIR}/manifest.json ${DBG_DIR}/manifest.json

${DBG_DIR}/app.html: ${SRC_DIR}/app.haml
	$(call haml, ${SRC_DIR}/app.haml, ${DBG_DIR}/app.html)

${DBG_DIR}/app.js:\
  ${SRC_DIR}/app.coffee\
  ${SRC_DIR}/core/*.coffee\
  ${SRC_DIR}/app.*.coffee
	$(call coffee,\
    ${SRC_DIR}/app.coffee\
    ${SRC_DIR}/core/*.coffee\
    ${SRC_DIR}/app.*.coffee\
    , ${DBG_DIR}/app.js)

${DBG_DIR}/ui.js: ${SRC_DIR}/ui/*.coffee
	$(call coffee, ${SRC_DIR}/ui/*.coffee, ${DBG_DIR}/ui.js)

${DBG_DIR}/ui.css:\
  ${SRC_DIR}/common.sass\
  ${SRC_DIR}/ui/*.sass
	$(call sass, ${SRC_DIR}/ui/ui.sass, ${DBG_DIR}/ui.css)

${DBG_DIR}/app.css:\
  ${SRC_DIR}/common.sass\
  ${SRC_DIR}/app.sass\
  ${SRC_DIR}/sass/*.sass
	$(call sass, ${SRC_DIR}/app.sass, ${DBG_DIR}/app.css)

${DBG_DIR}/cs_addlink.js: ${SRC_DIR}/cs_addlink.coffee
	$(call coffee, ${SRC_DIR}/cs_addlink.coffee, ${DBG_DIR}/cs_addlink.js)

${DBG_DIR}/cs_search.js:\
    ${SRC_DIR}/app.coffee\
    ${SRC_DIR}/core/url.coffee\
    ${SRC_DIR}/cs_search.coffee
	$(call coffee,\
  ${SRC_DIR}/app.coffee\
  ${SRC_DIR}/core/url.coffee\
  ${SRC_DIR}/cs_search.coffee\
  , ${DBG_DIR}/cs_search.js)

${DBG_DIR}/lib/: ${LIB_FILES}
	rm -rf ${DBG_DIR}/lib/
	cp -r ${SRC_DIR}/lib/ ${DBG_DIR}/lib/

${DBG_DIR}/img/: ${SRC_DIR}/image/svg/*.svg
	rm -rf ${DBG_DIR}/img/
	mkdir ${DBG_DIR}/img/

	convert\
    -background transparent\
    -resize 96x96\
    -extent 128x128-16-16\
    ${SRC_DIR}/image/svg/read.crx.svg ${DBG_DIR}/img/read.crx_128x128.png

	convert\
    -background transparent\
    -resize 90x90\
    -extent 128x128-50-92.5\
    ${SRC_DIR}/image/svg/alpha_badge.svg ${DBG_DIR}/img/tmp_alpha_badge.png

	convert\
    -background transparent\
    -composite ${DBG_DIR}/img/read.crx_128x128.png\
    ${DBG_DIR}/img/tmp_alpha_badge.png\
    ${DBG_DIR}/img/read.crx_128x128.png

	rm ${DBG_DIR}/img/tmp_alpha_badge.png

	$(call svg,read.crx,48,48)
	$(call svg,read.crx,16,16)
	$(call svg,close,16,16)
	$(call svg,star,19,19)
	$(call svg,star2,19,19)
	$(call svg,link,19,19)
	$(call svg,search2,19,19)
	$(call svg,reload,19,19)
	$(call svg,pencil,19,19)
	$(call svg,arrow,19,19)
	$(call svg,dummy,1,1)

${DBG_DIR}/test/: ${QUNIT_FILES}
	rm -rf ${DBG_DIR}/test/
	mkdir ${DBG_DIR}/test/
	cp ${SRC_DIR}/test/test.html ${DBG_DIR}/test/test.html
	cp -r ${SRC_DIR}/test/qunit/ ${DBG_DIR}/test/qunit/

${DBG_DIR}/test/test.js: ${DBG_DIR}/test/ ${SRC_DIR}/test/*.coffee
	$(call coffee, ${SRC_DIR}/test/*.coffee, ${DBG_DIR}/test/test.js)

${DBG_DIR}/write/:
	mkdir ${DBG_DIR}/write/

${DBG_DIR}/write/write.html: ${SRC_DIR}/write/write.haml
	$(call haml, ${SRC_DIR}/write/write.haml, ${DBG_DIR}/write/write.html)

${DBG_DIR}/write/write.css: ${SRC_DIR}/write/write.sass
	$(call sass, ${SRC_DIR}/write/write.sass, ${DBG_DIR}/write/write.css)

${DBG_DIR}/write/write.js:\
  ${SRC_DIR}/app.coffee\
  ${SRC_DIR}/core/url.coffee\
  ${SRC_DIR}/write/write.coffee
	$(call coffee,\
    ${SRC_DIR}/app.coffee\
    ${SRC_DIR}/core/url.coffee\
    ${SRC_DIR}/write/write.coffee\
    , ${DBG_DIR}/write/write.js)

${DBG_DIR}/write/cs_write.js:\
  ${SRC_DIR}/app.coffee\
  ${SRC_DIR}/core/url.coffee\
  ${SRC_DIR}/write/cs_write.coffee
	$(call coffee,\
    ${SRC_DIR}/app.coffee\
    ${SRC_DIR}/core/url.coffee\
    ${SRC_DIR}/write/cs_write.coffee\
    , ${DBG_DIR}/write/cs_write.js)

${DBG_DIR}/zombie.html: ${SRC_DIR}/zombie.haml
	$(call haml, ${SRC_DIR}/zombie.haml, ${DBG_DIR}/zombie.html)

${DBG_DIR}/zombie.js:\
  ${SRC_DIR}/app.coffee\
  ${SRC_DIR}/core/url.coffee\
  ${SRC_DIR}/core/read_state.coffee\
  ${SRC_DIR}/core/bookmark.coffee\
  ${SRC_DIR}/zombie.coffee
	$(call coffee,\
    ${SRC_DIR}/app.coffee\
    ${SRC_DIR}/core/url.coffee\
    ${SRC_DIR}/core/read_state.coffee\
    ${SRC_DIR}/core/bookmark.coffee\
    ${SRC_DIR}/zombie.coffee\
    , ${DBG_DIR}/zombie.js)
