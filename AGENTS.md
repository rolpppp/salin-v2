# AGENTS.md

# Salin Engineering Handbook

Version: 1.0

Status: Active

---

# Purpose

This document defines how contributors—human or AI—should approach development on Salin.

It serves as the engineering handbook for the project and establishes:

- development philosophy
- documentation hierarchy
- architectural boundaries
- implementation workflow
- coding expectations
- review checklist

Before implementing any feature, read this document.

---

# About Salin

Salin is an offline-first personal finance application whose central question is:

> "What's left?"

Everything in the application should reinforce this idea.

Salin is not designed to maximize engagement.

It is designed to maximize financial clarity.

The product should feel:

- calm
- trustworthy
- intentional
- lightweight
- predictable

Never sacrifice clarity for novelty.

---

# Documentation Hierarchy

If multiple documents discuss the same topic, follow this order of precedence.

```
PRODUCT.md

↓

BUSINESS_RULES.md

↓

FEATURE_SPEC.md

↓

DATA_MODEL.md

↓

ARCHITECTURE.md

↓

SYNC.md

↓

API.md

↓

FRONTEND.md

↓

DESIGN.md

↓

TECH_STACK.md

↓

SPRINTS.md
```

Higher documents always override lower ones.

---

# Before Writing Code

Always identify the feature being implemented.

Then read the relevant documents.

Minimum reading:

- PRODUCT.md
- FEATURE_SPEC.md
- BUSINESS_RULES.md
- FRONTEND.md

If database changes are involved:

- DATA_MODEL.md

If synchronization is involved:

- SYNC.md
- API.md

If UI changes are involved:

- DESIGN.md
- FRONTEND.md

Never implement from assumptions.

---

# Development Philosophy

Follow these principles throughout the project.

## Offline First

The application must function without internet access.

Networking enhances the application.

It must never be required for core financial workflows.

---

## Local Database is the Source of Truth

Drift is authoritative.

The backend exists only for:

- synchronization
- authentication
- cloud backup
- AI services

Never design features that depend on immediate server responses.

---

## Reuse Before Building

Before creating:

- widget
- provider
- repository
- utility
- service

Search the existing project.

Prefer extending existing components over creating new ones.

---

## Composition Over Duplication

Small reusable pieces are preferred over large specialized implementations.

Avoid copy-pasting code.

Extract reusable logic.

---

## Keep Business Logic Out of UI

Widgets display data.

They should not calculate business rules.

Business rules belong in:

- services
- repositories
- providers

Never inside widgets.

---

## Data Flows Down

User Action

↓

Provider

↓

Repository

↓

Database

↓

Provider

↓

UI

Avoid bypassing this flow.

---

# Architecture Rules

Respect the project architecture.

```
Presentation

↓

Application

↓

Repository

↓

Local Database

↓

Sync Layer (optional)
```

Never skip layers.

---

# Database Rules

The database is defined in DATA_MODEL.md.

Rules:

- Never modify schema without updating DATA_MODEL.md.
- Every migration must preserve user data.
- Use UUIDs.
- Never use auto-increment IDs.
- Store timestamps in UTC.
- Soft delete whenever possible.
- Never expose Drift directly to the UI.

---

# Repository Rules

Repositories are responsible for:

- database access
- synchronization
- persistence

Repositories should not contain UI logic.

Repositories should expose domain models—not raw database rows.

---

# State Management Rules

State should be predictable.

Providers should:

- expose immutable state
- contain presentation logic
- coordinate repositories

Avoid business calculations inside widgets.

---

# UI Rules

Follow FRONTEND.md.

Rules:

- One primary action per screen.
- Use existing components.
- Preserve spacing.
- Preserve typography.
- Respect accessibility.
- Never introduce new interaction patterns without updating FRONTEND.md.

---

# Design Rules

Follow DESIGN.md.

Never:

- hardcode colors
- hardcode spacing
- hardcode typography
- hardcode border radius

