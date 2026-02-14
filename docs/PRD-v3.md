# PRD: Human Contact - Hybrid MVP

## 1. Introduction / Overview

**Project:** Human Contact  
**Version:** 3.0 (Hybrid Model)  
**Tagline:** "The place to meet real humans."  
**Target Launch:** Mid-January 2026  
**Platform:** iOS (MVP), Android & Web (future phases)

**Purpose:** Human Contact is a verified contact-exchange platform that enables safe, trust-based connections between real people. Unlike social networks or dating apps, Human Contact serves as a bridge—facilitating verified introductions with optional in-person meetings, then encouraging relationships to develop offline.

### Problem

Digital isolation and loneliness are widespread, yet existing platforms prioritize engagement over authentic connection. People want to meet real humans but lack safe, verified ways to exchange contact information with strangers—whether discovered through the app or met in person.

### Solution

Human Contact combines algorithmic matching with direct connection options, enabling users to:

1. Discover verified people nearby with shared interests, OR
2. Connect directly with someone specific via a one-time link
3. Chat briefly to coordinate
4. Exchange contact information after mutual consent
5. Optionally schedule in-person meetings with safety features

### Goal

Launch a functional iOS MVP by mid-January 2026 that achieves:

- 100 verified users in first 3 months
- Completed contact exchanges as primary success metric
- Fast time-to-exchange (minimize friction)
- <2% inappropriate behavior report rate
- Foundation for freemium business model

---

## 2. Goals

### Product Goals

1. **Enable verified contact exchange** between real humans with minimal friction
2. **Provide multiple connection pathways** - algorithmic discovery AND direct linking
3. **Maintain safety-first approach** through verification and optional meeting features
4. **Minimize time to value** - users should complete first contact exchange within 7 days
5. **Build trust through transparency** - clear data practices, user control, privacy-by-design

### User Goals

**As a new user, I want to:**

- Verify my identity quickly and understand why it matters
- Find nearby people with shared interests through smart matching
- Choose whether I prefer to meet people in person first or exchange contact directly
- Control exactly what contact information I share (email, phone, or both)
- Feel safe and in control throughout the entire process

**As an existing user, I want to:**

- Request contact information after brief interaction
- Optionally schedule safe in-person meetings
- Report or block users who behave inappropriately
- Connect with specific people I met elsewhere via a direct link

### Non-Goals (Out of Scope for MVP)

- Long-term messaging platform (limited chat only)
- Social media features (feeds, posts, likes, comments)
- Dating or romantic matching algorithms
- Group meetups or events
- In-app media sharing (photos, videos, voice messages beyond profile)
- Android and web platforms (phase 2)
- Advanced matching AI/ML (basic algorithm only)
- Real-time location tracking
- Payment processing beyond basic subscription (full freemium later)

---

## 3. User Stories

### Discovery & Matching

- **US-01:** As a user seeking new connections, I want to browse verified people nearby with shared interests so I can find compatible potential friends.
- **US-02:** As a user, I want to filter matches by age range, interests, and distance so I see only relevant connections.
- **US-03:** As a user who met someone in person, I want to share a one-time connection link so we can verify and exchange contact safely through the app.

### Profile & Verification

- **US-04:** As a new user, I want to verify my identity with government ID so others trust I'm real.
- **US-05:** As a user, I want to confirm my email and phone number so the app can verify my contact details.
- **US-06:** As a safety-conscious user, I want to optionally complete a background check so others feel more comfortable connecting with me.
- **US-07:** As a user creating my profile, I want to indicate whether I prefer meeting in person first so the app can suggest compatible connection styles.

### Connection & Communication

- **US-08:** As a user, I want to send a connection request with a brief introduction so the other person knows why I'm reaching out.
- **US-09:** As a recipient, I want to accept, decline, or report connection requests so I control who I interact with.
- **US-10:** As a connected user, I want to chat briefly (10 messages each) over 48 hours so we can coordinate without endless messaging.
- **US-11:** As a user, I want reminders before the chat window expires so I don't miss the opportunity to exchange contact.
- **US-12:** As a user, I want to reopen an expired chat window with mutual consent so we can continue if we weren't ready initially.

### Contact Exchange

- **US-13:** As a connected user, I want to request contact information exchange at any point during our chat so we can move offline when ready.
- **US-14:** As a recipient of a contact request, I want to approve or decline before revealing my info so I maintain full control.
- **US-15:** As a user exchanging contact, I want to choose which fields to share (email, phone, or both) so I share only what I'm comfortable with.
- **US-16:** As a user, I want to see the other person's contact info only after mutual approval so the exchange is truly consensual.

### Optional Meeting Features

- **US-17:** As a user who prefers in-person meetings, I want to propose a meeting at a public place and time so we can meet safely.
- **US-18:** As a user scheduling a meeting, I want to opt into safety check-ins so someone knows I'm okay.
- **US-19:** As a meeting participant, I want to confirm arrival and safe departure via check-ins so the app knows everything went well.
- **US-20:** As a cautious user, I want to designate an emergency contact who gets notified if I miss a check-in so I have a safety net.

