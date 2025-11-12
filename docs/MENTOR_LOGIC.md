# Mentor Intelligence Logic - How It Currently Works

This document explains the mentor system's decision-making process in plain English.

---

## Overview

The mentor analyzes your current state (goals, habits, journals) and shows you the most relevant coaching card. It checks for different situations **in priority order** and shows the first match it finds.

Think of it like a decision tree: "Is user brand new? → Yes, show welcome card. No, check next condition..."

### 🔑 Hardcoded vs LLM-Generated

The mentor system has **two distinct phases**:

#### Phase 1: Decision Logic (HARDCODED)
- **What it does:** Determines WHICH card to show based on your data
- **How it works:** Checks conditions in priority order (see below)
- **Implementation:** Pure Dart code with hardcoded thresholds and rules
- **Example:** "If goal created >3 days ago AND progress <10% → Trigger 'Stalled Goal' card"

#### Phase 2: Content Generation (MIX of both)

**Option A - Hardcoded Templates:**
- Simple, predefined messages with variable substitution
- Example: `"Your '${goalName}' deadline is in ${hoursLeft} hours"`
- Fast, predictable, no API calls required

**Option B - LLM-Generated Content:**
- Calls Claude API with context about your situation
- Prompt includes: card type, relevant data (goal names, progress, etc.)
- More personalized and adaptive to nuance
- Example prompt: "User has stalled goal 'Learn Spanish', created 5 days ago, 0% progress. Generate empathetic coaching message."

**Current Implementation Status:**
- ⚠️ **TBD**: Not all cards are implemented yet
- 🎯 **Design Decision Pending**: Which cards use templates vs LLM
- 📋 **Recommendation**: Use templates for simple cases (deadlines, streaks), LLM for complex coaching (stalled goals, comebacks)

---

## Important: Example Messages

Throughout this document, you'll see quoted example messages like:
> "Welcome to MentorMe! Let's start by understanding what matters most to you..."

**These are ILLUSTRATIVE EXAMPLES**, not necessarily the actual hardcoded text or LLM output. They demonstrate the *tone and intent* of each card type.

---

## The Priority System (Top to Bottom)

### 1️⃣ NEW USER (Highest Priority - Onboarding)

**What triggers this:**
- You have zero goals
- You have zero habits
- You have zero journal entries

**What the mentor does:**
- Shows a warm welcome message
- Suggests starting with guided reflection
- Provides "Get Started" action

**Why this comes first:**
- Brand new users need onboarding
- Most important to get them engaged

**Example:**
> "Welcome to MentorMe! Let's start by understanding what matters most to you..."

---

### 2️⃣ URGENT DEADLINE (Critical Priority)

**What triggers this:**
- You have a goal with a deadline
- The deadline is within 24 hours
- The goal is not yet 100% complete

**What the mentor does:**
- Shows urgent, focused message
- Highlights time remaining ("12 hours left")
- Helps prioritize what can still be done
- Creates urgency without panic

**Why this comes second:**
- Time-sensitive - can't wait
- Prevents missed deadlines

**Example:**
> "Your 'Submit Project Proposal' deadline is in 12 hours. You're at 60% - here's what to focus on..."

---

### 3️⃣ STREAK AT RISK (High Priority)

**What triggers this:**
- You have a habit with a streak of 7+ days
- You haven't completed it today yet

**What the mentor does:**
- Celebrates your achievement (7, 14, 30 days!)
- Reminds you to complete today
- Motivates without guilt
- Shows "Don't break the chain" urgency

**Why this comes third:**
- Protects hard-earned progress
- Streaks are motivating but fragile
- Still time-sensitive (today only)

**Example:**
> "Your 14-day 'Morning Exercise' streak is amazing! Complete it today to keep the momentum going."

---

### 4️⃣ STALLED GOAL (Medium-High Priority)

**What triggers this:**
- Goal created 3+ days ago
- Current progress less than 10%
- Still actively pursuing it

**What the mentor does:**
- Acknowledges the stall empathetically
- Asks reflective questions ("What's holding you back?")
- Suggests small next step
- No guilt or shame

**Why here in priority:**
- Common issue (procrastination)
- Not time-critical but important
- Early intervention prevents abandonment

**Example:**
> "You created 'Learn Spanish' 5 days ago but haven't started yet. What's getting in the way?"

