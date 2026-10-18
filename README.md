# SachLens — AI-Powered Document & Image Authenticity Checker

**See the signs. Examine the evidence. Make informed decisions.**

SachLens is an AI-assisted digital authenticity analysis application designed to help users inspect documents, photographs, certificates, invoices, social media screenshots, posters, advertisements, and other digital images for potential manipulation or AI generation.

In a world where AI-generated images and convincingly altered documents are becoming increasingly accessible, SachLens aims to make digital forensic checks easier to understand and more accessible to everyday users.

Rather than blindly labelling content as real or fake, SachLens focuses on identifying suspicious signals, explaining its findings, and helping users decide what to verify next.

---

## The Problem

AI-generated imagery, forged certificates, manipulated invoices, altered screenshots, and misleading promotional graphics can be difficult to distinguish from genuine content.

These files can be used for:
- Academic certificate and qualification fraud.
- Invoice, receipt, and financial document manipulation.
- Fake advertisements, promotional posters, and announcements.
- Altered social media screenshots and impersonation attempts.
- AI-generated photographs presented as authentic.
- Misleading visual evidence circulated online.

Most users do not have access to professional forensic software or the technical expertise needed to interpret digital image artifacts.

**SachLens aims to bridge this gap by turning technical inspection into understandable, evidence-based findings.**

## Our Solution

SachLens brings together image analysis, digital forensics, text inspection, and AI-assisted detection in one application.

Users provide an image or supported document, and the app analyzes available evidence to identify potential warning signs.

Depending on the file format and implemented capabilities, these checks may include:

- **AI-generated image analysis:** Evaluating whether an image exhibits characteristics associated with AI generation.
- **Image manipulation detection:** Examining error-level differences and other visual artifacts that may indicate localized editing.
- **Metadata inspection:** Reviewing available file information, timestamps, and editing software details.
- **Text extraction:** Reading visible document text through OCR when supported.
- **Document consistency checks:** Identifying arithmetic discrepancies, conflicting dates, inconsistent values, or unusual text formatting where applicable.
- **Visual evidence:** Highlighting areas that may deserve closer inspection.
- **Explainable results:** Presenting findings in understandable language rather than relying exclusively on a single score.

These checks provide supporting evidence, not definitive proof of authenticity or fraud.

## Key Features

### 1. AI-Generated Image Inspection
Analyze photographs and graphics for potential signs of synthetic image generation.

### 2. Document Forgery Inspection
Examine certificates, invoices, receipts, and other document images for possible editing artifacts and inconsistencies.

### 3. Error Level Analysis (ELA)
Re-save supported images at a fixed JPEG quality and compare pixel differences across regions. Unusual differences can be displayed as a heat map for further inspection.

ELA is a heuristic: ordinary compression, image texture, resizing, and repeated saving can also produce differences.

### 4. Image and Screenshot Analysis
Inspect social media screenshots, posters, advertisements, and promotional graphics for potential image manipulation and visual inconsistencies.

### 5. Explainable Findings
Help users understand why a file may warrant further verification, including suspicious regions or inconsistencies identified by the available analysis methods.

### 6. Privacy-Conscious Design
SachLens is designed with privacy in mind. On-device processing can reduce unnecessary exposure of sensitive documents. Actual data handling depends on the features and services enabled in the application.

### 7. Responsible Verdicts
The application is intended to communicate findings using cautious categories such as:

- **Likely Authentic:** No significant warning signs were detected by the available checks.
- **Suspicious:** One or more indicators warrant further investigation.
- **Cannot Determine:** Available evidence is insufficient for a reliable assessment.

A lack of detected warning signs does not guarantee that a file is genuine.

---

## How It Works

The intended analysis workflow consists of the following stages.

| Stage | Analysis | Purpose |
|---|---|---|
| 1 | File intake | Accept a supported image or document for inspection. |
| 2 | File fingerprinting | Identify files or duplicate content where fingerprint matching is implemented. |
| 3 | Metadata inspection | Examine available file properties and editing information. |
| 4 | Image forensics | Look for unusual compression patterns and localized differences. |
| 5 | Text extraction | Extract readable text when OCR is available. |
| 6 | Consistency analysis | Identify supported arithmetic, date, or formatting inconsistencies. |
| 7 | AI-image analysis | Evaluate potential indicators of synthetic image generation. |
| 8 | Evidence reporting | Present findings and suggest appropriate verification steps. |