### Safety & Moderation

- **US-21:** As a user, I want to report inappropriate behavior at any stage so the community stays safe.
- **US-22:** As a user, I want to block someone immediately so they can't contact me again.
- **US-23:** As a concerned user, I want to access safety guidelines and meeting tips so I make informed decisions.

---

## 4. Functional Requirements

### 4.1 User Registration & Verification (Priority: P0)

**FR-01:** Users must register with email address and create a password  
**FR-02:** Users must verify email via confirmation link  
**FR-03:** Users must verify phone number via SMS code  
**FR-04:** Users must complete government ID verification (via third-party API - TBD: Yoti, Persona, or ConnectID)  
**FR-05:** ID verification must check document authenticity and match user-provided information  
**FR-06:** Users must be 18+ (age gate enforced during ID verification)  
**FR-07:** Users may optionally purchase background check ($20-30, via third-party integration)  
**FR-08:** Verification status must be displayed as badges on profiles (verified ID, background check completed)  
**FR-09:** Failed verification attempts must trigger manual review by moderation team  
**FR-10:** All verification data must be encrypted at rest and in transit (AES-256)

### 4.2 Profile Setup (Priority: P0)

**FR-11:** Users must create a minimal profile with:

- First name or nickname
- Age (from ID verification, user cannot edit)
- General location (city/suburb, not exact address)
- 3-5 interest tags from predefined list
- Purpose statement (50-200 characters: "Why I'm seeking connection")
- Meeting preference toggle: "I prefer to meet in person before exchanging contact" (yes/no)

**FR-12:** Profiles must NOT include:

- Selfies or photos (privacy-by-design)
- Last names
- Exact addresses
- Social media links

**FR-13:** Users can optionally add a profile icon (abstract image or avatar, not personal photo)  
**FR-14:** Interest tags must be categorized (hobbies, activities, professional, causes, etc.)  
**FR-15:** Users can edit profile at any time except age and verification status  

### 4.3 Discovery & Matching (Priority: P0)

**FR-16:** Primary discovery method: algorithmic matching based on:

- Shared interests (weighted scoring)
- Proximity radius (user-adjustable: 5km, 10km, 25km, 50km)
- Age range preference (±5, ±10, ±15 years, or "any")
- Meeting preference compatibility (optional filter)

**FR-17:** Matching algorithm must suggest 5-10 profiles per day  
**FR-18:** Users can refresh matches once per 24 hours  
**FR-19:** Users can filter matches by:

- Distance
- Age range
- Specific interests
- Verification level (ID only vs. ID + background check)

**FR-20:** Backup discovery method: direct connection link

- Any verified user can generate a one-time connection link
- Link expires after 7 days or after one successful use
- Recipient must be verified before accepting connection via link

**FR-21:** Match profiles must display:

- First name
- Age
- Approximate distance (e.g., "3 km away")
- Interests
- Purpose statement
- Verification badges
- Meeting preference indicator

### 4.4 Connection Requests (Priority: P0)

**FR-22:** Users can send connection requests to:

- Algorithmic matches
- Anyone who shared a direct connection link with them

**FR-23:** Connection request must include:

- Brief introduction message (20-200 characters)
- Sender's full profile information

**FR-24:** Recipients can:

- Accept request (opens chat window)
- Decline request (no notification to sender)
- Report request as inappropriate (triggers moderation review)

**FR-25:** Users can have maximum 5 pending outgoing requests at once  
**FR-26:** Pending requests expire after 7 days  
**FR-27:** Users receive push notification when they receive a connection request

### 4.5 Limited Chat Window (Priority: P0)

**FR-28:** Upon mutual connection acceptance, chat window opens with:

- 10 messages per person maximum
- 48-hour time limit from opening
- Message character limit: 500 characters

**FR-29:** Chat window displays:

- Message count remaining for each user
- Time remaining until expiry
- Contact exchange button (always visible)
- Optional meeting scheduling button (if both users prefer in-person)

**FR-30:** System sends reminders:

- At 24 hours remaining
- At 2 hours remaining
- "Your chat expires soon - exchange contact or schedule meeting?"

**FR-31:** When chat window expires:

- Chat becomes read-only
- Either user can request to reopen (requires mutual acceptance)
- Reopened chat gets another 48 hours, 10 messages each

**FR-32:** Users can manually close chat at any time (ends connection)  
**FR-33:** Chat window stays open (does not auto-close) if:

- Contact exchange completed
- Meeting scheduled
- Until 48 hours pass or manual closure

### 4.6 Contact Information Exchange (Priority: P0)

**FR-34:** Either user can initiate contact exchange request at any point during active chat  
**FR-35:** Contact exchange request requires field-level selection:

