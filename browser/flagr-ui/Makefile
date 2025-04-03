version:
	n exec 16.20.2 node --version
	
install:
	n exec 16.20.2 npm install

serve:
	n exec 16.20.2 npm run serve

build:
	docker pull ghcr.io/openflagr/flagr

run:
	docker run -it -d -p 18000:18000 ghcr.io/openflagr/flagr