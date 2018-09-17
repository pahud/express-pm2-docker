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



## Benchmark

install `loadtest`

```
npm i loadtest -g
```

Load test localhost:8080 with 1000 requests

```
loadtest -n 1000 -c 100 http://localhost:8080
```



## Push image to Amazon ECR

create an ECR repository



```
$ aws ecr create-repository --repository-name  pm2-express-demo
{
    "repository": {
        "registryId": "{AWS_ACCOUNT_ID}",
        "repositoryName": "pm2-express-demo",
        "repositoryArn": "arn:aws:ecr:us-west-2:{AWS_ACCOUNT_ID}:repository/pm2-express-demo",
        "createdAt": 1537113651.0,
        "repositoryUri": "{AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo"
    }
}
```



update `Makefile`, set **ECRREPOURI** to your `repositoryUri`.

ECR get-login to load the docker credentials

```
$ aws ecr get-login --no-include-email  | sh
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```

**make push** to push image to ECR

```
$ make push
docker push "903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo"
The push refers to repository [903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo]
3285a765a44b: Pushed
5456ca3e5aec: Pushed
07130fcbbf8f: Pushed
6cb47fb521a1: Pushed
287ef32bfa90: Pushed
ce291010afac: Pushed
73046094a9b8: Pushed
latest: digest: sha256:a0f40accbb1241f02da217affdfcabebc39e1fa9aa8d52ad7684cdb2ac594f89 size: 1783
```



## Start Service on Fargate with fargate-cli

Install `fargate-cli` from [here](http://somanymachines.com/fargate/). 

(please note the latest release of fargate-cli doesn't support some regions. You may need to build the binary from its master branch manually, see [tweet](https://twitter.com/pahudnet/status/1040233349141295104) and [PR](https://github.com/jpignata/fargate/pull/62))



create a ALB

```
$ fargate --region us-west-2 lb create demoalb -p 80 --security-group-id sg-0a08f8ad32663513b
 ℹ️  Created load balancer demoalb
```

create a service

```
$ fargate --region us-west-2 service create demoexpress -l demoalb -p http:8080 -i 903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo
[i] Created service demoexpress
```



```
$ fargate --region us-west-2 service list
NAME		IMAGE								CPU	MEMORY	LOAD BALANCER	DESIRED	RUNNING	PENDING
demoexpress	903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo	256	512	demoalb		10	1
$ fargate --region us-west-2 service ps demoexpress
ID					IMAGE								STATUS	RUNNING	IP		CPU	MEMORY
334d258a-67a3-41f4-8e25-d540c6dc0d0c	903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo	running	28s	34.209.200.232	256	512
```

check the load balancer DNS Name

```
$ fargate --region us-west-2 service info demoexpress
Service Name: demoexpress
Status:
  Desired: 1
  Running: 1
  Pending: 0
Image: 903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo
Cpu: 256
Memory: 512
Subnets: subnet-891e28ef, subnet-8892c4c0, subnet-63dc3339
Security Groups: sg-0d85e9e4b127e2245
Load Balancer:
  Name: demoalb
  DNS Name: demoalb-924358308.us-west-2.elb.amazonaws.com
  Ports:
    HTTP:80:
      Rules: DEFAULT=
[...]
```

test with cURL CLI

```
$ curl http://demoalb-924358308.us-west-2.elb.amazonaws.com
Hello World
```



### Deploy new image to Fargate

1. edit `src/app.js` 

2. `make build` to build the image again

3. manual tag the image, for example tag as `903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo:dev` and push to ECR

   ```
   $ docker tag pm2-express-demo:latest 903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo:dev
   // push to ECR
   $ docker push 903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo:dev
   ```

4. update the Fargate service with new Image

   ```
   $ fargate --region us-west-2 service deploy demoexpress -i 903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo:dev
   ```

5. check the process of update

   ```
   fargate --region us-west-2 service ps demoexpress
   ```

6. cURL the ALB again

   ```
   $ curl http://demoalb-924358308.us-west-2.elb.amazonaws.com
   Hello Taipei
   ```



To accelerate the deployment and serivce update, you can reduce the deregistration deplay default value from 300sec to 30sec or even 10sec. Check this [tweet](https://twitter.com/pahudnet/status/1041380473186840581).



### delete the Fargate service and clean up

```
$ fargate --region us-west-2 service scale demoexpress 0
[i] Scaled service demoexpress to 0

$ fargate --region us-west-2 service destroy demoexpress
[i] Destroyed service demoexpress
```



# CI/CD pipeline

1. create a private git repo in GitHub, e.g. `fargate-cicd-0917`

2. create another git remote repo and point to the new github repo like this:

   ```
   git remote add fargatecicd git@github.com:pahud/fargate-cicd-0917.git
   ```

3. push local repo to `fargatecicd` 

   ```
   git push -u fargatecicd master
   ```


4. create a CodePipeline with Github as the source.
5. Configure CodeBuild and the build provider, set `imagedefinitions.json` as the output docker image filename.
6. Set Amazon ECS as the Deployment Provider to cluster `fargate` and service name `demoexpress`
7. You may edit the `src/app.js` in github web page by clicking the edit button. By clicking the save button, your CodePipeline will be triggered immediately and the whole CI/CD pipeline will take about 5 minutes to complete.



# Deploy to Amazon EKS

follow [pahud/amazon-eks-workshop](https://github.com/pahud/amazon-eks-workshop) to create your Amazon EKS cluster with eksctl ([walkthrough](https://github.com/pahud/amazon-eks-workshop/blob/master/00-getting-started/create-eks-with-eksctl.md)).

```
// run the deployment
$ kubectl run demoexpress --port 8080 --image 903779448426.dkr.ecr.us-west-2.amazonaws.com/pm2-express-demo:latest
// expose the deployment as LoadBalancer type service
$ kubectl expose deploy/demoexpress --port 80 --target-port 8080 --type LoadBalancer
// describe the service
$ kubectl describe svc/demoexpress

Name:                     demoexpress
Namespace:                default
Labels:                   run=demoexpress
Annotations:              <none>
Selector:                 run=demoexpress
Type:                     LoadBalancer
IP:                       10.100.73.61
LoadBalancer Ingress:     ae64442c3b9e111e8a83b0a17b84b3b7-296496059.us-west-2.elb.amazonaws.com
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31615/TCP
Endpoints:                192.168.93.124:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  8s    service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   5s    service-controller  Ensured load balancer

```

Get the LB DNS name from `LoadBalancer Ingress` and try cURL on it

```
$ curl ae64442c3b9e111e8a83b0a17b84b3b7-296496059.us-west-2.elb.amazonaws.com
Hello There!
```

Check more basic Kubernetes administratiev operations [here](https://github.com/pahud/amazon-eks-workshop/blob/master/02-kubectl-basic-admin/kubectl-basic-admin.md).