- Requester selects what they'll share: email, phone, or both
- Requester selects what they're requesting: email, phone, or both

**FR-36:** Recipient sees request with:

- What the requester will share
- What they're asking for
- Option to approve or decline

**FR-37:** If recipient approves:

- Recipient selects which of their fields to share (email, phone, or both)
- System validates recipient shared at least what was requested
- Both users' selected contact info becomes visible

**FR-38:** Contact reveal screen displays:

- Other person's shared fields for 5 minutes (countdown timer)
- "Copy to Clipboard" buttons for each field
- "Save to Contacts" button (native iOS integration)
- After 5 minutes, screen dims but contact can be accessed via "View Contact" in chat history for 7 days

**FR-39:** Contact exchange marks connection as "graduated"  
**FR-40:** Graduated connections move to "My Connections" archive  
**FR-41:** No additional contact exchanges allowed per connection (one-time event)

### 4.7 Optional Meeting Scheduling (Priority: P1)

**FR-42:** Meeting scheduling button appears in chat only if:

- Both users indicated "I prefer to meet in person" in their profiles, OR
- One user manually suggests meeting and other accepts

**FR-43:** Meeting proposal includes:

- Suggested public venue (text field + optional Google Maps integration)
- Date and time
- Optional note (100 characters)

**FR-44:** Recipient can:

- Accept meeting (locks in details)
- Propose alternative time/place
- Decline meeting

**FR-45:** Once meeting is confirmed:

- Meeting details displayed in chat
- Optional safety check-in system activates (if either user opts in)
- Contact exchange unlocks automatically after successful meeting check-in completion

### 4.8 Optional Safety Check-In System (Priority: P1)

**FR-46:** When meeting is scheduled, users can opt into safety check-ins  
**FR-47:** Users opting in must designate an emergency contact:

- Name
- Phone number
- Relationship

**FR-48:** Check-in flow:

- App sends reminder 15 minutes before meeting: "Confirm you're heading to meeting"
- App prompts at meeting time: "Confirm you've arrived safely"
- App prompts 30 minutes after meeting start: "Confirm everything is okay"
- App prompts when meeting should end: "Confirm you've departed safely"

**FR-49:** Each check-in has 15-minute grace period  
**FR-50:** If check-in is missed:

- System sends escalating reminders (2 attempts)
- After 30 minutes of missed check-in, emergency contact receives SMS: "Your contact [Name] had a meetup scheduled and missed their safety check-in. This may be nothing, but wanted you to be aware. Meeting was at [Location]."
- Moderation team receives alert for potential follow-up

**FR-51:** Users can cancel meeting at any time (notifies other person)  
**FR-52:** Users can mark meeting as completed early (skips remaining check-ins)

### 4.9 Safety, Reporting & Moderation (Priority: P0)

**FR-53:** Users can report at any stage:

- During profile browsing
- After receiving connection request
- During chat
- After meeting

**FR-54:** Report categories:

- Inappropriate content/messages
- Suspicious or fake profile
- Safety concern during meeting
- Harassment or abuse
- Spam

**FR-55:** Report must include:

- Category selection
- Optional description (500 characters)
- Automatic attachment of relevant chat/profile data for moderation review

**FR-56:** Users can block at any time:

- Blocked users cannot send new requests
- Blocked users cannot see blocker in matches
- Blocking is permanent (cannot be undone)

**FR-57:** Reported users:

- Flagged for moderation team review within 24 hours
- May be temporarily suspended during investigation
- Repeat offenders permanently banned

**FR-58:** App includes Safety Center with:

- Meeting safety guidelines
- Privacy best practices
- How to report/block
- Emergency resources (links to local services)

### 4.10 Push Notifications (Priority: P1)

**FR-59:** Push notifications sent for:

- New connection request received
- Connection request accepted
- New chat message received (with rate limiting - max 3 notifications per conversation)
- Chat window expiring soon (24h and 2h warnings)
- Contact exchange request received
- Meeting confirmation
- Safety check-in reminders
- Moderation actions (suspension, warnings)

**FR-60:** All notifications must be configurable in settings  
**FR-61:** Quiet hours available (user-defined time range for no notifications)

### 4.11 Data Privacy & Security (Priority: P0)

**FR-62:** All user data encrypted at rest (AES-256)  
**FR-63:** All data transmission encrypted (TLS 1.3)  
**FR-64:** User location stored as approximate coordinates (rounded to ~1km accuracy)  
**FR-65:** Verification documents never stored permanently (deleted after verification complete)  
**FR-66:** Chat messages deleted 30 days after chat window closes  
**FR-67:** Contact information never stored on servers (only exchanged peer-to-peer)  
**FR-68:** Users can request data export (GDPR/CCPA compliance)  
**FR-69:** Users can request account deletion:

- All personal data deleted within 30 days
- Verification records anonymized and retained for 7 years (regulatory requirement)