Use design tokens.

Money should always be easier to scan than decorative elements.

---

# Business Rules

Business rules belong exclusively in BUSINESS_RULES.md.

Never duplicate business logic.

When adding new financial behavior:

1. Update BUSINESS_RULES.md
2. Update DATA_MODEL.md if required
3. Implement logic
4. Add tests

---

# Sync Rules

Read SYNC.md before implementing cloud features.

Remember:

Offline always succeeds.

Sync is eventually consistent.

Conflict resolution must never lose user data.

---

# API Rules

Read API.md before backend work.

The backend never computes:

- balances
- budgets
- statistics
- insights

Those belong on the client.

---

# Feature Development Workflow

Every feature should follow this order.

```
Understand Feature

↓

Read Documentation

↓

Update Documentation (if required)

↓

Update Data Model

↓

Implement Repository

↓

Implement Provider

↓

Implement UI

↓

Testing

↓

Documentation Review
```

Documentation comes before implementation.

---

# Component Workflow

Before creating a component:

Search existing components.

If one exists:

Reuse it.

Create a new component only when:

- behavior is fundamentally different
- existing component would become overly complex
- reusability improves

---

# Performance Principles

Optimize for perceived performance.

Rules:

- Prefer local reads.
- Avoid unnecessary rebuilds.
- Lazy load large collections.
- Cache expensive calculations.
- Paginate when appropriate.
- Keep animations lightweight.

Never optimize prematurely.

Measure first.

---

# Accessibility

Every feature should support:

- screen readers
- dynamic text
- sufficient contrast
- semantic labels
- minimum touch targets

Accessibility is a requirement—not an enhancement.

---

# Error Handling

Errors should:

Explain

↓

Recover

↓

Continue

Never expose raw exceptions to users.

Every error should provide:

- explanation
- recovery action
- logging

---

# Security

Never:

- log financial data
- log authentication tokens
- expose encryption keys
- trust client input on the backend

Sensitive information belongs in Secure Storage.

---

# Testing Expectations

Every feature should include appropriate tests.

Business Logic

Unit Tests

↓

Repositories

Repository Tests

↓

Widgets

Widget Tests

↓

Critical Workflows

Integration Tests

Bug fixes should include regression tests whenever practical.

---

# Code Quality

Prefer readability over cleverness.

Small functions.

Clear names.

Single responsibility.

Avoid unnecessary abstraction.

Document non-obvious decisions.

---

# Things Never To Do

Never:

- Access Drift directly from widgets.
- Duplicate business logic.
- Hardcode design values.
- Store financial records in SharedPreferences.
- Perform network requests directly from widgets.
- Bypass repositories.
- Introduce new architecture without discussion.
- Ignore offline behavior.
- Modify schema without updating DATA_MODEL.md.
- Break existing synchronization contracts.
- Skip validation.
- Silence errors without logging them.

---

# Pull Request Checklist

Before considering work complete:

✓ Requirements understood

✓ Documentation updated

✓ Architecture respected

✓ Business rules followed

✓ UI matches DESIGN.md

✓ UX matches FRONTEND.md

✓ Database updated (if needed)

✓ Tests added

✓ No duplicate logic

✓ No unnecessary dependencies

✓ No hardcoded values

---

# Decision Making

When uncertain, prefer the option that:

- simplifies the architecture
- improves maintainability
- reduces duplication
- strengthens offline capability
- preserves consistency

Do not optimize for short-term convenience.

---

# The Salin Rule

Every decision should answer one question:

> Does this help the user understand what's left?

If the answer is no,

reconsider the implementation.

---

# Definition of Success

A successful contribution:

- improves the product without increasing unnecessary complexity
- preserves offline-first behavior
- maintains architectural consistency
- follows the documented design system
- respects business rules
- leaves the codebase easier to understand than before

Every commit should move Salin toward becoming a calm, trustworthy financial companion.