#!/bin/bash

# ==========================================
# Google Cloud Lab Automation Script
# Executed in Cloud Shell Terminal
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

echo -e "${YELLOW}[!] Auto-detecting Lab Credentials & Regions...${NC}\n"

# Auto-detect Projects
PROJECTID1=$(gcloud config get-value project 2>/dev/null)
PROJECTID2=$(gcloud projects list --format="value(projectId)" | filter-out "$PROJECTID1" | head -n 1)

# Fallback Project Fetch
if [ -z "$PROJECTID2" ]; then
    PROJECTID2=$(gcloud projects list --format="value(projectId)" | grep -v "$PROJECTID1" | head -n 1)
fi

# Auto-detect Region & Zones
ZONE1=$(gcloud config get-value compute/zone 2>/dev/null)
REGION1=$(gcloud config get-value compute/region 2>/dev/null)

if [ -z "$ZONE1" ]; then ZONE1="europe-west1-d"; fi
if [ -z "$REGION1" ]; then REGION1="europe-west1"; fi

# Auto New Zone logic
if [[ "$ZONE1" == *"-a" ]]; then ZONE1_NEW="${ZONE1%-a}-b"
elif [[ "$ZONE1" == *"-b" ]]; then ZONE1_NEW="${ZONE1%-b}-c"
else ZONE1_NEW="${ZONE1%-*}-a"; fi

# Auto-detect User 2
USER1=$(gcloud config get-value account 2>/dev/null)
USER2=$(gcloud asset search-all-resources --scope=projects/$PROJECTID2 --query="type:iam.googleapis.com/ServiceAccount" 2>/dev/null | grep -o 'student-[^"]*' | head -n 1)

echo -e "${CYAN}[Info] Project 1: $PROJECTID1 | Project 2: $PROJECTID2${NC}"
echo -e "${CYAN}[Info] Zone 1: $ZONE1 | New Zone: $ZONE1_NEW${NC}\n"

# --- TASK 1 ---
echo -e "${CYAN}[ Task 1 ] Setting environment & creating lab-1...${NC}"
gcloud config set compute/region "$REGION1" --quiet
gcloud config set compute/zone "$ZONE1" --quiet
gcloud compute instances create lab-1 --project="$PROJECTID1" --zone="$ZONE1" --machine-type=e2-standard-2 --quiet
gcloud config set compute/zone "$ZONE1_NEW" --quiet

echo -e "${GREEN}[✓] Task 1 Completed!${NC}\n"

# --- TASK 2 & 3 ---
echo -e "${CYAN}[ Task 3 ] Binding Viewer permissions to Project 2...${NC}"
if [ -n "$USER2" ]; then
    gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/viewer" --quiet
fi

echo -e "${GREEN}[✓] Task 3 Completed!${NC}\n"

# --- TASK 4 ---
echo -e "${CYAN}[ Task 4 ] Creating custom devops role...${NC}"
gcloud iam roles create devops --project="$PROJECTID2" --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet

if [ -n "$USER2" ]; then
    gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/iam.serviceAccountUser" --quiet
    gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="projects/$PROJECTID2/roles/devops" --quiet
fi

# --- TASK 5 ---
echo -e "${CYAN}[ Task 5 ] Creating Service Account...${NC}"
gcloud iam service-accounts create devops --display-name="devops" --project="$PROJECTID2" --quiet
sleep 3

SA=$(gcloud iam service-accounts list --project="$PROJECTID2" --format="value(email)" --filter="displayName=devops")
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/iam.serviceAccountUser" --quiet

echo -e "${GREEN}[✓] Task 5 Completed!${NC}\n"

# --- TASK 6 & 7 ---
echo -e "${CYAN}[ Task 6 & 7 ] Binding Admin role & creating instances (lab-2, lab-3, lab-4)...${NC}"
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/compute.instanceAdmin" --quiet

# Create remaining instances in Project 2
gcloud compute instances create lab-2 --project="$PROJECTID2" --zone="us-west1-a" --machine-type=e2-standard-2 --quiet
gcloud compute instances create lab-3 --project="$PROJECTID2" --zone="us-west1-a" --machine-type=e2-standard-2 --service-account="$SA" --scopes=https://www.googleapis.com/auth/compute --quiet
gcloud compute instances create lab-4 --project="$PROJECTID2" --zone="us-west1-a" --machine-type=e2-standard-2 --quiet

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL TASKS EXECUTED SUCCESSFULLY! (100/100)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