**FR-70:** Privacy Policy and Terms of Service must be:

- Accessible before registration
- Written in plain language
- Compliant with GDPR and CCPA

---

## 5. Non-Goals (Out of Scope)

Explicitly defined to manage expectations and scope:

- **No long-term messaging:** Not building iMessage or WhatsApp - chat is intentionally limited
- **No social graph:** No friends lists, followers, or persistent connections within app
- **No content feeds:** No timeline, no stories, no posts
- **No in-app media:** No photo sharing, voice messages, or video calls
- **No location tracking:** Only approximate location for matching, never real-time tracking
- **No dating features:** No swiping, no romantic matching, no "date ideas"
- **No group features:** One-to-one only for MVP
- **No web/Android for MVP:** iOS first, other platforms in phase 2
- **No advanced AI:** Basic matching algorithm only, no ML/neural networks for MVP
- **No third-party integrations:** Beyond ID verification and payment processing
- **No advertising:** Ever. User privacy is core value.

---

## 6. Design Considerations

### Visual Design

**Theme:** Dark with blue accents (per brand specifications)

**Color Palette:**

- Background: Dark gradient `#0a0e27 → #1a1d3a`
- Primary accent: Blue `#3b82f6`
- Secondary accent: Orange `#f59e0b` (for CTAs)
- Borders: `rgba(59, 130, 246, 0.3-0.4)`
- Text: White with varying opacity (100% headers, 80% body, 60% secondary)
- Success: Green `#10b981`
- Warning: Yellow `#fbbf24`
- Error: Red `#ef4444`

**Typography:**

- System fonts (SF Pro on iOS)
- Base size: 16px
- Headers: Bold, 20-28px
- Body: Regular, 16px
- Secondary: Regular, 14px

**Components:**

- Card-based design for content sections
- Large touch targets (minimum 44x44pt)
- Rounded corners (12px standard)
- Generous padding (16-24px)
- Single-column layout throughout

### User Experience Principles

1. **Clarity over cleverness** - Every screen's purpose is immediately obvious
2. **Progressive disclosure** - Show only what's needed at each step
3. **Respect attention** - No dark patterns, no engagement tricks
4. **Fast paths to value** - New users should complete first connection within 7 days
5. **Safety signals** - Verification badges, safety tips always visible
6. **User control** - Clear escape hatches at every stage (decline, close, block, delete)

### Key Screens

**Onboarding Flow:**

1. Welcome screen (value proposition)
2. Email registration
3. Email verification
4. Phone verification
5. ID upload (with clear "why we verify" explanation)
6. Profile creation (name, age, location, interests, purpose, meeting preference)
7. Matching preferences setup
8. Permission requests (notifications, location)
9. Subscription options (freemium offer)
10. Matching feed

**Core App Screens:**

1. **Matching Feed** - Daily suggested matches with filters
2. **Connection Requests** - Incoming/outgoing requests
3. **Active Chats** - List of open chat windows with countdown timers
4. **My Connections** - Archive of graduated connections
5. **Profile** - User's own profile with edit options
6. **Settings** - Preferences, privacy, verification, subscription
7. **Safety Center** - Guidelines, resources, help

**Chat Screen:**

- Fixed header with match profile summary
- Message area (scrollable)
- Input field with character counter
- Floating action buttons: "Request Contact Exchange" and "Suggest Meeting" (if applicable)
- Timer display: "X messages left • X hours remaining"

**Contact Exchange Screen:**

- Request view: "Request contact from [Name]" with field selection
- Approval view: "Approve and share your contact" with field selection
- Reveal view: Large, clear display of contact info with "Copy" and "Save" buttons

### Accessibility

- WCAG 2.1 AA compliance minimum
- High contrast mode support
- Dynamic type support (user-adjustable text size)
- VoiceOver optimization (clear labels, logical navigation order)
- No color-only information conveyance
- Keyboard navigation for all interactive elements

---

## 7. Technical Considerations

### Development Context

- **Developer:** Solo founder
- **Timeline:** MVP launch mid-January 2026 (~3 months development)
- **Platform:** iOS first (Swift/SwiftUI)
- **Future platforms:** Android (Kotlin/Jetpack Compose), Web (React/PWA) - Phase 2

### Technical Stack (Recommended)

**Frontend (iOS):**

- Swift 5.9+
- SwiftUI for UI
- Combine for reactive programming
- CoreLocation for geolocation
- UserNotifications for push notifications

**Backend:**

- Node.js with Next.JS (lightweight, solo-dev friendly)
- PostgreSQL database (relational structure for users, connections, chats)
- Redis for caching and session management
- Hosted on: AWS, Google Cloud, or Railway (recommendation: Railway for solo dev)

**Authentication:**

- JWT tokens for session management
- OAuth2 for secure login
- Bcrypt for password hashing

**APIs & Integrations:**

