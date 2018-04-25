build:
	docker build -t pm2-express-demo .
build-pm2:
	docker build -t pm2-express-demo:pm2 -f Dockerfile.pm2 .
run:
	docker run -ti -p 8080:8080 pm2-express-demo:latest
run-pm2:
	docker run -ti -p 8080:8080 pm2-express-demo:pm2
