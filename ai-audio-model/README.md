# Mahd — AI Audio Model

All AI datasets, preprocessing scripts, feature extraction outputs, training experiments, and trained models are maintained in a centralized **Google Drive** workspace directly mounted to **Google Colab** for seamless access and automatic saving during experimentation:

🔗 **Google Drive — AI Workspace:** [Access Mahd AI Shared Folder](https://drive.google.com/drive/folders/19f9nYoCtNWN_Lze9jE7TZLkA0h5V0Hem?usp=drive_link)

## Two-Stage AI Architecture

Mahd's audio intelligence follows a **two-stage classification architecture**:

1. **Stage 1 — Cry Detection (Binary Classification):** Distinguishes infant crying (`Cry`) from household background noise and non-cry human sounds (`Non-Cry`).
2. **Stage 2 — Cry Cause Classification (Multi-Class Classification):** Triggered only when a cry is detected, classifying the cry into one of five target causes: **Hunger**, **Pain**, **Tired**, **Discomfort**, or **Burping**.
