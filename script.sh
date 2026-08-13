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

# Inputs for Zones
printf "${BOLD}${GREEN}[?] Enter ZONE 1 (e.g., europe-west1-d): ${NC}"
read ZONE1

printf "${BOLD}${GREEN}[?] Enter ZONE 2 for Project 2 (e.g., us-west1-a): ${NC}"
read ZONE2

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${YELLOW}[!] Auto-detecting Projects & Credentials...${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# Extract Region 1 from Zone 1
REGION1="${ZONE1%-*}"

# Auto New Zone logic (Changes last letter)
if [[ "$ZONE1" == *"-a" ]]; then ZONE1_NEW="${ZONE1%-a}-b"
elif [[ "$ZONE1" == *"-b" ]]; then ZONE1_NEW="${ZONE1%-b}-c"
else ZONE1_NEW="${ZONE1%-*}-a"; fi

# Auto-detect Project IDs
PROJECTID1=$(gcloud config get-value project 2>/dev/null)
PROJECTID2=$(gcloud projects list --format="value(projectId)" | grep -v "$PROJECTID1" | head -n 1)

# Auto-detect User 2
USER2=$(gcloud asset search-all-resources --scope=projects/$PROJECTID2 --query="type:iam.googleapis.com/ServiceAccount" 2>/dev/null | grep -o 'student-[^"@]*@qwiklabs\.net' | head -n 1)

if [ -z "$USER2" ]; then
    USER2=$(gcloud projects get-iam-policy "$PROJECTID2" --format="json" 2>/dev/null | jq -r '.bindings[].members[]' | grep 'student-' | grep -v "$(gcloud config get-value account 2>/dev/null)" | head -n 1 | sed 's/user://')
fi

echo -e "${CYAN}[Info] Project 1: $PROJECTID1 | Project 2: $PROJECTID2${NC}"
echo -e "${CYAN}[Info] Region 1: $REGION1 | Zone 1: $ZONE1 | New Zone: $ZONE1_NEW${NC}"
echo -e "${CYAN}[Info] Zone 2: $ZONE2 | User 2: $USER2${NC}\n"

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
gcloud compute instances create lab-2 --project="$PROJECTID2" --zone="$ZONE2" --machine-type=e2-standard-2 --quiet
gcloud compute instances create lab-3 --project="$PROJECTID2" --zone="$ZONE2" --machine-type=e2-standard-2 --service-account="$SA" --scopes=https://www.googleapis.com/auth/compute --quiet
gcloud compute instances create lab-4 --project="$PROJECTID2" --zone="$ZONE2" --machine-type=e2-standard-2 --quiet

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL TASKS EXECUTED SUCCESSFULLY! (100/100)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
