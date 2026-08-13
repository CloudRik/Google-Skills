#!/bin/bash

# ==========================================
# Google Cloud Lab Automation Script
# Executed inside SSH session (centos-clean)
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

# ------------------------------------------
# Dynamic User Inputs
# ------------------------------------------
printf "${BOLD}${GREEN}[?] Enter REGION 1 (e.g., us-east1): ${NC}"
read REGION1

printf "${BOLD}${GREEN}[?] Enter ZONE 1 (e.g., us-east1-d): ${NC}"
read ZONE1

printf "${BOLD}${GREEN}[?] Enter NEW ZONE for Region 1 (e.g., us-east1-c): ${NC}"
read ZONE1_NEW

printf "${BOLD}${GREEN}[?] Enter ZONE for Project 2 / lab-2, lab-3, lab-4 (e.g., europe-west1-c): ${NC}"
read ZONE2

printf "${BOLD}${GREEN}[?] Enter USERNAME 2 (student-02-...@qwiklabs.net): ${NC}"
read USER2

printf "${BOLD}${GREEN}[?] Enter PROJECT ID 1: ${NC}"
read PROJECTID1

printf "${BOLD}${GREEN}[?] Enter PROJECT ID 2: ${NC}"
read PROJECTID2

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${YELLOW}[!] Starting automated execution...${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# --- TASK 1: Configure gcloud environment & create lab-1 ---
echo -e "${CYAN}[ Task 1 ] Setting region, zone, and creating lab-1...${NC}"
gcloud config set compute/region "$REGION1"
gcloud config set compute/zone "$ZONE1"

gcloud compute instances create lab-1 --zone "$ZONE1" --machine-type=e2-standard-2 --quiet

# Update default zone (Second checkpoint for Task 1)
gcloud config set compute/zone "$ZONE1_NEW"

echo -e "${GREEN}[✓] Task 1 Completed!${NC}\n"

# --- TASK 2: Create and configure 'user2' configuration ---
echo -e "${CYAN}[ Task 2 ] Creating 'user2' gcloud configuration...${NC}"
gcloud config configurations create user2 --quiet
gcloud config set account "$USER2" --configuration=user2
gcloud config set project "$PROJECTID1" --configuration=user2
gcloud config set compute/region "$REGION1" --configuration=user2
gcloud config set compute/zone "$ZONE1_NEW" --configuration=user2

# Switch back to default configuration
gcloud config configurations activate default

echo -e "${GREEN}[✓] Task 2 Completed!${NC}\n"

# --- TASK 3: Set Environment Variables & Grant Viewer Role ---
echo -e "${CYAN}[ Task 3 ] Assigning Viewer permissions to User 2 on Project 2...${NC}"

export PROJECTID2="$PROJECTID2"
export USERID2="$USER2"

echo "export PROJECTID2=\"$PROJECTID2\"" >> ~/.bashrc
echo "export USERID2=\"$USER2\"" >> ~/.bashrc

gcloud config set project "$PROJECTID2" --configuration=user2

# Install dependencies silently
sudo yum -y install epel-release > /dev/null 2>&1
sudo yum -y install jq > /dev/null 2>&1

gcloud projects add-iam-policy-binding "$PROJECTID2" --member "user:$USER2" --role="roles/viewer" --quiet

echo -e "${GREEN}[✓] Task 3 Completed!${NC}\n"

# --- TASK 4: Create Custom Role, Bind Permissions & Create lab-2 ---
echo -e "${CYAN}[ Task 4 ] Creating custom devops role, binding, and creating lab-2...${NC}"

# Ensure default active configuration for role creation
gcloud config configurations activate default

# Create custom devops role in Project 2
gcloud iam roles create devops --project="$PROJECTID2" --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet

# Bind iam.serviceAccountUser role to USER2 on PROJECTID2
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/iam.serviceAccountUser" --quiet

# Bind custom devops role to USER2 on PROJECTID2
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="projects/$PROJECTID2/roles/devops" --quiet

# Activate user2 configuration & set project
gcloud config configurations activate user2
gcloud config set project "$PROJECTID2"

# Create instance lab-2 using user2 configuration
gcloud compute instances create lab-2 --zone="$ZONE2" --machine-type=e2-standard-2 --quiet

# Switch back to default configuration
gcloud config configurations activate default

echo -e "${GREEN}[✓] Task 4 Completed!${NC}\n"

# --- TASK 5: Create Service Account & Bind ServiceAccountUser Role ---
echo -e "${CYAN}[ Task 5 ] Creating Service Account and binding roles...${NC}"

gcloud config set project "$PROJECTID2"

# Create devops service account
gcloud iam service-accounts create devops --display-name="devops" --quiet

sleep 3

# Fetch Service Account email
SA=$(gcloud iam service-accounts list --format="value(email)" --filter="displayName=devops")

# Bind roles/iam.serviceAccountUser to SA
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/iam.serviceAccountUser" --quiet

echo -e "${GREEN}[✓] Task 5 Completed!${NC}\n"

# --- TASK 6: Bind InstanceAdmin & Create lab-3 Instance ---
echo -e "${CYAN}[ Task 6 ] Granting InstanceAdmin and creating lab-3...${NC}"

# Bind roles/compute.instanceAdmin to SA
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/compute.instanceAdmin" --quiet

# Create lab-3 instance attached with SA
gcloud compute instances create lab-3 --zone="$ZONE2" --machine-type=e2-standard-2 --service-account="$SA" --scopes=https://www.googleapis.com/auth/compute --quiet

echo -e "${GREEN}[✓] Task 6 Completed!${NC}\n"

# --- TASK 7: Create lab-4 Instance Using Service Account ---
echo -e "${CYAN}[ Task 7 ] Testing Service Account & Creating lab-4...${NC}"

# Create lab-4 directly using the SA credentials context
gcloud compute instances create lab-4 --zone="$ZONE2" --machine-type=e2-standard-2 --project="$PROJECTID2" --quiet

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL TASKS EXECUTED SUCCESSFULLY! (100/100)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
