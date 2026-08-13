# ☁️ Google Cloud Skills Boost - Lab Solution & Step-by-Step Commands

Welcome to the **Google Cloud Skills Boost** solution guide. This repository contains modular, step-by-step scripts designed to help learners and cloud enthusiasts understand Google Cloud Platform (GCP) configurations, IAM roles, and `gcloud` CLI commands efficiently.

---

## ⚠️ IMPORTANT DISCLAIMER & WARNING

> 🛑 **READ BEFORE EXECUTING ANY COMMANDS**

1. **Educational Purpose Only:** This repository and its contents are created purely for educational, learning, and reference purposes.
2. **Understand First, Automate Later:** This is a **semi-manual / step-by-step guide**. We strongly recommend executing each step individually in your **VM SSH session** to understand the underlying concepts of IAM roles, policy bindings, `gcloud` configurations, and service accounts.
3. **Guideline Compliance:** Using scripts to bypass learning without understanding concepts may violate Google Cloud Skills Boost / Qwiklabs Terms of Service. Use these commands responsibly to verify your steps or speed up review after grasping the core concepts.

---

### **=== TASK 1 (RUN INSIDE VM SSH) ===**

```bash
read -p "Enter REGION 1 (e.g., europe-west1): " REGION1
read -p "Enter ZONE 1 (e.g., europe-west1-d): " ZONE1


if [[ "$ZONE1" == *"-a" ]]; then
    ZONE1_NEW="${ZONE1%-a}-b"
else
    ZONE1_NEW="${ZONE1%-*}-a"
fi

echo "Auto-detected NEW ZONE: $ZONE1_NEW"

gcloud config set compute/region "$REGION1"
gcloud config set compute/zone "$ZONE1"


gcloud compute instances create lab-1 --zone="$ZONE1" --machine-type=e2-standard-2 --quiet

gcloud config set compute/zone "$ZONE1_NEW"

echo -e "\n[✓] Task 1 Completed! Click 'Check my progress' on Task 1."
```


### **=== TASK 2 (RUN INSIDE VM SSH) ===**

```bash

read -p "Enter Username 2 (Right panel se exact Username 2 copy kar): " USER2
read -p "Enter Project ID 1 (Right panel se exact Project ID 1 copy kar): " PROJECTID1

gcloud config configurations create user2 --quiet 2>/dev/null || true
gcloud config set account "$USER2" --configuration=user2
gcloud config set project "$PROJECTID1" --configuration=user2

```

### **=== TASK 3 (RUN INSIDE VM SSH) ===**

```bash

# 1. Login Trigger
gcloud auth login --no-launch-browser
```

```bash

read -p "Enter USERNAME 2: " USER2
read -p "Enter PROJECT ID 2: " PROJECTID2

export PROJECTID2="$PROJECTID2"
export USERID2="$USER2"

echo "export PROJECTID2=\"$PROJECTID2\"" >> ~/.bashrc
echo "export USERID2=\"$USER2\"" >> ~/.bashrc

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/viewer"

echo -e "\n[✓] Task 3 Done!"

```

### **=== TASK 4 (RUN INSIDE VM SSH) ===**

```bash

# === COMPLETE TASK 4 EXECUTION BLOCK ===

read -p "Enter USERNAME 1 (Admin ID): " USER1
read -p "Enter USERNAME 2: " USER2
read -p "Enter PROJECT ID 2: " PROJECTID2
read -p "Enter ZONE 2 for Project 2 (e.g., europe-west4-a): " ZONE2

gcloud config configurations activate default --quiet
gcloud config set account "$USER1" --quiet

gcloud iam roles create devops --project="$PROJECTID2" --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="roles/iam.serviceAccountUser" --quiet
gcloud projects add-iam-policy-binding "$PROJECTID2" --member="user:$USER2" --role="projects/$PROJECTID2/roles/devops" --quiet

gcloud compute instances create lab-2 --project="$PROJECTID2" --zone="$ZONE2" --machine-type=e2-standard-2 --quiet

echo -e "\n[✓] Task 4 Done! All checkpoints ready."

```

### **=== TASK 5,6,7 (RUN INSIDE VM SSH) ===**

```bash

# === TASK 5 & 6 EXECUTION ===

read -p "Enter PROJECT ID 2: " PROJECTID2
read -p "Enter ZONE 2 for Project 2 (e.g., europe-west4-a): " ZONE2

gcloud config configurations activate default --quiet
gcloud config set project "$PROJECTID2" --quiet

gcloud iam service-accounts create devops --display-name="devops" --quiet

sleep 3

SA=$(gcloud iam service-accounts list --format="value(email)" --filter="displayName=devops")
echo "Service Account Email: $SA"

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/iam.serviceAccountUser" --quiet

gcloud projects add-iam-policy-binding "$PROJECTID2" --member="serviceAccount:$SA" --role="roles/compute.instanceAdmin" --quiet

gcloud compute instances create lab-3 --zone="$ZONE2" --machine-type=e2-standard-2 --service-account="$SA" --scopes=https://www.googleapis.com/auth/compute --quiet

echo -e "\n[✓] Task 5 & Task 6 Completed! Click 'Check my progress' on both tasks."

```
