SRC_DIR = code
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
	${DBG_DIR}/test/test.js

.PHONY: clean
clean:
	rm -rf ${DBG_DIR}

${DBG_DIR}:
	mkdir ${DBG_DIR}

${DBG_DIR}/manifest.json: ${SRC_DIR}/manifest.json
	cp ${SRC_DIR}/manifest.json ${DBG_DIR}/manifest.json

${DBG_DIR}/app.html: ${SRC_DIR}/app.haml
	haml -q ${SRC_DIR}/app.haml ${DBG_DIR}/app.html

${DBG_DIR}/app.js: ${APP_COFFEE}
	coffee -b -p -c ${APP_COFFEE} > ${DBG_DIR}/app.js

${DBG_DIR}/ui.js: ${SRC_DIR}/ui.*.coffee
	coffee -b -p -c ${SRC_DIR}/ui.*.coffee | cat > ${DBG_DIR}/ui.js

${DBG_DIR}/app.css: ${SRC_DIR}/app.sass ${SRC_DIR}/sass/*.sass
	sass --style compressed --no-cache ${SRC_DIR}/app.sass ${DBG_DIR}/app.css

${DBG_DIR}/cs_addlink.js: ${SRC_DIR}/cs_addlink.coffee
	coffee -b -p -c ${SRC_DIR}/cs_addlink.coffee | cat > ${DBG_DIR}/cs_addlink.js

${DBG_DIR}/lib/: ${LIB_FILES}
	rm -rf ${DBG_DIR}/lib/
	cp -r ${SRC_DIR}/lib/ ${DBG_DIR}/lib/

${DBG_DIR}/img/: ${IMG_FILES}
	rm -rf ${DBG_DIR}/img/
	cp -r ${SRC_DIR}/img/ ${DBG_DIR}/img/

${DBG_DIR}/test/: ${QUNIT_FILES}
	rm -rf ${DBG_DIR}/test/
	mkdir ${DBG_DIR}/test/
	cp ${SRC_DIR}/test/test.html ${DBG_DIR}/test/test.html
	cp -r ${SRC_DIR}/test/qunit/ ${DBG_DIR}/test/qunit/

${DBG_DIR}/test/test.js: ${DBG_DIR}/test/ ${SRC_DIR}/test/*.coffee
	coffee -b -p -c ${SRC_DIR}/test/*.coffee | cat > ${DBG_DIR}/test/test.js

