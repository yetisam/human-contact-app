# PROJECT: HUMAN CONTACT

## APP OVERVIEW

**Name:** Human Contact  
**Tagline:** “The place to meet real humans”  
**Purpose:** Safe initial meeting platform that facilitates real human connections.

---

## CORE CONCEPT

- Platform for initial introductions between verified people.  
- Focus on person-person contact via email or phone, then it is up to the involved users if they want to meet.  
- After contact via the app, users can exchange contact info (email/phone).  
- App serves as a bridge, not a permanent communication platform.  
- Combats loneliness and isolation through genuine human connection.

---

## PLATFORM

- Mobile-first approach  
- Native iOS app (Swift / SwiftUI)  
- Native Android app (Kotlin / Jetpack Compose)  
- Responsive web companion site

---

## DESIGN SPECIFICATIONS

**Theme:** Dark with blue accents  

- **Background:** Dark gradient (`#0a0e27 → #1a1d3a`)  
- **Accent boxes:** Blue gradient (`#1e40af → #1e3a8a`)  
- **Borders:** `rgba(59, 130, 246, 0.3–0.4)`  
- **Text:** White with varying opacity  

**Logo:** Two gender-neutral figures shaking hands (basic concept to be refined)

- Left figure: Blue tones (`#3b82f6`, `#2563eb`)  
- Right figure: Orange tones (`#f59e0b`, `#fb923c`)  
- Style: Simple, modern, inclusive

---

## CORE FEATURES

### Safety & Verification

- ✅ Government ID verification (required)  
- ✅ Optional background check integration  
- ✅ Check-in safety system during meetups  
- ✅ Emergency contact sharing  
- ✅ Report & block functionality  
- ✅ Community moderation team  
- ✅ **No in-app selfies or photo verification.** Users may optionally exchange photos **after** first contact, at their own discretion.

### User Experience

- Interest-based matching algorithm  
- Proximity-based suggestions  
- Profile verification badges  
- Simple process: **Connect→ Talk→ Meet→ Grow**

### Contact Exchange

- Email/phone sharing after verified first contact  
- User controls when to share contact info  
- Encourages organic friendship development outside the app

---

## PRIVACY & MEDIA

- **No selfie capture:** the app does not capture, store, or process user selfies or biometric templates.  
- **Optional photo exchange only:** any photos are exchanged **user-to-user**, **after first contact**, and are **not required** for onboarding or verification.  
- **ID verification uses documents only** (via a third-party IDV provider); **no face maps, video selfies, or liveness biometrics** are stored by Human Contact.

---

## WHAT WE'RE NOT

- ✗ Not a messaging app  
- ✗ Not social media  
- ✗ Not a dating platform  
- ✗ Not designed for long-term in-app engagement

---

## WHAT WE ARE

- ✓ Safe introduction platform  
- ✓ Human contacting facilitator  
- ✓ Contact exchange enabler  
- ✓ Launchpad to real friendships  

---

## TECHNICAL REQUIREMENTS

- User authentication & profile management  
- ID verification API integration  
- Geolocation services  
- Matching algorithm (interest-based + proximity)  
- Meeting scheduling system  
- Safety check-in system  
- Push notifications  
- Secure contact information exchange  
- Reporting & moderation tools  

---

## LEGAL CONSIDERATIONS

- Privacy Policy (GDPR, CCPA compliance)  
- Terms of Service (liability limitations)  
- ID verification regulations  
- Background check compliance  
- User safety disclaimers  
- Data storage & encryption requirements  

---

## TARGET USERS

- People experiencing loneliness or isolation  
- Those seeking genuine friendships  
- Individuals new to an area  
- Anyone wanting human to human connection  

---

## BUSINESS MODEL OPTIONS

- Freemium (basic free, premium features)  
- Subscription model  
- Verification fee  
- Background check add-on fee  

---

## COMPETITIVE ANALYSIS & PARTNER OPPORTUNITIES

| **App / Platform**        | **Market Position**                          | **Core Features**                                                          | **Weaknesses / Gaps (vs. Human Contact)**                                                 | **Human Contact Advantage / Differentiator**                                                  | **Potential Partner APIs / Integrations**                                                    |
| ------------------------- | -------------------------------------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Patook**                | Friendship app (non-dating)                  | Interest-based matching, platonic chat, reputation score                   | Still chat/social model; no ID verification or safety check-in; allows anonymous profiles | Verified identities only; no in-app messaging; contact exchange after first verified contact  | – Yoti / Persona (ID verification)<br>– Checkr (optional background checks)                  |
| **Bumble (Friends Mode)** | Mainstream friend & dating hybrid            | In-app chat, ID verification (rolling out), “Share My Date” safety feature | Still dating-oriented; engagement-driven; relies on selfies; not bridge-based             | Strict “connect → talk → meet → grow” path; no selfies; safety-first onboarding               | – ConnectID (AU market ID verification)<br>– Google Maps / Apple Maps for meetup geolocation |
| **Lunchclub**             | AI-powered professional meeting matcher      | Interest/professional-based AI matching; meeting scheduler                 | Business networking focus only; no ID or safety systems                                   | Wider human connection purpose (social/friendship, not work); verified identity & safety flow | – Google Calendar API (meeting scheduler)<br>– Persona (IDV)                                 |
| **Meetup**                | Group activities & local events              | Group creation, event listings, community moderation                       | Group-centric, not 1:1 introductions; no verification                                     | One-on-one verified contact with safety & emergency features                                  | – Google Places API (venue suggestions)<br>– Twilio / Nexmo (SMS check-ins)                  |
| **Yubo**                  | Social livestream platform for meeting peers | Video chat, community rooms, optional ID verification                      | Youth/Gen-Z oriented; heavy video/social layer; minimal real-world safety                 | Privacy-forward (no photos required), adult focus, genuine offline meetups                    | – Yoti (for age + ID verification)<br>– AWS Cognito / Firebase Auth (secure auth)            |
| **Friender**              | “Meet friends through activities” app        | Shared interests, direct chat, in-app messaging                            | No verification; security concerns; fake accounts                                         | Verified-only platform; no messaging clutter                                                  | – Persona / Onfido for IDV<br>– Twilio for safety notifications                              |
| **Vibe IRL**              | Real-life social discovery app               | Mood-based meet suggestions, proximity search                              | Encourages open chat before meeting; minimal safety; still social network feel            | Focused on verified contact exchange; eliminates social feed noise                            | – Mapbox / Google Maps APIs<br>– Persona for identity verification                           |
| **BeFriend / 7 Cups**     | Mental health & loneliness support           | Chat-based empathy matching, online connection                             | Purely online; no real-world meeting flow; anonymous                                      | Safe in-person connection route for loneliness without “therapy” positioning                  | – Twilio (voice verification)<br>– ConnectID or Yoti for ID checks                           |
| **Nefity**                | Privacy-conscious social meetup platform     | Verified users; local activities; minimal data collection                  | Not fully implemented; unclear safety stack; no “bridge” design                           | Explicit “bridge app” model; no data mining; verified contact exchange                        | – Persona (KYC/AML verification)<br>– Plaid (optional payment for premium)                   |

