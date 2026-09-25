# Mahd (مهد) - Edge-AI Infant Monitoring System

## Introduction (Goal)
Mahd is an intelligent, Edge-to-Cloud infant monitoring system designed to ensure data privacy and provide real-time alerts for caregivers. The primary goal of the system is to leverage local Edge AI for acoustic classification and a scalable Cloud infrastructure for event routing, ensuring rapid and secure responses to infant distress.

## Technologies Used
- **Artificial Intelligence:** DistilHuBERT (Audio Classification)
- **Edge Computing:** Raspberry Pi 4, Python
- **Mobile Development:** Flutter, Dart
- **Cloud & Backend:** Firebase

## System Architecture
The Mahd system utilizes a hybrid Edge-to-Cloud IoT architecture. This design seamlessly integrates local hardware with cloud services: edge computing processes audio immediately inside the infant's room, and subsequently, the cloud platform handles real-time event routing and scalable data management. 

![System Architecture](assets/معمارية3.png)

## Brief Launch Instructions
*Note: Full launch instructions will be provided as development progresses in the upcoming sprints.*
1. **AI Model:** Navigate to the `ai-audio-model` directory to access the audio preprocessing and inference scripts.
2. **Edge Hardware:** Connect the ReSpeaker 2-Mics Pi HAT to the Raspberry Pi and run the upcoming Python scripts in the `edge-raspberrypi` directory.
3. **Mobile App:** Run `flutter pub get` and `flutter run` inside the `mobile-client` directory once the UI development commences.

## Project Tracking
All project tasks, user stories, and sprint backlogs are managed via Jira.
- [View Mahd Jira Workspace](ضعي_رابط_جيرا_هنا)
