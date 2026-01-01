# Template for Toto NodeJS Microservices
This repo serves as a template to create new Toto NodeJS Microservices. 

Follow these steps: 

## 1. Clone the Repository
The last parameter will allow you to clone the template to a specific target directory (e.g. `toto-ms-xyz`)
```
git clone https://github.com/nicolasances/toto-node-template <target directory>
```

## 2. Create a new Repo 
Go on Github and create a new Git Repo for `toto-ms-xyz`. 

## 3. Set the new Origin URL
CD to the target directory (`toto-ms-xyz`) and set the new Origin URL to the newly created repo for the new microservice. 
```bash
git remote set-url origin <new-repo-url>
```

## 4. Install dependencies and start the Microservice
Install NPM dependencies through `npm i` and then you should be able to start the microservice through <br>
`npm run start:dev`

## 5. Change core configurations
The following will need to be done: 
 - Update `index.ts` by chaning the API name and adding the endpoints of the service
 - Update `Config.ts` to make sure you're downloading the right secrets and that the configurations are ok (e.g. db names, collections, etc..)
 - Update `package.json` and change the **package name** and eventually description and version



## 6. Create your first Endpoint
To do that, follow this resource: 
 * [Create a Delegate (endpoint)](./docs/create-dlg.md)



## 7. Configuring for Cloud Deployment

Toto Microservices can be deployed:
* [On GCP (Cloud Run)](#deploying-on-gcp-cloud-run)
* [On AWS (ECS)](#deploying-on-aws-ecs)


### Database
Before running the `terraform apply`, remember to do the following: 

* Create any DB configuration needed first (e.g. create the user on the db). <br>
Remember that to create a user on Mongo, you should run this: 
```
use <db_name>
db.createUser({user: "toto-ms-xxx", pwd: passwordPrompt(), roles: [{db: "<db_name>", role: "readWrite"}]})
```

If you have created a user, you'll want secrets and you'll have to modify the terraform files if you want that secret to be automatically created on the Secrets Manager.

---
### Deploying on GCP (Cloud Run)
To deploy this service on GCP (Cloud Run) you need to: 

1. Make sure you have a **compliance GCP environment**. Follow the [Guide to Deploying Toto on GCP with Terraform](https://github.com/nicolasances/toto-terra). 

1. **Move** the folder `.github` (under `gcp`) to the root of the project.

2. Uncomment the sections of the `release-*.yml` files that are commented. 

3. Fix the Terraform file (`gcp/terraform/toto-ms-xxx.tf`): 
    * Rename to the name of the microservice
    * Replace all occurrences of `toto-ms-xxx` and `toto_ms_xxx` to use the name of the microservice instead

4. Move the Terraform file to `toto-terra`, commit and **push**. <br>
That will trigger a job on Terraform Cloud. 

---
### Deploying on AWS (ECS)
To deploy this service on AWS (ECS) you will need to: 
 
1. Make sure you have a **compliant AWS environment**. Follow the [Guide to Deploying Toto on AWS with Terraform](https://github.com/nicolasances/toto-aws-terra). <br>
Once the environment has been terraformed, you can follow the next steps. 

2. **Create needed Secrets in Secrets Manager**. <br>
A Secrets Manager needs to be **manually** configured with the following secrets (**IMPORTANT**: on AWS use **plaintext secrets** to store the secret, **not the key-value pair ones**): 
    * `<env>/toto-expected-audience` - the audience for the auth token.
    * `<env>/jwt-signing-key` - the JWT signing key used to sign the JWT tokens when using Toto as a custom auth provider.

3. **Configure the Microservice basepath.** <br> 
Toto Microservices deployed on AWS are exposed through a Load Balancer with path-based rooting, so you need a **base path** unique to this microservice. <br>
*Note: you need to be on version 13+ of the `toto-api-controller` ([see docs here](https://github.com/nicolasances/node-toto-api-controller/blob/master/docs/13.0.0.md) if you want more context) <br>
For that, in `index.ts` make sure you configure the base path in the API Controller. <br>
Here's an example: <br>
`const api = new TotoAPIController("toto-ms-ex1", new ControllerConfig(), { basePath: '/ex1' });`

4. **Update the CI/CD pipeline**
Take the files `aws/codebuild/buildspec-*.yml` and update the following line, replacing `toto-ms-ex1` with the name of your microservice: 
```
- export IMAGE=toto-ms-ex1
```

*These files are the definition of the Build project (for dev and prod) on AWS CodeBuild. They will be part of the pipeline run on AWS CodePipeline*. 

5. **Run the Microservice Terraform**
    * Take the file `aws/terraform/toto-ms-ex1.tf`:
        * **rename it** with your microservice name (name of the repo)
        * **modify the file**: 
            * rename all the occurencies of `toto-ms-ex1` with your microservice name.
            * rename all the resources name that should have the prefix `toto_ms_ex1_<something>` to `<name_of_your_ms>_<something>`.
            * rename the path in the **path condition** of `aws_lb_listener_rule`: instead of `values = ["/ex1/*"]` it should contain the **base path that you configured for your service**.
        * **copy it to** `toto-aws-terra` 
    * **Run Terraform** on the target environment.

6. **IMPORTANT NOTE!** <br>
AWS CodePipeline can only listen to **fixed branches**. <br>
That means that, while you can use any branch to organize your code and develop, **only two branches will allow for automated CI/CD**, so you ***must have two branches with those names***: 
    * dev
    * prod 

7. **Push the code**<br>
Push this microservice's code to the chosen Github branch (dev or prod) and the CodePipeline on AWS will be automatically taking care of the rest. 



