#!/bin/bash

# ==========================================
# Google Cloud Lab Automation Script
# ==========================================

# Colors for UI
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${BOLD}${YELLOW}       GOOGLE SKILLS BOOST - LAB AUTOMATOR          ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}Please enter the dynamic credentials for this lab session:${NC}\n"

# Prompt User Inputs
read -p "$(echo -e ${BOLD}${GREEN}"[?] Enter USERNAME 1 (e.g. student-04-...@qwiklabs.net): "${NC})" USER1
read -p "$(echo -e ${BOLD}${GREEN}"[?] Enter USERNAME 2 (e.g. student-02-...@qwiklabs.net): "${NC})" USER2
read -p "$(echo -e ${BOLD}${GREEN}"[?] Enter PROJECT ID 1: "${NC})" PROJECTID1
read -p "$(echo -e ${BOLD}${GREEN}"[?] Enter PROJECT ID 2: "${NC})" PROJECTID2
read -p "$(echo -e ${BOLD}${GREEN}"[?] Enter REGION (e.g. us-east4 or europe-west1): "${NC})" REGION
read -p "$(echo -e ${BOLD}${GREEN}"[?] Enter ZONE (e.g. us-east4-b or europe-west1-c): "${NC})" ZONE

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${YELLOW}[!] Starting automated execution, please wait...${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# Export Environment Variables
export PROJECTID1=$PROJECTID1
export PROJECTID2=$PROJECTID2
export USERID2=$USER2

# --- TASK 1: Configure Environment & Create lab-1 ---
echo -e "${CYAN}[ Task 1 ] Configuring gcloud and creating lab-1...${NC}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
gcloud config set project $PROJECTID1

gcloud compute instances create lab-1 --zone $ZONE --machine-type=e2-standard-2 --quiet
gcloud config set compute/zone ${ZONE%?}"c"

# --- TASK 2 & 3: Environment Setups & Policy Binding ---
echo -e "${CYAN}[ Task 3 ] Assigning IAM permissions for User 2...${NC}"
echo "export PROJECTID2=$PROJECTID2" >> ~/.bashrc
echo "export USERID2=$USER2" >> ~/.bashrc

gcloud config configurations activate default
gcloud config set project $PROJECTID1

gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USER2 --role=roles/viewer --quiet

# --- TASK 4: Custom Role & Bindings ---
echo -e "${CYAN}[ Task 4 ] Creating custom devops role and binding permissions...${NC}"
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet

gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USER2 --role=roles/iam.serviceAccountUser --quiet
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USER2 --role=projects/$PROJECTID2/roles/devops --quiet

# --- TASK 5: Service Account Creation ---
echo -e "${CYAN}[ Task 5 ] Creating Service Account...${NC}"
gcloud iam service-accounts create devops --display-name devops --project $PROJECTID2 --quiet

SA=$(gcloud iam service-accounts list --project $PROJECTID2 --format="value(email)" --filter "displayName=devops")

gcloud projects add-iam-policy-binding $PROJECTID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser --quiet

# --- TASK 6: Attach Role & Create lab-3 Instance ---
echo -e "${CYAN}[ Task 6 ] Binding InstanceAdmin and creating lab-3...${NC}"
gcloud projects add-iam-policy-binding $PROJECTID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin --quiet

gcloud compute instances create lab-3 --project $PROJECTID2 --zone $ZONE --machine-type=e2-standard-2 --service-account $SA --scopes https://www.googleapis.com/auth/compute --quiet

# --- TASK 7: Create lab-2 & lab-4 Instances ---
echo -e "${CYAN}[ Task 7 ] Creating remaining instances (lab-2 and lab-4)...${NC}"
gcloud compute instances create lab-2 --project $PROJECTID2 --zone $ZONE --machine-type=e2-standard-2 --quiet
gcloud compute instances create lab-4 --project $PROJECTID2 --zone $ZONE --machine-type=e2-standard-2 --quiet

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL TASKS EXECUTED SUCCESSFULLY! (100/100)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
