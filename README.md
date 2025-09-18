# SymptomSaga – Heart Palpitation Tracking App

**SymptomSaga** is an iOS app built in **Swift** using the **[Spezi framework](https://github.com/StanfordSpezi/Spezi)**.  
The app helps patients capture and contextualize **episodic heart palpitations** by combining:  
- **ECG and health data** from wearables (via Apple HealthKit)  
- **Symptom reporting** through a guided questionnaire  
- **Secure, shareable health reports** for clinicians  

This project was developed as part of the course [TRA460: Digital Health Implementation](https://www.chalmers.se/en/education/your-studies/course-selection-and-registration/select-courses/choose-a-tracks-course/digital-health-implementation/) at Chalmers University of Technology.

## Features

- **Health Data Integration**  
  - Fetches ECG, heart rate, resting heart rate, and heart rate variability from **Apple HealthKit**  
  - Supports real-time visualization of wearable data  

- **Symptom Tracking**  
  - Patients log palpitations, severity, duration, and potential triggers  
  - Data is timestamped and linked with corresponding health metrics  

- **FHIR Backend Support**  
  - All health data and symptom logs are converted into **FHIR resources**  
  - Data can be pushed to a **FHIR server** (HAPI FHIR or Meld Sandbox)  

- **Shareable Reports**  
  - Patients can generate a secure, time-limited web link to share compiled health reports  
  - Reports include vitals, ECG traces, and symptom insights  

- **User-Friendly Interface**  
  - Simple onboarding process with consent handling  
  - Dashboard showing most recent vitals and past logs  
  - Settings for digital prescriptions via external apps (e.g., Fibricheck integration)  

---


## Tech Stack

- **iOS App**: Swift + [Spezi Framework](https://github.com/StanfordSpezi/Spezi)  
- **Health Data**: Apple HealthKit  
- **Backend**: HAPI FHIR Server / Meld Sandbox (via Docker)  
- **Web Report (separate repo)**: [HeartPalp-Dashboard](https://github.com/tyrawallen/HeartPalp-Dashboard) (Next.js)  

---

### Setup
1. Clone the repository:  
   ```bash
   git clone https://github.com/dpediaditis/heart_palpitation.git
   cd heart_palpitation

---

## Screenshots
### Dashboard
<p align="center">
  <img src="docs/images/Dashboard.png" alt="Image 1" width="200"/>
  <img src="docs/images/Dashboard2.png" alt="Image 2" width="200"/>
  <img src="path/to/HeartDetails.png" alt="Image 3" width="200"/>
</p>

*Main app screen showing ECG recording and vitals from Apple Health.* 