---

### 5️⃣ MINI WIN (Medium Priority)

**What triggers this:**
- Goal created 3+ days ago
- Progress less than 5%
- No journal entries (stuck in planning, not reflecting)

**What the mentor does:**
- Suggests a tiny 5-minute action
- Breaks analysis paralysis
- Makes starting feel easy
- Focuses on momentum, not completion

**Why here:**
- Specific intervention for planning paralysis
- More targeted than general stalled goal
- Unlocks movement

**Example:**
> "Feeling stuck on 'Write a Book'? Just write one paragraph today. 5 minutes, that's it."

---

### 6️⃣ COMEBACK (Medium Priority)

**What triggers this:**
- You've journaled before (not a new user)
- It's been 3+ days since your last journal entry

**What the mentor does:**
- Welcomes you back warmly
- No guilt about the gap
- Suggests checking in to reconnect
- Re-engages without pressure

**Why here:**
- Re-engagement is important
- Not urgent, but prevents long-term dropout

**Example:**
> "Welcome back! It's been a few days. How are things going? Let's check in."

---

### 7️⃣ FEATURE DISCOVERY (Medium Priority)

There are **3 types** of feature discovery cards:

#### 7a. Discover Habit Checking

**What triggers this:**
- You completed a reflection/journal entry
- You haven't checked off your habit yet
- First time this combination happens

**What the mentor does:**
- Tutorial on reflection → habit workflow
- "Now check off your habit!"
- Shows you the connection

**Example:**
> "Great reflection! Now, did you complete 'Morning Exercise'? Check it off to track your progress."

#### 7b. Discover Chat

**What triggers this:**
- You have goals or journal entries
- You've never used the chat feature

**What the mentor does:**
- Introduces the chat feature
- Explains how to get personalized advice
- Invites first conversation

**Example:**
> "Did you know you can chat with me anytime? Ask me about your goals or for advice!"

#### 7c. Discover Milestones

**What triggers this:**
- You have goals
- None of your goals have milestones

**What the mentor does:**
- Explains milestone breakdown feature
- Shows how milestones make big goals achievable
- Suggests trying it

**Example:**
> "Big goals feel overwhelming. Break 'Learn Spanish' into smaller milestones to track progress."

