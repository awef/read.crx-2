sed -r -e "s/\"0\.[0-9]+\"/\"0\.$1\"/" -i src/manifest.json
find src -name *.haml -exec sed -r -e "s/app_version = \"0\.[0-9]+\"/app_version = \"0.$1\"/" -i {} \;

rake clean
rake

rm ./read.crx_2.zip
zip -9 -r -X -T ./read.crx_2.zip ./debug -x ./debug/test/\*

clamscan ./read.crx_2.zip

google-chrome chrome-extension://pjgcfbpjgcmblkffcjfmdgcgmdhdaohh/test/test.html