The checks that run, their execution time, and their availability depend on the file type and the capabilities implemented in the current release.

## Example Use Cases

### Case 1: Certificate Inspection
A user uploads a certificate image. The app identifies an unusual region around a grade or date field. The result explains that the region warrants review rather than declaring the certificate forged.

### Case 2: Invoice Inspection
A user uploads an invoice. If text extraction and arithmetic validation are available, the app can flag a discrepancy between the listed items and the stated total.

### Case 3: AI-Generated Photograph
A user submits an image for AI-generation analysis. The app reports the available model's assessment as an indicator, not a conclusive determination.

### Case 4: Social Media Screenshot
A user inspects a screenshot containing a purported announcement. The app may identify visual inconsistencies or extract the visible text. It cannot independently prove that the post appeared on the original platform or that its claims are true.

---

## Privacy and Security

Sensitive documents can contain names, identification numbers, financial details, academic records, and other personal information.

SachLens follows a privacy-conscious development approach:

- Prefer on-device processing when technically feasible.
- Avoid unnecessary collection of personal information.
- Clearly disclose any optional external AI services or network processing.
- Explain data handling through an appropriate privacy policy.
- Avoid presenting an automated assessment as an authoritative fraud determination.

**Privacy claims must reflect the actual implementation.** If a feature uploads files or extracted content to an external service, that behavior must be disclosed accurately.

## Technology

SachLens is developed as a Flutter application using Dart.

The project includes image analysis based on Error Level Analysis and a modular signal-based assessment approach. Additional capabilities, such as OCR, metadata inspection, and AI-generated image classification, depend on the components integrated into the current build.

The architecture is intended to support explainable, modular analysis rather than depending entirely on one opaque verdict.

## Limitations

SachLens is an assistive inspection tool, not a certified forensic laboratory or an official document-verification authority.

- No single image analysis method can reliably detect every manipulation.
- Error Level Analysis can produce false positives and false negatives.
- Metadata may be missing, stripped, or deliberately altered.
- AI-generated image detectors can misclassify both synthetic and genuine images.
- OCR and document consistency checks depend on image quality and the supported rules.
- A genuine screenshot can contain false information.
- A suspicious-looking document is not necessarily fraudulent.
- Authenticity may require confirmation from the original issuer or publishing platform.

For important academic, financial, legal, or identity-related decisions, users should verify the source independently.

## Hackathon Project

SachLens explores how AI-assisted analysis and digital forensic techniques can help people critically examine digital content in an era of increasingly convincing synthetic media.

The project emphasizes three principles:

1. **Accessibility:** Make digital inspection understandable to non-experts.
2. **Explainability:** Show the evidence behind a warning whenever possible.
3. **Responsibility:** Communicate uncertainty and avoid unsupported claims.

## Getting Started

### Requirements
- Flutter SDK compatible with the project configuration.
- Dart SDK compatible with the project configuration.
- Android Studio or another supported Flutter development environment.
- An Android device or emulator.

### Run Locally

Clone the repository:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd sachlens
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Build an Android release APK:

```bash
flutter build apk --release
```

Build an Android App Bundle:

```bash
flutter build appbundle --release
```

The APK is typically generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The Android App Bundle is typically generated at:

```text
build/app/outputs/bundle/release/app.aab
```

Release signing and any required configuration must be completed before distributing a release build.

## Project Status

SachLens is being developed as an AI-assisted document and image authenticity analysis application.

The capabilities available to users are determined by the current implementation. Features described as intended, optional, or dependent on additional components should not be assumed to be fully operational until verified in the released build.

## Disclaimer

SachLens provides automated indicators for informational purposes only. It does not guarantee that a document or image is authentic, forged, AI-generated, or truthful. Results should not be used as the sole basis for accusations, legal conclusions, financial decisions, or other high-stakes judgments.

## Acknowledgment

Built to explore practical, responsible applications of AI and digital forensics for identifying potential manipulation in digital content.

**SachLens — Examine the evidence before trusting the image.**
