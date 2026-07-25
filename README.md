# Salin

> **Know what's left.**

Salin is a premium, local-first budgeting application built for students and young Filipino professionals. Instead of focusing on account balances or net worth, Salin answers one simple question:

> **"After everything that matters, what's actually left?"**

Unlike traditional finance applications that overwhelm users with charts, investments, and financial jargon, Salin provides a calm, focused experience centered around the remaining budget, upcoming obligations, and everyday spending decisions.

The app is designed to feel like a quiet financial companion—not accounting software.

---

# Philosophy

Most budgeting applications answer:

> "How much money do I have?"

Salin answers:

> "What can I still safely spend?"

Every major feature revolves around what remains.

Examples include:

- Remaining monthly budget
- Remaining category budget
- Remaining debt balance
- Remaining split balance
- Remaining recurring obligations

Numbers are presented clearly, honestly, and without unnecessary visual noise.

---

# Target Users

### Primary

Students and young Filipino professionals who are:

- managing their own finances for the first time
- budgeting monthly allowances or salaries
- using multiple payment methods
- splitting expenses with friends
- paying recurring subscriptions and bills

### Secondary

Freelancers and gig workers with irregular income who need a simple way to monitor remaining cash flow between projects.

---

# Core Features

## Home Dashboard

The dashboard immediately answers:

> "What's left?"

Displays:

- Remaining monthly budget
- Upcoming recurring bills
- Pending splits
- Outstanding debts
- Recent activity
- Contextual financial insights

---

## Accounts

Manage multiple account types including:

- Cash
- Bank
- E-wallet
- Credit Card

---

## Transactions

Record income and expenses.

Supports:

- Categories
- Accounts
- Notes
- Attachments (future)
- Search
- Filtering

---

## Quick Add

Paste or type naturally.

Examples:

- Bank SMS
- Receipt text
- Casual sentences
- Transaction lists

AI automatically extracts transactions for review before saving.

---

## Budgets

Create monthly budgets by category.

Track:

- Budget
- Spent
- Remaining

---

## Recurring Payments

Manage subscriptions and recurring bills.

Features:

- Flexible schedules
- Upcoming reminders
- Mark as paid
- Overdue detection

---

## Splits

Track shared expenses.

Supports:

- People who owe you
- People you owe
- Settlement tracking

---

## Debts

Track personal loans separately from shared expenses.

Supports:

- Money lent
- Money borrowed
- Partial repayments
- Remaining balances

---

## Insights

Provides meaningful financial observations instead of overwhelming dashboards.

Examples:

- Largest spending category
- Monthly comparisons
- Spending trends
- Remaining vs spent
- Budget performance

---

## Personalization

Customize:

- Accent colors
- Dark mode
- Dashboard widgets
- Layout density
- Home greeting
- Currency format

---

# Design Principles

Salin is designed around five principles.

## Calm

The interface should never overwhelm users.

Whitespace is preferred over density.

---

## Honest

Financial information is presented truthfully without exaggeration.

No artificial achievements.

No manipulation.

---

## Personal

The application should feel approachable through thoughtful personalization and contextual insights.

---

## Modern

Inspired by:

- Apple Wallet
- Linear
- Notion
- Arc Browser

Not by traditional banking software.

---

## Timeless

The interface favors typography, spacing, and hierarchy over visual trends.

---

# Technology Stack

| Layer | Technology |
|---------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Database | Drift |
| Secure Storage | flutter_secure_storage |
| Serialization | Freezed + json_serializable |
| Charts | fl_chart |
| AI | Google Gemini |
| Authentication | Firebase Authentication |
| Analytics | Firebase Analytics |
| Crash Reporting | Firebase Crashlytics |

Detailed explanations can be found in `TECH_STACK.md`.

---

# Architecture

Salin follows an local-first architecture.

```
Presentation
      │
Application
      │
Domain
      │
Persistence
      │
Storage
```

Business logic remains independent from UI.

More information is available in `ARCHITECTURE.md`.

---

# Repository Structure

```
salin/

README.md
PRODUCT.md
DESIGN.md
ARCHITECTURE.md
TECH_STACK.md
DATA_MODEL.md
API_SPEC.md
AI_GUIDELINES.md
CODING_STANDARDS.md
ROADMAP.md
CHANGELOG.md

docs/
design/
assets/
```

---

# Development Philosophy

This repository is designed for AI-assisted software development.

Documentation is considered part of the codebase.

Every major design decision should be documented before implementation.

Business rules should exist in documentation—not hidden inside source code.

---

# Getting Started

## Requirements

- Flutter (latest stable)
- Dart SDK
- Android Studio
- Xcode (macOS only)
- Firebase CLI
- Git

---

## Clone Repository

```bash
git clone https://github.com/<username>/salin.git

cd salin
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Run Application

```bash
flutter run
```

---

# Documentation

| Document | Purpose |
|------------|----------|
| PRODUCT.md | Product vision, users, features, and business goals |
| DESIGN.md | Design philosophy, UI system, interaction principles |
| ARCHITECTURE.md | Software architecture and project organization |
| TECH_STACK.md | Technologies and libraries used |
| DATA_MODEL.md | Database schema and domain models |
| API_SPEC.md | Future API contracts |
| AI_GUIDELINES.md | Instructions for AI coding assistants |
| CODING_STANDARDS.md | Coding conventions and best practices |
| ROADMAP.md | Product roadmap and development milestones |
| CHANGELOG.md | Version history |

---

# Current Scope

This version focuses on building a complete personal budgeting experience.

Included:

- Accounts
- Transactions
- Budgets
- Recurring Payments
- Splits
- Debts
- Insights
- Personalization

Planned for future releases:

- Safety Net
- Protection
- Growth
- Guidance

---

# Contributing

Before implementing any feature:

1. Read PRODUCT.md.
2. Read DESIGN.md.
3. Verify business rules in DATA_MODEL.md.
4. Follow CODING_STANDARDS.md.
5. Ensure consistency with existing architecture.

---

# Vision

Salin is not trying to become another finance super app.

It is trying to become the budgeting application people trust enough to open every day.

Every interaction should reinforce one idea:

> **Not "How much money do I have?"**

> **"After everything that matters, what's left?"**