# express-pm2-docker

sample reference artifacts running [Express](https://github.com/expressjs/express) with [PM2](http://pm2.keymetrics.io/) on Docker



Build the docker image

```bash
$ make build-pm2
```



Run PM2 with Docker

```Bash
$ make run-pm2
```





## TODO

- push docker images to Amazon ECR
- deploy as a service in Amazon ECS/Fargate/EKS or common Kubernetes environment
- CI/CD pipeline