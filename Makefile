full:
	mkdir -p build/full
	cp -r * build/full
	chmod +x /build/lite/install.sh
	cd build && tar czf DrBash-full.tar.gz full/
	rm -rf /build/lite

lite:
	mkdir -p build/lite
	cp -r * build/lite
	rm -rf build/lite/media.shd
	chmod +x /build/lite/install.sh
	cd build && tar czf DrBash-lite.tar.gz lite/
	rm -rf /build/lite

install:
	chmod +x ./install.sh && ./install.sh
