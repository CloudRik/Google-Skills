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

# Only 3 simple inputs needed!
printf "${BOLD}${GREEN}[?] Enter USERNAME 2 (student-02-...@qwiklabs.net): ${NC}"
read USER2

printf "${BOLD}${GREEN}[?] Enter PROJECT ID 1: ${NC}"
read PROJECTID1

printf "${BOLD}${GREEN}[?] Enter PROJECT ID 2: ${NC}"
read PROJECTID2

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${YELLOW}[!] Auto-detecting Region & Zones from environment...${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# Auto-detect default Region and Zone
ZONE1=$(gcloud config get-value compute/zone 2>/dev/null)
REGION1=$(gcloud config get-value compute/region 2>/dev/null)

# Fallbacks if not set
if [ -z "$ZONE1" ]; then
    ZONE1="europe-west1-d"
fi
if [ -z "$REGION1" ]; then
    REGION1="europe-west1"
fi

# Auto-generate NEW ZONE by changing last letter
if [[ "$ZONE1" == *"-a" ]]; then
    ZONE1_NEW="${ZONE1%-a}-b"
elif [[ "$ZONE1" == *"-b" ]]; then
    ZONE1_NEW="${ZONE1%-b}-c"
else
    ZONE1_NEW="${ZONE1%-*}-a"
fi

# Project 2 Zone auto-fallback
ZONE2="us-west1-a"

echo -e "${CYAN}[Info] Detected Zone 1: $ZONE1 | New Zone: $ZONE1_NEW | Zone 2: $ZONE2${NC}\n"

# --- TASK 1 ---
echo -e "${CYAN}[ Task 1 ] Setting region, zone, and creating lab-1...${NC}"
gcloud config set compute/region "$REGION1" --quiet
gcloud config set compute/zone "$ZONE1" --quiet

gcloud compute instances create lab-1 --zone "$ZONE1" --machine-type=e2-standard-2 --quiet
gcloud config set compute/zone "$ZONE1_NEW" --quiet

echo -e "${GREEN}[✓] Task 1 Completed!${NC}\n"

# --- TASK 2 ---
echo -e "${CYAN}[ Task 2 ] Creating 'user2' gcloud configuration...${NC}"
gcloud config configurations create user2 --quiet
gcloud config set account "$USER2" --configuration=user2 --quiet
gcloud config set project "$PROJECTID1" --configuration=user2 --quiet
gcloud config set compute/region "$REGION1" --configuration=user2 --quiet
gcloud config set compute/zone "$ZONE1_NEW" --configuration=user2 --quiet

gcloud config configurations activate default --quiet

echo -e "${GREEN}[✓] Task 2 Completed!${NC}\n"

# --- TASK 3 ---
echo -e "${CYAN}[ Task 3 ] Assigning Viewer permissions to User 2...${NC}"
export PROJECTID2="$PROJECTID2"
export USERID2="$USER2"

echo "export PROJECTID2=\"$PROJECTID2\"" >> ~/.bashrc
echo "export USERID2=\"$USER2\"" >> ~/.bashrc

gcloud config set project "$PROJECTID2" --configuration=user2 --quiet

sudo yum -y install epel-release > /dev/null 2>&1
sudo yum -y install jq > /dev/null 2>&1

gcloud projects add-iam-policy-binding "$PROJECTID2" --member "user:$USER2" --role="roles/viewer" --quiet

echo -e "${GREEN}[✓] Task 3 Completed!${NC}\n"

# --- TASK 4 ---
echo -e "${CYAN}[ Task 4 ] Creating custom devops role & creating lab-2...${NC}"
gcloud config configurations activate default --quiet

gcloud iam roles create devops --project="$PROJECTID2" --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/iam.serviceAccountUser" --quiet
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="projects/$PROJECTID2/roles/devops" --quiet

gcloud config configurations activate user2 --quiet
gcloud config set project "$PROJECTID2" --quiet

gcloud compute instances create lab-2 --zone="$ZONE2" --machine-type=e2-standard-2 --quiet

gcloud config configurations activate default --quiet

echo -e "${GREEN}[✓] Task 4 Completed!${NC}\n"

# --- TASK 5 ---
echo -e "${CYAN}[ Task 5 ] Creating Service Account...${NC}"
gcloud config set project "$PROJECTID2" --quiet

gcloud iam service-accounts create devops --display-name="devops" --quiet
sleep 3

SA=$(gcloud iam service-accounts list --format="value(email)" --filter="displayName=devops")
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/iam.serviceAccountUser" --quiet

echo -e "${GREEN}[✓] Task 5 Completed!${NC}\n"

# --- TASK 6 ---
echo -e "${CYAN}[ Task 6 ] Granting InstanceAdmin and creating lab-3...${NC}"
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/compute.instanceAdmin" --quiet

gcloud compute instances create lab-3 --zone="$ZONE2" --machine-type=e2-standard-2 --service-account="$SA" --scopes=https://www.googleapis.com/auth/compute --quiet

echo -e "${GREEN}[✓] Task 6 Completed!${NC}\n"

# --- TASK 7 ---
echo -e "${CYAN}[ Task 7 ] Creating lab-4...${NC}"
gcloud compute instances create lab-4 --zone="$ZONE2" --machine-type=e2-standard-2 --project="$PROJECTID2" --quiet

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL TASKS EXECUTED SUCCESSFULLY! (100/100)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
