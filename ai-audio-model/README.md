# Mahd AI Audio Model

This folder contains the audio AI development work for **Mahd**, an intelligent infant monitoring system. The AI work focuses on infant cry detection and cry-cause classification.

## Folder Structure

```text
ai-audio-model/
├── 1_data_preprocessing/
├── 2_feature_extraction/
├── 3_model_inference/
├── Mahd_cry_detection_model.ipynb
└── README.md
```

- **`1_data_preprocessing/`** — Data preprocessing resources and scripts.
- **`2_feature_extraction/`** — Feature extraction resources and experiments.
- **`3_model_inference/`** — Model inference and evaluation work.
- **`Mahd_cry_detection_model.ipynb`** — Cry-detection development notebook.

## Google Drive — AI Files

**Shared Google Drive folder:** `[PASTE_GOOGLE_DRIVE_LINK_HERE]`

Replace the placeholder above with the Google Drive folder link when it is available. This folder can be used to share large model files and other AI resources that are not stored directly in GitHub.

## Integration with the Mobile Application

The Flutter app is located in [`../mobile-client/`](../mobile-client/).

The mobile app currently supports microphone audio capture and an **experimental ONNX cry-cause classification test**. This debug test is not a completed cry-detection pipeline. Final integration will need to detect crying before classifying its cause and recording a confirmed event.

## Development Status

AI model development and end-to-end integration are ongoing. Final model specifications, evaluation results, and deployment instructions should be added once confirmed by the AI team.