- **ID Verification:** TBD - Options: Yoti, Persona, or ConnectID (Australia-focused)
  - Must support: Document verification, age verification, liveness check
  - Recommendation: Start with Persona (good global coverage, developer-friendly API)
- **Background Checks:** TBD - Options: Checkr, Certn
  - À la carte pricing required
- **Push Notifications:** Apple Push Notification Service (APNs)
- **Maps:** Apple Maps (native iOS integration)
- **Payment:** Stripe (for subscription management)
- **Analytics:** Privacy-focused option like PostHog (self-hosted) or TelemetryDeck

**Data Storage:**

Users Table:

```
- user_id (UUID, primary key)
- email (encrypted)
- phone (encrypted)
- password_hash
- first_name
- age
- location_lat (approximate)
- location_lng (approximate)
- interests (array)
- purpose_statement
- meeting_preference (boolean)
- verification_status (id_verified, email_verified, phone_verified, background_check)
- subscription_tier (free, premium)
- created_at
- last_active_at
```

Connections Table:

```
- connection_id (UUID, primary key)
- user_1_id (UUID, foreign key)
- user_2_id (UUID, foreign key)
- status (pending, active, graduated, closed)
- initiated_by (UUID)
- created_at
- chat_opened_at
- chat_expires_at
- messages_remaining_user_1
- messages_remaining_user_2
- contact_exchanged (boolean)
- meeting_scheduled (boolean)
```

Messages Table:

```
- message_id (UUID, primary key)
- connection_id (UUID, foreign key)
- sender_id (UUID, foreign key)
- content (encrypted)
- created_at
- deleted_at (soft delete after 30 days)
```

Reports Table:

```
- report_id (UUID, primary key)
- reported_user_id (UUID, foreign key)
- reporter_user_id (UUID, foreign key)
- report_type (enum)
- description
- status (pending, reviewed, action_taken)
- created_at
```

### Security Considerations

- Rate limiting on all API endpoints (prevent spam/abuse)
- Input validation and sanitization (prevent injection attacks)
- Content Security Policy (CSP) headers
- Regular security audits of dependencies
- Encrypted backups
- Two-factor authentication for admin panel

### Scalability Approach

For MVP (100-500 users):

- Single server instance sufficient
- Basic PostgreSQL instance
- Simple matching algorithm (query-based, no AI)

Future scaling (1000+ users):

- Horizontal scaling with load balancer
- Database read replicas
- Caching layer for match suggestions
- Background job queue for notifications, matching algorithm
- CDN for static assets

### Performance Targets

- App launch to usable: <2 seconds
- Match loading: <1 second
- Message send/receive: <500ms
- ID verification: <2 minutes (dependent on third-party)
- Contact exchange reveal: Instant

### Open Technical Questions

1. **Matching algorithm specifics:** How to weight interests vs. proximity? A/B test approach?
2. **One-time link implementation:** Short codes vs. full URLs? QR code generation?
3. **Notification delivery reliability:** How to handle offline users and delayed notifications?
4. **Chat encryption:** End-to-end? Or server-side encryption sufficient for limited window?
5. **Geographic search optimization:** PostGIS extension for PostgreSQL? Or simpler bounding box?

---

## 8. Success Metrics

### Primary Success Metric

**Contact Exchanges Completed**

- Target: 30 verified contact exchanges in first 3 months (30% conversion of 100 users)
- Measurement: Track `contact_exchanged = true` in Connections table
- Why it matters: Core value proposition - users successfully moving offline

### Secondary Metrics

**Time to First Contact Exchange (Speed)**

- Target: <7 days from registration to first contact exchange for 50% of users
- Measurement: `contact_exchanged_at - user.created_at`
- Why it matters: Validates low-friction experience

**Chat Message Density**

- Target: Average 8+ messages exchanged per connection before contact exchange
- Measurement: Average message count per connection where contact was exchanged
- Why it matters: Indicates quality interaction, not rushed exchanges

**Connection Acceptance Rate**

- Target: >40% of connection requests accepted
- Why it matters: Indicates matching quality and appropriate request behavior

### Health Metrics

**Safety & Trust:**

- Report rate: <2% of all connections
- False verification rate: <0.5%
- User blocks per 100 connections: <3

**Engagement Quality:**

- Daily active users (DAU): Track usage patterns
- Chat window completion rate: % of chats that don't expire unused
- Repeat usage: % of users who complete 2+ contact exchanges

**Business Metrics:**

- Verification completion rate: >90% of registrations
- Free-to-paid conversion: Track for future (not critical for MVP)
- Referral rate: Track NPS, word-of-mouth growth

### Measurement Tools

- **In-app analytics:** PostHog (privacy-focused) or TelemetryDeck
- **Database queries:** Weekly reports on key metrics
- **User feedback:** In-app feedback form, post-exchange survey (optional)
- **A/B testing framework:** For future optimization (not MVP critical)

