# SachLens: Fake Document and AI Image Checker

Check before you trust or pay. SachLens reads posters, letters, offers and images on your phone, marks the red flags, and explains every finding. It is free, needs no server and no paid API, and is honest about what it cannot see.

* Google Play: submitted, currently in review

## Problem

Fake admission letters, job posters, visa offers, investment schemes and altered invoices cost people their savings every day. Victims usually cannot check a document before they pay. Existing tools either ask you to upload private documents to a server, or give one unexplained score that is easy to misread.

## Solution

SachLens is an Android app that checks documents, images and wall posters entirely on the phone. It combines file forensics, text reading and explainable rules, then shows a clear result:

* red numbered boxes on a poster, each with the reason and how to verify it
* a three level verdict for documents: Suspicious, Cannot determine, or No warning signs found
* a risk meter and the exact evidence behind it
* local help for reporting and checking, chosen from the phone region

## Features

* Check a poster: photograph a poster and see the red flags marked on it
* Document check: letters, offers, invoices and images (JPEG, PNG, PDF)
* Dates and timeline check, for example a payment confirmed after the document date
* Totals check, for example subtotal, tax and fees against the stated total
* Scam wording in English, Roman Urdu, Spanish, French and Portuguese, with negation handling ("we never ask for fees" is not a flag)
* QR code and link checks, read as text and never opened
* File details: editing software, AI tool labels, camera data
* Edit heat map (error level analysis) and a side by side Compare with original mode
* Batch scan for up to 20 files, PDF report, and a Privacy Cleaner for photos
* Reading quality check: the app says so when text cannot be read, and never calls it safe

## How it works

1. The file is read into memory. Temporary files are deleted right after use.
2. File details are analysed: EXIF data, PDF creator fields, AI tool markers and Content Credentials labels.
3. For JPEG images, error level analysis marks areas that react differently when the image is re saved.
4. On device text recognition reads the text with its position. Pieces of text on the same row are joined, so a label and its value are read together.
5. Rules cross check dates, totals, scores, payment wording, institution domains and QR destinations.
6. Findings are combined into one explainable result. Every finding has a reason in plain words.
7. The result tells the user how to confirm the document with the issuer.

## AI methodology

SachLens uses applied machine learning and explainable analysis, not a black box.

* Machine learning for perception: Google ML Kit text recognition and barcode scanning, running on the device.
* Computer vision forensics: error level analysis and image differencing, written in Dart.
* Rule based language analysis: multilingual pattern sets, negation handling, and row reconstruction from the text positions given by the recognizer.
* Evidence scoring: each finding has a suspicion value and a weight. Findings are combined so that one strong finding, or several medium findings, lead to a warning. The good verdict needs positive evidence, never just the absence of problems.
* Explainability and honesty: every verdict shows its reasons, a rough risk guide, and the limits of the method.

There is no generative AI model, no large language model and no cloud AI service in the app. We chose this on purpose, to keep user files on the phone. SachLens does not claim to detect AI generated pictures from their pixels. It reports labels and traces that AI tools leave in files, and says when none are found.

## Models and APIs used

| Component | Purpose | Runs where | Cost |
|---|---|---|---|
| Google ML Kit Text Recognition (Latin script) | Reads text and positions | On the device | Free |
| Google ML Kit Barcode Scanning | Reads QR codes | On the device | Free |
| Our own Dart code | Forensics, rules, scoring | On the device | Free |

No paid API, no cloud API, no API keys.

## Tech stack

Flutter and Dart for Android. Packages: google_mlkit_text_recognition, google_mlkit_barcode_scanning, image, exif, pdf, pdfx, image_picker, file_picker, share_plus, path_provider, crypto. No backend, no database, no login.

## Privacy

Files are processed on the device. The app has no account and no server. Reports and cleaned photos leave the phone only when the user chooses to share them.

## Setup

Requirements: Flutter 3 or newer, an Android phone or emulator.

```bash
git clone https://github.com/YOUR_USERNAME/sachlens.git
cd sachlens
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

Build a release APK:

```bash
flutter build apk --release
```

Note: if you see a build error that mentions the image and archive packages, keep the dependency_overrides section in pubspec.yaml, which pins the image package to a compatible version.

## Testing

The repository includes automated test cases for the poster rules and the document rules, covering scam posters in several languages, honest posters that must not be accused, warning posters, and text in unsupported scripts. The samples folder holds fictional files for trying the app by hand.


## Limitations

* It finds warning signs. It cannot prove that a document is genuine.
* It cannot verify signatures, seals, paper or a student record.
* A careful forgery with no contradictions can pass.
* Urdu and Arabic script cannot be read yet. The app says so and does not guess.
* Text reading can misread digits, so mismatch messages say to check by hand.
* Phrases in languages other than English should be reviewed by native speakers.

## Roadmap

More scripts, a larger and reviewed list of institutions, a test set with published accuracy, and an optional opt in deeper check.

## Team and contributions

* Ayesha Arshad (team lead, solo): idea, product design, Flutter development, rule design, testing, documentation and release.

The project was built newly for the NYLP AI Hackathon 2026. An AI assistant (Claude by Anthropic) was used for coding help and review. All design decisions, integration, testing and submission were done by the team lead.

## License

MIT