**Why here:**
- Helps users discover features
- Not urgent, but improves experience
- One-time per feature (won't spam)

---

### 8️⃣ WINNING (Low-Medium Priority)

**What triggers this:**
- 80%+ habit completion rate
- 4+ journal entries per week
- Sustained for 14 days

**What the mentor does:**
- Celebrates your success genuinely
- Acknowledges consistency
- Suggests leveling up
- Encourages new challenges

**Why here:**
- Positive reinforcement
- Not urgent (you're already winning!)
- Prevents plateauing

**Example:**
> "You're crushing it! 21-day streak, consistent journaling. Ready for the next challenge?"

---

### 9️⃣ PARTIAL DATA STATES (Low Priority)

These catch users who are **only using one or two features**:

#### 9a. Only Journals

**What triggers this:**
- You have journal entries
- No goals, no habits

**What the mentor does:**
- Analyzes your journal themes
- Suggests turning insights into goals
- Shows connection between reflection and action

**Example:**
> "You've been reflecting on fitness a lot. Ready to set a fitness goal?"

#### 9b. Only Habits

**What triggers this:**
- You have habits
- No journals, no goals

**What the mentor does:**
- Suggests adding reflection
- Shows how journaling amplifies habit success
- Invites guided reflection

**Example:**
> "You're building great habits! Journaling can help you understand what's working and why."

#### 9c. Only Goals

**What triggers this:**
- You have goals
- No journals, no habits

**What the mentor does:**
- Suggests daily habits to support goals
- Shows habit-goal connection
- Recommends starting small

**Example:**
> "'Get Fit' is a great goal! What daily habit would support it? Morning walk? Meal prep?"

#### 9d. Habits + Goals (No Journals)

**What triggers this:**
- You have both habits and goals
- No journal entries

**What the mentor does:**
- Suggests reflection to amplify progress
- Shows how journaling reveals patterns
- Invites first reflection

**Example:**
> "You're tracking habits and goals. Journaling helps you see what's working and adjust."

**Why these are low priority:**
- Users are already engaged (not new)
- Not urgent or time-sensitive
- Gentle nudge toward full experience

---

### 🔟 BALANCED (Default Fallback)

**What triggers this:**
- You have all three: journals, habits, goals
- None of the higher-priority conditions match

**What the mentor does:**
- Contextual encouragement based on your progress
- General check-in and support
- Adaptive message based on recent activity

**Why this is last:**
- You're already using the app well
- No specific intervention needed
- Generic positive support

**Example:**
> "Keep up the great work! You're making progress on your goals and building strong habits."

---

## How the Decision Tree Works

### The Algorithm Flow:

```
1. Is user brand new (no data)?
   YES → Show new user welcome
   NO → Check next...

2. Any goals with deadline in < 24 hours?
   YES → Show urgent deadline card
   NO → Check next...

3. Any habit streaks ≥7 days not done today?
   YES → Show streak protection card
   NO → Check next...

4. Any goals created 3+ days ago with <10% progress?
   YES → Show stalled goal card
   NO → Check next...

5. Goal created 3+ days ago, <5% progress, no journals?
   YES → Show mini win card
   NO → Check next...

6. Has journaled before but 3+ days since last entry?
   YES → Show comeback card
   NO → Check next...

7. Any undiscovered features that would help?
   YES → Show feature discovery card
   NO → Check next...

8. Winning (80%+ habits, 4+ journals/week for 14 days)?
   YES → Show celebration + new challenge
   NO → Check next...

9. Using only 1-2 features (not all 3)?
   YES → Show partial data suggestion
   NO → Check next...

10. DEFAULT: Show balanced encouragement
```

### Key Principles:

**First Match Wins**
- The system checks conditions in order
- It stops at the first match
- It never shows multiple cards at once

**Early Returns**
- If you're a new user, you get welcome (never gets to check deadlines)
- If you have an urgent deadline, you get that (never gets to check streaks)
- Priority = what's most important right now

**Context Passed Along**
- When a condition matches, relevant data is captured
- Example: Stalled goal card gets the specific goal object
- This allows personalized messages ("Your 'Learn Spanish' goal...")

---

## Constants (Thresholds)

These are the specific numbers that trigger each state:

- **Urgent Deadline:** Within 24 hours
- **Streak Protection:** 7+ day streak
- **Stalled Goal:** 3+ days old, <10% progress
- **Mini Win:** 3+ days old, <5% progress
- **Comeback:** 3+ days since last journal
- **Winning:** 80%+ habit completion, 4+ journals/week, 14 days sustained

---

## What Gets Personalized

### Data Available for Message Generation

When the mentor generates a message (whether via template or LLM), it has access to relevant context:

**For Stalled Goals:**
- Specific goal name ("Learn Spanish")
- Days since created (5 days)
- Current progress percentage (0%)
- Goal category (Career, Health, etc.)

**For Streak Protection:**
- Specific habit name ("Morning Exercise")
- Current streak length (14 days)
- Completion history (last 30 days)

**For Urgent Deadlines:**
- Goal name
- Hours/minutes remaining (precise countdown)
- Current progress percentage
- Milestones (if defined)

**For Comeback:**
- Days since last journal entry
- Previous journal themes (if using LLM)
- Recent goal activity

### Template vs LLM Examples

#### Using Hardcoded Template:
```dart
// Simple string interpolation
"Your '${goal.title}' deadline is in ${hoursLeft} hours. You're at ${goal.progress}% - you can finish!"
```
Result:
> "Your 'Submit Proposal' deadline is in 12 hours. You're at 60% - you can finish!"

#### Using LLM Generation:
```dart
// Prompt sent to Claude API
"""
Card Type: URGENT_DEADLINE
Goal: "Submit Proposal"
Hours Remaining: 12
Current Progress: 60%
Milestones: ["Research Complete", "Draft Outline", "Write Content", "Review"]

Generate a motivating, urgent message that helps the user focus on what they can realistically accomplish.
"""
```
Possible LLM Result:
> "Your 'Submit Proposal' deadline is 12 hours away - you're in the home stretch at 60%! Focus on finishing 'Write Content' and 'Review' now. You've got the research and outline done, so you're closer than you think. Time to sprint!"

**Key Difference:**
- **Template:** Fixed structure, just fills in variables
- **LLM:** Understands context deeply, can provide nuanced guidance based on multiple factors

---

## Special Cases

### Multiple Matches

**Q: What if I have both an urgent deadline AND a stalled goal?**

A: You only see the urgent deadline card. Priority order wins.

### Timing

**Q: When does the mentor check my state?**

A: When you open the mentor screen. It analyzes your current data fresh each time (with caching for performance).

### State Changes

**Q: If I complete my habit, does the card update immediately?**

A: The card regenerates when significant data changes (detected via state hash). Small updates are debounced to prevent flickering.

---

## Summary

The mentor system:

1. **Analyzes your current state** - Goals, habits, journals (HARDCODED LOGIC)
2. **Checks priority conditions** - Top to bottom, first match wins (HARDCODED LOGIC)
3. **Generates personalized card** - Uses your specific data (TEMPLATE or LLM)
4. **Shows relevant guidance** - What you need most right now

The priority order ensures **urgent things come first**, **onboarding happens for new users**, and **feature discovery helps without nagging**.

It's designed to feel like a real mentor who knows your situation and offers timely, relevant guidance - not generic advice.

---

## Recommendations: When to Use Templates vs LLM

### Use HARDCODED TEMPLATES for:

**✅ Simple, formulaic messages:**
- **Urgent Deadline:** "Your '{goal}' deadline is in {hours} hours. You're at {progress}% - focus on finishing!"
- **Streak Protection:** "Your {days}-day '{habit}' streak is amazing! Don't break it - complete it today."
- **Feature Discovery:** "Did you know you can chat with me? Click here to start a conversation."

**✅ Reasons:**
- Predictable output needed
- Minimal context required
- Fast (no API call)
- No risk of API failures
- Consistent tone guaranteed

---

### Use LLM GENERATION for:

**✅ Complex, nuanced coaching:**
- **Stalled Goal:** Needs empathetic questions, understanding of potential obstacles
- **Mini Win:** Requires creative suggestions for tiny first steps specific to goal type
- **Comeback:** Should acknowledge absence warmly without guilt, adapt to context
- **Balanced:** General check-in needs to synthesize multiple data points

**✅ Reasons:**
- Requires empathy and emotional intelligence
- Benefits from understanding goal/habit semantics (e.g., "Learn Spanish" vs "Get Fit" need different advice)
- Can provide varied responses (not repetitive)
- Can ask thoughtful questions based on context
- More engaging and human-like

---

### Hybrid Approach (Recommended):

**🎯 Best Practice:**
1. Use **template** for headline/title: "Goal Stalled: 'Learn Spanish'"
2. Use **LLM** for coaching message body
3. Use **hardcoded** action buttons: ["Reflect on Blockers", "Set Reminder", "Break Into Steps"]

**Example:**
```
[TEMPLATE] Title: "Your 'Learn Spanish' goal needs attention"
[LLM] Message: "You created this goal 5 days ago with big ambitions, but
haven't started yet. That's completely normal - starting is often the
hardest part. What's getting in the way? Is it finding the right app?
Not sure where to begin? Or maybe it's just not feeling urgent right now?
Let's identify the real blocker together."
[TEMPLATE] Actions: [Start Reflection] [Get Suggestions] [Dismiss]
```

This balances **speed, reliability, and personalization**.

---

### Quick Reference Table

| Card Type | Recommended Approach | Reason |
|-----------|---------------------|---------|
| **New User** | Template | Simple welcome, no context needed |
| **Urgent Deadline** | Template | Formulaic (goal + time + progress) |
| **Streak Protection** | Template | Simple celebration + reminder |
| **Stalled Goal** | LLM | Needs empathy, thoughtful questions |
| **Mini Win** | LLM | Creative tiny action suggestions |
| **Comeback** | LLM | Warm re-engagement, context-aware |
| **Feature Discovery** | Template | Tutorial-like, consistent messaging |
| **Winning** | Hybrid | Template title + LLM celebration |
| **Partial Data States** | Hybrid | Template suggestion + LLM reasoning |
| **Balanced** | LLM | Synthesize multiple data points |

**Legend:**
- **Template:** Hardcoded string with variable interpolation
- **LLM:** Claude API call with context
- **Hybrid:** Template structure + LLM content
