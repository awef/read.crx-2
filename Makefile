SRC_DIR = src
DBG_DIR = debug

APP_COFFEE = ${SRC_DIR}/app.coffee
APP_COFFEE += ${shell find ${SRC_DIR}/ -type f -regex '${SRC_DIR}/app\.[^.]+\.coffee'}
APP_COFFEE += ${shell find ${SRC_DIR}/ -type f -regex '${SRC_DIR}/app\.[^.]+\.[^.]+\.coffee'}

LIB_FILES = ${shell find ${SRC_DIR}/lib/ -type f}
IMG_FILES = ${shell find ${SRC_DIR}/img/ -type f}

QUNIT_FILES =\
	${SRC_DIR}/test/test.html\
	${SRC_DIR}/test/qunit/qunit.js\
	${SRC_DIR}/test/qunit/qunit.css

haml = haml -q $(1) $(2)
sass = sass --style compressed --no-cache $(1) $(2)
coffee = coffee -b -p -c $(1) > $(2)

.PHONY: all
all:\
	${DBG_DIR}\
	${DBG_DIR}/manifest.json\
	${DBG_DIR}/app.html\
	${DBG_DIR}/app.js\
	${DBG_DIR}/ui.js\
	${DBG_DIR}/app.css\
	${DBG_DIR}/cs_addlink.js\
	${DBG_DIR}/lib/\
	${DBG_DIR}/img/\
	${DBG_DIR}/test/\
	${DBG_DIR}/test/test.js\
	${DBG_DIR}/write/\
	${DBG_DIR}/write/write.html\
	${DBG_DIR}/write/write.css\
	${DBG_DIR}/write/write.js\
	${DBG_DIR}/write/cs_write.js

.PHONY: clean
clean:
	rm -rf ${DBG_DIR}

${DBG_DIR}:
	mkdir ${DBG_DIR}

${DBG_DIR}/manifest.json: ${SRC_DIR}/manifest.json
	cp ${SRC_DIR}/manifest.json ${DBG_DIR}/manifest.json

${DBG_DIR}/app.html: ${SRC_DIR}/app.haml
	$(call haml, ${SRC_DIR}/app.haml, ${DBG_DIR}/app.html)

${DBG_DIR}/app.js: ${APP_COFFEE}
	$(call coffee, ${APP_COFFEE}, ${DBG_DIR}/app.js)

${DBG_DIR}/ui.js: ${SRC_DIR}/ui.*.coffee
	$(call coffee, ${SRC_DIR}/ui.*.coffee, ${DBG_DIR}/ui.js)

${DBG_DIR}/app.css: ${SRC_DIR}/app.sass ${SRC_DIR}/sass/*.sass
	$(call sass, ${SRC_DIR}/app.sass, ${DBG_DIR}/app.css)

${DBG_DIR}/cs_addlink.js: ${SRC_DIR}/cs_addlink.coffee
	$(call coffee, ${SRC_DIR}/cs_addlink.coffee, ${DBG_DIR}/cs_addlink.js)

${DBG_DIR}/lib/: ${LIB_FILES}
	rm -rf ${DBG_DIR}/lib/
	cp -r ${SRC_DIR}/lib/ ${DBG_DIR}/lib/

${DBG_DIR}/img/: ${SRC_DIR}/image/svg/*.svg
	rm -rf ${DBG_DIR}/img/
	mkdir ${DBG_DIR}/img/
	rsvg -w 128 -h 128 ${SRC_DIR}/image/svg/read.crx.svg ${DBG_DIR}/img/read.crx_128x128.png
	rsvg -w 48 -h 48 ${SRC_DIR}/image/svg/read.crx.svg ${DBG_DIR}/img/read.crx_48x48.png
	rsvg -w 16 -h 16 ${SRC_DIR}/image/svg/read.crx.svg ${DBG_DIR}/img/read.crx_16x16.png
	rsvg -w 16 -h 16 ${SRC_DIR}/image/svg/close.svg ${DBG_DIR}/img/close_16x16.png
	rsvg -w 19 -h 19 ${SRC_DIR}/image/svg/star.svg ${DBG_DIR}/img/star_19x19.png
	rsvg -w 19 -h 19 ${SRC_DIR}/image/svg/star2.svg ${DBG_DIR}/img/star2_19x19.png
	rsvg -w 19 -h 19 ${SRC_DIR}/image/svg/link.svg ${DBG_DIR}/img/link_19x19.png
	rsvg -w 19 -h 19 ${SRC_DIR}/image/svg/search2.svg ${DBG_DIR}/img/search2_19x19.png
	rsvg -w 19 -h 19 ${SRC_DIR}/image/svg/reload.svg ${DBG_DIR}/img/reload_19x19.png
	rsvg -w 19 -h 19 ${SRC_DIR}/image/svg/pencil.svg ${DBG_DIR}/img/pencil_19x19.png

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

${DBG_DIR}/write/write.js: ${SRC_DIR}/write/write.coffee ${SRC_DIR}/app.url.coffee
	$(call coffee, ${SRC_DIR}/write/write.coffee ${SRC_DIR}/app.url.coffee, ${DBG_DIR}/write/write.js)

${DBG_DIR}/write/cs_write.js: ${SRC_DIR}/write/cs_write.coffee ${SRC_DIR}/app.url.coffee
	$(call coffee, ${SRC_DIR}/write/cs_write.coffee ${SRC_DIR}/app.url.coffee, ${DBG_DIR}/write/cs_write.js)
