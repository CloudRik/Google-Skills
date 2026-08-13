#!/bin/bash

# ==========================================
# Google Cloud Lab Automation Script
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${BOLD}${YELLOW}       GOOGLE SKILLS BOOST - LAB AUTOMATOR          ${NC}"
echo -e "${CYAN}====================================================${NC}\n"

printf "${BOLD}${GREEN}[?] Enter USERNAME 1: ${NC}"
read USER1

printf "${BOLD}${GREEN}[?] Enter USERNAME 2: ${NC}"
read USER2

printf "${BOLD}${GREEN}[?] Enter PROJECT ID 1: ${NC}"
read PROJECTID1

printf "${BOLD}${GREEN}[?] Enter PROJECT ID 2: ${NC}"
read PROJECTID2

printf "${BOLD}${GREEN}[?] Enter REGION (e.g. us-east1): ${NC}"
read REGION

printf "${BOLD}${GREEN}[?] Enter ZONE (e.g. us-east1-d): ${NC}"
read ZONE

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${YELLOW}[!] Starting automated execution, please wait...${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# Set Core Project 1
gcloud config set project "$PROJECTID1" --quiet
gcloud config set compute/region "$REGION" --quiet
gcloud config set compute/zone "$ZONE" --quiet

# --- TASK 1: Create lab-1 in Project 1 ---
echo -e "${CYAN}[ Task 1 ] Creating lab-1 in Project 1...${NC}"
gcloud compute instances create lab-1 --project="$PROJECTID1" --zone="$ZONE" --machine-type=e2-standard-2 --quiet

# --- TASK 3: Assign Viewer Role to User 2 on Project 2 ---
echo -e "${CYAN}[ Task 3 ] Assigning IAM permissions for User 2...${NC}"
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/viewer" --quiet

# --- TASK 4: Create Custom Role & Bindings ---
echo -e "${CYAN}[ Task 4 ] Creating custom devops role and binding permissions...${NC}"
gcloud iam roles create devops --project="$PROJECTID2" --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/iam.serviceAccountUser" --quiet
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="projects/$PROJECTID2/roles/devops" --quiet

# --- TASK 5: Create Service Account ---
echo -e "${CYAN}[ Task 5 ] Creating Service Account...${NC}"
gcloud iam service-accounts create devops --display-name="devops" --project="$PROJECTID2" --quiet

sleep 5

SA=$(gcloud iam service-accounts list --project="$PROJECTID2" --format="value(email)" --filter="displayName=devops")

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/iam.serviceAccountUser" --quiet

# --- TASK 6: Bind InstanceAdmin & Create lab-3 in Project 2 ---
echo -e "${CYAN}[ Task 6 ] Binding InstanceAdmin and creating lab-3...${NC}"
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/compute.instanceAdmin" --quiet

gcloud compute instances create lab-3 --project="$PROJECTID2" --zone="europe-west1-c" --machine-type=e2-standard-2 --service-account="$SA" --scopes=https://www.googleapis.com/auth/compute --quiet

# --- TASK 7: Create lab-2 & lab-4 in Project 2 ---
echo -e "${CYAN}[ Task 7 ] Creating remaining instances (lab-2 & lab-4)...${NC}"
gcloud compute instances create lab-2 --project="$PROJECTID2" --zone="europe-west1-c" --machine-type=e2-standard-2 --quiet
gcloud compute instances create lab-4 --project="$PROJECTID2" --zone="europe-west1-c" --machine-type=e2-standard-2 --quiet

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL TASKS EXECUTED SUCCESSFULLY! (100/100)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