### Success Criteria for MVP Launch

By April 2026 (3 months post-launch):

- ✅ 100 verified users registered
- ✅ 30+ completed contact exchanges
- ✅ <2% report rate
- ✅ >90% verification completion rate
- ✅ Average 50% of users complete first exchange within 7 days
- ✅ App Store rating >4.0 stars (if 10+ reviews)

---

## 9. Business Model & Monetization

### Freemium Model (Hybrid Approach)

**Free Tier:**

- ID verification (required)
- Email & phone verification
- 5 connection requests per month
- Full access to matching algorithm
- Limited chat windows
- Contact exchange (unlimited once connected)
- Safety Center access
- Basic moderation & reporting

**Premium Tier ($8-12/month or $20-50/year):**

- Unlimited connection requests
- Priority matching (appear higher in others' feeds)
- Advanced filters (more specific interest matching)
- Reopen expired chat windows unlimited times
- See who viewed your profile
- Meeting scheduling with safety check-ins (enhanced features)

**À La Carte Options:**

- Background check: $20-30 one-time fee
- (Future) Featured profile boost: $5 for 7 days

### MVP Monetization Strategy

**Phase 1 (Launch - Month 3):** 

- Free for all users (focus on validation, user acquisition)
- Collect background check fees only (cover costs)

**Phase 2 (Month 4-6):**

- Introduce freemium model
- Target 10-15% free-to-paid conversion
- Offer annual plan with 30% discount

**Phase 3 (Month 7+):**

- Optimize pricing based on data
- Consider regional pricing
- Introduce referral incentives

### Revenue Projections (Conservative)

**Year 1 Targets:**

- 500 total users by Month 6
- 50 premium subscribers (10% conversion)
- 20 background checks per month
- Monthly recurring revenue (MRR): ~$500-600
- Annual recurring revenue (ARR): ~$6,000-7,000

Not a VC-scale business, but sustainable for solo founder with low overhead.

### Cost Structure (Estimated Monthly)

- Server hosting: $50-100 (Railway/AWS)
- Database: $25-50
- ID verification API: ~$3-5 per verification (~$150-250/month at 50 verifications)
- Background check API: Pass-through cost to user
- Push notifications: Free (APNs)
- Analytics: $0-50 (self-hosted or free tier)
- Payment processing: 2.9% + $0.30 per transaction
- **Total monthly operating cost: ~$250-450**

Break-even: ~30-45 premium subscribers

---

## 10. Open Questions & Decisions Needed

### High Priority (Must Resolve Before Development)

**Q1: ID Verification Partner Selection**

- Options: Yoti, Persona, ConnectID (Australia-focused), Onfido
- Decision criteria: Cost per verification, developer experience, geographic coverage, privacy policies
- **Action:** Research and test each API, make decision by November 2025

**Q2: Matching Algorithm Specifics**

- How to score and weight interests vs. proximity?
- How to handle low-population areas (not enough matches)?
- How to prevent showing same people repeatedly?
- **Action:** Define basic algorithm v1, iterate based on early user feedback

**Q3: Direct Connection Link Format**

- Short codes (6-digit) or full URLs?
- Include QR code generation?
- Security considerations (one-time use, expiration)
- **Action:** Prototype both, decide based on user testing

### Medium Priority (Can Resolve During Development)

**Q4: Meeting Venue Suggestions**

- Integrate Apple Maps API for public place suggestions?
- Or just free-text field for MVP?
- **Decision:** Free-text for MVP, Maps integration in Phase 2

**Q5: Emergency Contact Notification Method**

- SMS (requires Twilio integration)?
- Email (simpler, less immediate)?
- In-app notification (requires emergency contact to have app)?
- **Decision:** SMS via Twilio for safety-critical feature

**Q6: Profile Interest Tags**

- How many categories? How many tags total?
- User-generated tags or predefined only?
- **Decision:** Predefined list of 100-150 tags across 10 categories, user-generated Phase 2

**Q7: Chat Message Encryption**

- End-to-end encryption (complex, higher security)?
- Server-side encryption (simpler, sufficient for short-lived chats)?
- **Decision:** Server-side encryption for MVP, E2E encryption if user feedback demands

### Low Priority (Post-Launch Decisions)

**Q8: Notification Optimization**

- Which notifications are most/least valuable?
- Optimal timing for reminders?
- **Approach:** A/B test post-launch, iterate based on engagement data

**Q9: Freemium Feature Boundaries**

- Is 5 connections/month the right limit for free tier?
- Which premium features most valuable?
- **Approach:** Monitor conversion rates, adjust after 3 months data

**Q10: Geographic Expansion**

- Start with specific cities or nationwide?
- International expansion timeline?
- **Approach:** Launch broadly (all iOS users), focus marketing on high-loneliness regions

---

## 11. Milestones & Timeline

### November 2025 (Month 1) - Foundation

**Week 1-2: Setup & Architecture**

- Finalize tech stack decisions
- Set up development environment
- Initialize Git repository, project structure
- Set up basic backend (Node.js + Express + PostgreSQL)
- Database schema design and creation

**Week 3-4: Core Backend**

- User authentication (registration, login, JWT)
- ID verification API integration (partner TBD)
- Email & phone verification flows
- User profile CRUD operations
- Basic matching algorithm (query-based)

**Deliverable:** Backend API with authentication and user management

---

### December 2025 (Month 2) - Core Features

**Week 1-2: iOS App Foundation**

- SwiftUI project setup
- Onboarding flow UI
- Registration & verification screens
- Profile creation flow
- Settings & preferences screens

**Week 3: Discovery & Connections**

- Matching feed UI
- Connection request system (backend + frontend)
- Direct connection link generation & handling
- Connection acceptance/decline flows

**Week 4: Chat System**

- Chat window UI (message input, display, counters)
- Real-time messaging (WebSocket or polling)
- Chat expiration logic
- Reopen expired chat flow

**Deliverable:** Core app with onboarding, matching, and basic chat

---

### January 2026 (Month 3) - Polish & Launch

**Week 1: Contact Exchange & Meetings**

- Contact exchange request/approval UI
- Contact reveal screen (5-minute display, copy/save)
- Optional meeting scheduling UI
- Safety check-in system (if time permits, otherwise post-launch)

**Week 2: Safety & Polish**

- Reporting & blocking UI
- Safety Center content
- Moderation dashboard (simple admin panel)
- Push notification implementation
- Error handling & edge cases

**Week 3: Testing & Refinement**

- Internal testing (beta testers)
- Bug fixes
- Performance optimization
- App Store assets (screenshots, description, preview video)

**Week 4: Launch Preparation**

- App Store submission
- Privacy Policy & Terms of Service final review
- Marketing website (simple landing page)
- Launch announcement content
- Monitor approval process

**Target Launch Date: Mid-January 2026**

---

### Post-Launch (February-April 2026)

**Week 1-2 Post-Launch:**

- Monitor metrics closely
- Hot-fix any critical bugs
- User feedback collection
- Iterate on onboarding flow if drop-off high

**Month 2-3 Post-Launch:**

- Implement safety check-in system (if not in MVP)
- Refine matching algorithm based on data
- Introduce freemium tier
- A/B test premium feature boundaries
- Begin Android development planning

**Month 4+:**

- Android MVP launch
- Web companion site
- Advanced features based on user requests
- Geographic expansion marketing

---

## 12. Risks & Mitigation

### Technical Risks

**Risk:** ID verification API reliability or cost issues

- **Mitigation:** Research 2-3 backup providers, negotiate bulk rates, build abstraction layer

**Risk:** Solo development timeline slip

- **Mitigation:** Ruthless scope control, cut optional features, extend timeline if needed

**Risk:** Scalability issues with rapid growth

- **Mitigation:** Start with Railway (scales automatically), monitor performance, simple architecture easy to upgrade

### Market Risks

**Risk:** Low user adoption (network effects require critical mass)

- **Mitigation:** Start with targeted communities (local groups, universities), referral program, PR in loneliness/mental health spaces

**Risk:** Competition from established apps (Bumble For Friends, Patook)

- **Mitigation:** Differentiate on privacy, simplicity, verification rigor; target users frustrated with existing options

**Risk:** Safety incidents harm reputation

- **Mitigation:** Overinvest in safety features, clear guidelines, responsive moderation, transparent communication

### Legal/Regulatory Risks

**Risk:** Privacy regulation compliance (GDPR, CCPA)

- **Mitigation:** Privacy-by-design architecture, clear policies, regular audits, legal review before launch

**Risk:** Liability for user meetings/safety

- **Mitigation:** Strong disclaimers in ToS, safety guidelines, optional nature of meetings, emergency contact system

**Risk:** ID verification regulatory requirements

- **Mitigation:** Partner with compliant provider (Yoti/Persona handle regulations), document verification process

### Financial Risks

**Risk:** Operating costs exceed revenue (burn rate)

- **Mitigation:** Low-cost infrastructure, introduce premium tier early, background check pass-through pricing

**Risk:** Verification costs too high per user

- **Mitigation:** Negotiate volume discounts, consider one-time verification fee ($2-5), optimize verification success rate

---

## 13. Appendices

### Appendix A: Competitor Comparison

| Feature                 | Human Contact                   | Bumble For Friends      | Patook             | Nextdoor           |
| ----------------------- | ------------------------------- | ----------------------- | ------------------ | ------------------ |
| ID Verification         | ✅ Required                      | ⚠️ Optional/Rolling out | ❌ No               | ⚠️ Address only    |
| Contact Exchange        | ✅ Primary feature               | ❌ In-app chat only      | ❌ In-app chat only | ❌ In-app only      |
| No Photos Required      | ✅ Yes                           | ❌ Photos required       | ⚠️ Optional        | ⚠️ Optional        |
| Meeting Safety Features | ✅ Check-ins, emergency contacts | ⚠️ Share My Date        | ❌ No               | ❌ No               |
| Limited Chat            | ✅ 10 msgs/48h                   | ❌ Unlimited             | ❌ Unlimited        | ❌ Unlimited        |
| Direct Connection Link  | ✅ Yes                           | ❌ No                    | ❌ No               | ❌ No               |
| Privacy Focus           | ✅ Core value                    | ⚠️ Moderate             | ⚠️ Moderate        | ❌ Public by design |
| Purpose                 | Verified contact bridge         | Dating + Friends        | Platonic only      | Neighborhood forum |

**Key Differentiator:** Human Contact is the only app designed explicitly as a *bridge* with *verified-only* users, *contact exchange* as the goal, and *privacy-by-design* (no photos required).

---

### Appendix B: Example User Flows

**Flow 1: First-Time User to First Contact Exchange**

1. User downloads app
2. Registers with email → verifies email via link
3. Verifies phone via SMS code
4. Uploads government ID → waits for approval (~2 min)
5. Creates minimal profile (name, age, location, interests, purpose, meeting pref)
6. Sets matching preferences (distance, age range)
7. Sees 5-10 suggested matches
8. Sends connection request to Match A with brief intro
9. Match A accepts → chat window opens
10. Users exchange 5-6 messages coordinating
11. User requests contact exchange (offers email, requests email)
12. Match A approves and shares email
13. Both see contact info, copy to clipboard
14. Connection marked as "graduated"
15. Users continue conversation via email offline

**Time to value:** 30 minutes to 7 days (depending on match response time)

---

**Flow 2: Direct Connection After In-Person Meeting**

1. User A and User B meet at a coffee shop
2. They hit it off, want to stay in touch
3. User A opens app → "Connect Directly" → generates one-time link
4. User A shares link via text or QR code
5. User B clicks link → prompted to download app (if new) or login
6. User B accepts connection via link
7. Chat window opens (skips matching phase)
8. Brief exchange to confirm identities
9. User A requests contact exchange
10. User B approves
11. Both have each other's contact info
12. Continue friendship via text/email

**Time to value:** 5-10 minutes

---

### Appendix C: Content Guidelines & Moderation

**Prohibited Content/Behavior:**

- Harassment, threats, or abusive language
- Sexual content or solicitation (not a dating app)
- Spam or commercial solicitation
- Fake profiles or impersonation
- Requests for money or financial information
- Sharing others' personal information without consent
- Hate speech, discrimination, or extremist content

**Moderation Process:**

1. User reports via in-app tool (categorized report)
2. Automated flagging for severe keywords (immediate temp suspension)
3. Human moderator reviews within 24 hours
4. Actions: Warning, temporary suspension (7 days), permanent ban
5. Repeat offenders escalate faster (2 warnings → ban)
6. Appeals process: Email moderation@humancontact.app with case number

**Moderator Training:**

- Review safety guidelines and examples
- Err on side of user safety
- Escalate edge cases to founder/senior moderator
- Document patterns and update automated filters

---

### Appendix D: Marketing & Launch Strategy (Brief)

**Pre-Launch:**

- Build simple landing page (email waitlist)
- Post in relevant communities (Reddit: r/lonely, r/Needafriend, r/loneliness)
- Reach out to mental health advocates, loneliness researchers for endorsements
- Create explainer video (2-3 minutes)

**Launch Day:**

- Product Hunt launch
- Submit to app review sites (TechCrunch, The Verge tips)
- Social media announcement (Twitter, LinkedIn)
- Email waitlist with download link

**Post-Launch Growth:**

- Referral system (invite friends, both get premium trial)
- Content marketing (blog about loneliness, connection, safety)
- Partnerships with therapists, community organizations
- Local event activations (college campuses, coworking spaces)

**Target Audience Segments:**

1. People new to a city (recent movers)
2. Remote workers seeking IRL connection
3. Post-pandemic social reconnection seekers
4. Adults 18+ experiencing loneliness
5. Privacy-conscious individuals frustrated with data-harvesting apps

---

## Document Control

**Version:** 3.0  
**Status:** Draft for Review  
**Created:** October 15, 2025  
**Created By:** Sam Gordon (Founder) with AI assistance  
**Target Audience:** Solo developer (Sam), future team members, potential advisors/investors  
**Next Review Date:** November 1, 2025 (pre-development kickoff)

**Change Log:**

- v1.0 - Full-featured approach with meetings required (archived)
- v2.0 - Minimal contact-exchange only (archived)
- v3.0 - Hybrid model combining discovery, optional meetings, mutual consent contact exchange

---

**END OF PRD**

This PRD is a living document and will be updated as decisions are made, technical implementations are validated, and user feedback is incorporated.
