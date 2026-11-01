# ###############################################################
# ###############################################################
# COPY THIS FILE TO toto-terra (renamed to <name of the microservice>.tf)
#
# It creates, in each toto GCP project (applied once per environment),
# what a microservice hosted on the external GKE cluster needs:
# the Artifact Registry repository, the GitHub environment used by the
# CI/CD pipeline, the secrets, and the IAM grants to the pod's identity.
#
# Requires the toto-terra variables gke_project_id and gke_project_number
# (see the toto-terra-gke README).
# ###############################################################
# ###############################################################

# ---------------------------------------------------------------
# 1. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-xxx-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-xxx"
    format = "DOCKER"
    description = "Toto MS XXX Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

    cleanup_policy_dry_run = false
    cleanup_policies {
        id     = "keep-minimum-versions"
        action = "KEEP"
        most_recent_versions {
            keep_count            = 1
        }
    }
}

# The GKE nodes (service account gke-nodes of the GKE project) pull the images of this repository
resource "google_artifact_registry_repository_iam_member" "toto-ms-xxx-registry-gke-reader" {
    project = google_artifact_registry_repository.toto-ms-xxx-registry.project
    location = google_artifact_registry_repository.toto-ms-xxx-registry.location
    repository = google_artifact_registry_repository.toto-ms-xxx-registry.name
    role = "roles/artifactregistry.reader"
    member = format("serviceAccount:gke-nodes@%s.iam.gserviceaccount.com", var.gke_project_id)
}

# ---------------------------------------------------------------
# 2. Github environment secrets & variables (used by the release-*.yml workflows)
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-xxx-github-environment" {
    repository = "toto-ms-xxx"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-xxx-secret-cicdsakey" {
    repository = "toto-ms-xxx"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ms-xxx-var-pid" {
    repository = "toto-ms-xxx"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}

# ---------------------------------------------------------------
# 3. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
# REMOVE IF THE MICROSERVICE HAS NO DATABASE
variable "toto_ms_xxx_mongo_user" {
    description = "Mongo User for xxx"
    type = string
    sensitive = true
}
variable "toto_ms_xxx_mongo_pswd" {
    description = "Mongo Password for xxx"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-xxx-mongo-user" {
    secret_id = "toto-ms-xxx-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-xxx-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-xxx-mongo-user.id
    secret_data = var.toto_ms_xxx_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-xxx-mongo-pswd" {
    secret_id = "toto-ms-xxx-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-xxx-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-xxx-mongo-pswd.id
    secret_data = var.toto_ms_xxx_mongo_pswd
}

# ---------------------------------------------------------------
# 4. GKE Cluster authorization
# The pod runs as the Kubernetes Service Account "toto-ms-xxx" in the namespace of the
# environment (var.toto_environment: dev or prod). Through Workload Identity Federation
# for GKE, it is this principal in IAM: roles are granted to it directly (no Google SA, no key).
# ---------------------------------------------------------------
locals {
    toto_ms_xxx_gke_principal = format(
        "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/toto-ms-xxx",
        var.gke_project_number,
        var.gke_project_id,
        var.toto_environment,
    )
}
resource "google_project_iam_member" "toto-ms-xxx-gke-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = local.toto_ms_xxx_gke_principal
}
# UNCOMMENT WHAT THE MICROSERVICE NEEDS
# resource "google_project_iam_member" "toto-ms-xxx-gke-role-gcs" {
#     project = var.gcp_pid
#     role = "roles/storage.admin"
#     member = local.toto_ms_xxx_gke_principal
# }
# resource "google_project_iam_member" "toto-ms-xxx-gke-role-pubsub" {
#     project = var.gcp_pid
#     role = "roles/pubsub.publisher"
#     member = local.toto_ms_xxx_gke_principal
# }
# resource "google_project_iam_member" "toto-ms-xxx-gke-role-aiplatform" {
#     project = var.gcp_pid
#     role = "roles/aiplatform.user"
#     member = local.toto_ms_xxx_gke_principal
# }
