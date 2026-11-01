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
* [On GKE in a separate GCP project](#deploying-on-gke-separate-gcp-project)
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
### Deploying on GKE (Separate GCP Project)
It is possible to deploy a microservice on a GKE cluster, in a **separate GCP Project**. 

*Use this when you have access to a GKE cluster and want to deploy there the microservice*.

To use this: 

1. Make sure you have a **compliant GKE cluster**. Read the [Guide to Toto Terraforming for GKE](https://github.com/nicolasances/toto-terra-gke)

2. **Name and base path.** 
    - The `name` in `package.json` **must be the microservice name** (e.g. `toto-ms-xyz`): the CI/CD pipeline uses it to name the Docker image and its Artifact Registry repository, and the Terraform files use the same name.
    - Set a `basePath` in `src/index.ts` (e.g. `basePath: '/xyz'`). The basepath is **mandatory** on GKE: all microservices share the same hostname and the Kubernetes Gateway routes on the path, so it must be **unique** across microservices.

3. **Move** the folder `.github` (under `gke-external`) to the root of the project. <br>
The `release-*.yml` workflows build the Docker image and push it to the environment's Artifact Registry, tagged with the `package.json` **version** (dev: on `feature/**` and `main`, prod: on `release/**`). They do not deploy: the deployment is done by Terraform (step 6).

4. Update the Terraform files in the `gke-external/terraform` folder: 
    - Replace all occurrences of `toto-ms-xxx` or `toto_ms_xxx` with the microservice name. 
    - In `toto-ms-xxx.toto-terra-gke.tf`, replace `<basepath>` with the `basePath` of `src/index.ts` **without the leading slash**.
    - In `toto-ms-xxx.toto-terra.tf`, remove the Mongo secrets if the microservice has no database, and uncomment the extra roles it needs (Cloud Storage, Pub/Sub, Vertex AI).
    - Rename both files to `<microservice name>.tf`. *E.g.: `toto-ms-expenses`*

5. **toto-terra** (the toto GCP projects): move `toto-ms-xxx.toto-terra.tf` to `toto-terra`, commit and **push**, and apply it on **both** environments. <br>
It creates the Artifact Registry repository (readable by the GKE nodes), the GitHub environment used by the pipeline, the secrets, and the IAM grants to the pod's identity (Workload Identity). <br>
    - 5.1. **Push the microservice code**, so that the pipeline pushes the first image (step 3). **The image must exist before step 6**, otherwise the Deployment never becomes ready and the `terraform apply` times out.

6. **toto-terra-gke** (the GKE cluster): 
    - Move `toto-ms-xxx.toto-terra-gke.tf` to the **`workloads/`** folder of `toto-terra-gke`, commit and **push**. 
    - Add the image tag of each environment to `scripts/tf-env.template.sh` and to your own env file: <br>
    `export TF_VAR_<microservice_name>_image_tag='{"dev":"1.0.0","prod":"1.0.0"}'` (`<microservice_name>` with underscores, e.g. `toto_ms_xyz`).
    - On the Terraform VM: `source` your env file, then run `terraform apply` in `workloads/`. That deploys the microservice in the `dev` and `prod` namespaces and exposes it on `https://<environment hostname>/<basepath>`.

#### Deploying a new version on GKE
1. **Bump the `version` in `package.json`** and push: the pipeline pushes the image with the new tag. <br>
*If the version is not bumped, the existing tag is overwritten with the new image: Terraform sees no change and the pods keep running the old image.*
2. Update the version in `TF_VAR_<microservice_name>_image_tag` (only for the environment you deploy), `source` your env file, and `terraform apply` in `workloads/`.

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