---

### Market Opportunity Snapshot

| **Market Segment**                                                | **Current Gap**                                                                             | **Opportunity for Human Contact**                                                                      |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Verified social connection apps**                               | Most apps use weak selfie or email verification only                                        | Offer a trust-first ecosystem (document-based IDV, optional background check)                          |
| **Friendship / Loneliness relief apps**                           | Dominated by chat-based apps, little focus on *meeting safely*                              | First platform purpose-built for *safe in-person friendship formation*                                 |
| **Privacy-conscious users**                                       | Data-hungry social networks dominate; few options for photo-free, privacy-first connections | “No selfies / no data mining / no chat” is a rare and appealing differentiator                         |
| **Safety-driven meetups**                                         | Dating apps lead on SOS/check-in, but not non-romantic contexts                             | Implement integrated check-in + emergency handoff systems for any human meeting                        |
| **Adults 18+ new to an area / post-pandemic social reconnection** | Currently underserved outside dating or hobby groups                                        | “Verified meet-first” model fits perfectly with re-socialization trends and loneliness crisis response |

---

### Key Differentiators Summary

| **Category**     | **Human Contact**                                      | **Industry Norm**                                 |
| ---------------- | ------------------------------------------------------ | ------------------------------------------------- |
| **Verification** | Government ID via third-party (Yoti/Persona/ConnectID) | Optional selfie or email verification             |
| **Safety**       | Built-in check-in system + emergency contact relay     | Only a few dating apps offer partial SOS features |
| **Privacy**      | No selfie capture, no feed, minimal data retention     | High data collection & photo requirements         |
| **Meeting Flow** | Connect → Talk (minimal) → Meet → Exchange contact     | Chat-heavy, often never leads to real meetings    |
| **Purpose**      | Bridge to genuine friendship                           | Engagement-driven social apps                     |
| **Monetization** | Verification + premium safety tools (freemium)         | Ad-driven, engagement-based                       |
| **User Focus**   | People seeking human connection & loneliness relief    | Dating, networking, or entertainment              |

---

### Recommended Partner APIs (for MVP / Pilot)

| **Function**                                              | **Suggested Partner**                       | **Why**                                                               |
| --------------------------------------------------------- | ------------------------------------------- | --------------------------------------------------------------------- |
| **ID Verification**                                       | **Yoti**                                    | UK/AU-compliant, document-based (no selfies), privacy-focused         |
|                                                           | **Persona**                                 | Modular KYC/AML verification; handles passports, licences, watchlists |
|                                                           | **ConnectID (Australia)**                   | Bank-backed national ID assurance — ideal for AU compliance           |
| **Background Checks**                                     | **Checkr**                                  | API-ready background screening; scalable for global use               |
| **Safety Check-In / SOS**                                 | **Noonlight API** *(or Twilio integration)* | Proven “check-in & emergency trigger” system                          |
| **Geolocation / Venues**                                  | **Google Maps API** / **Mapbox**            | Place suggestions for public meeting spots                            |
| **Authentication & Security** | **Firebase Auth / AWS Cognito**             | Managed user auth, MFA, and encryption                                |
| **Payment Gateway (Premium)**                             | **Stripe / Plaid**                          | Simple setup for subscription or verification fee models              |

---

### Strategic Summary

- **Position:** First *non-dating, verified human-connection bridge app* for in-person friendship and loneliness reduction.  
- **Gap filled:** Real-world introductions under full safety and verification layers — *without selfies, social feeds, or chat clutter.*  
- **Advantage:** Combines trust (IDV), safety (check-ins), and simplicity (bridge-only UX).  
- **Primary market:** Adults 25–55 seeking new connections, safety-first meeting culture, and privacy-by-design social tech.  
- **Scalable region:** Start with **Australia** (ConnectID partner advantage, loneliness initiatives), then expand to **North America** and **UK** (Yoti / Persona compliant).

---

## NEXT DEVELOPMENT STEPS

1. Create detailed user flow diagrams  
2. Write comprehensive feature specifications  
3. Choose development framework  
4. Design database schema  
5. Create PRD (Product Requirements Document)  
6. Partner with ID verification service  
7. Build MVP with core features  
8. Conduct safety-focused beta testing  
9. Iterate based on user feedback  
10. Plan gradual market launch
