ECRREPOURI	:= "903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo"

build:
	docker build -t pm2-express-demo .
build-pm2:
	docker build -t pm2-express-demo:pm2 -f Dockerfile.pm2 .
run:
	docker run -ti -p 8080:8080 pm2-express-demo:latest
run-pm2:
	docker run -ti -p 8080:8080 pm2-express-demo:pm2
tag:
	docker tag pm2-express-demo:latest $(ECRREPOURI)
push:
	docker push $(ECRREPOURI)
