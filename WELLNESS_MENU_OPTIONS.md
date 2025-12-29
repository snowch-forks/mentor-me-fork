# Wellness Menu Home Page Placement Options

This document shows 3 different ways to add the wellness menu to the home page (Mentor Screen).

## Created Files

✅ **`lib/widgets/wellness_menu_widget.dart`** - Reusable wellness menu with collapsible sections

---

## Option A: Fixed Position (After Action Buttons) ⭐ RECOMMENDED

**Pros:**
- Always visible and accessible
- Simple implementation
- Users always know where to find it
- No configuration needed

**Cons:**
- Can't be hidden or reordered
- Adds length to home screen

**Visual Layout:**
```
┌─────────────────────────────────────┐
│ [Mentor Coaching Card]              │
├─────────────────────────────────────┤
│ [Chat] [Deep Reflection]            │
├─────────────────────────────────────┤
│ ✨ WELLNESS TOOLS (new section)     │
│ ┌─ Crisis Support (always visible) ─┐│
│ │ • Get Help Now                   ││
│ │ • Safety Plan                    ││
│ └─────────────────────────────────┘ │
│ ▶ Clinical Tools (collapsed)        │
│ ▶ Cognitive Techniques (collapsed)  │
│ ▶ Wellness Practices (9) (collapsed)│
│ ▼ Physical Wellness (expanded)      │
│   • Weight Tracking                 │
│   • Food Log                        │
│   • Fasting Tracker                 │
│   • Exercise Tracking               │
│ ▶ Health Tracking (collapsed)       │
│ ▶ Insights & Progress (collapsed)   │
├─────────────────────────────────────┤
│ [Dashboard Widgets: Hydration, etc.]│
│ [Customize Dashboard]               │
└─────────────────────────────────────┘
```

**Implementation:**

File: `lib/screens/mentor_screen.dart`

### Step 1: Add import at top
```dart
import '../widgets/wellness_menu_widget.dart';
```

### Step 2: Find the build method (around line 688)
Look for this code:
```dart
} else {
  // Standard list layout
  for (final config in layout.visibleWidgets) {
    final widget = _buildWidgetById(
```

### Step 3: Add wellness menu before the loop
Replace the `} else {` section with:
```dart
} else {
  // Standard list layout

  // WELLNESS MENU - Add after action buttons, before dashboard widgets
  bool wellnessMenuAdded = false;

  for (final config in layout.visibleWidgets) {
    // Add wellness menu right after action buttons
    if (config.id == 'actionButtons' && !wellnessMenuAdded) {
      final widget = _buildWidgetById(
        config.id,
        context,
        goalProvider,
        habitProvider,
        journalProvider,
      );
      if (widget != null) {
        widgets.add(widget);
        widgets.add(AppSpacing.gapLg);
      }

      // Add wellness menu here
      widgets.add(const WellnessMenuWidget(
        showHeader: true,
        showHelpMeChoose: false,
      ));
      widgets.add(AppSpacing.gapLg);

      wellnessMenuAdded = true;
      continue; // Skip the normal widget add below
    }

    final widget = _buildWidgetById(
      config.id,
      context,
      goalProvider,
      habitProvider,
      journalProvider,
    );
    if (widget != null) {
      widgets.add(widget);
      widgets.add(AppSpacing.gapLg);
    }
  }
}
```

---

## Option B: Customizable Dashboard Widget (User Can Reorder)

**Pros:**
- Users can show/hide the wellness menu
- Users can reorder it with other widgets
- Fits existing dashboard customization pattern
- More flexible

**Cons:**
- Users might hide it and forget about it
- Requires adding to dashboard configuration
- More complex implementation

**Visual Layout:**
```
User can drag to reorder:
┌─────────────────────────────────────┐
│ [Mentor Coaching Card]              │
│ [Chat] [Deep Reflection]            │
│ [Quick HALT Check]        ← User can│
│ [Recent Wins]              reorder  │
│ [Wellness Tools] ← NEW     these    │
│ [Hydration]                         │
│ [Weight Tracker]                    │
│ [Customize Dashboard]               │
└─────────────────────────────────────┘
```

**Implementation:**

### Step 1: Add to dashboard configuration

File: `lib/models/dashboard_config.dart`

Find `defaultWidgets` list and add:
```dart
static const List<WidgetConfig> defaultWidgets = [
  WidgetConfig(id: 'mentorCard', title: 'Mentor Card', isVisible: true),
  WidgetConfig(id: 'actionButtons', title: 'Action Buttons', isVisible: true),

  // ADD THIS LINE:
  WidgetConfig(id: 'wellnessMenu', title: 'Wellness Tools', isVisible: true),

  WidgetConfig(id: 'quickHalt', title: 'Quick HALT Check', isVisible: true),
  // ... rest of widgets
];
```

### Step 2: Add to widget builder

File: `lib/screens/mentor_screen.dart`

In `_buildWidgetById` method (around line 817), add this case:
```dart
Widget? _buildWidgetById(
  String id,
  BuildContext context,
  GoalProvider goalProvider,
  HabitProvider habitProvider,
  JournalProvider journalProvider,
) {
  switch (id) {
    case 'mentorCard':
      return _buildMentorCoachingCard(/* ... */);
    case 'actionButtons':
      return _buildActionButtons(context);

    // ADD THIS CASE:
    case 'wellnessMenu':
      return const WellnessMenuWidget(
        showHeader: true,
        showHelpMeChoose: false,
      );

    case 'quickHalt':
      return const QuickHaltWidget();
    // ... rest of cases
  }
}
```

### Step 3: Add import at top
```dart
import '../widgets/wellness_menu_widget.dart';
```

**Result:** Users can now show/hide and reorder the wellness menu via "Customize Dashboard" button.

---

## Option C: Collapsible Card (Minimal Visual Impact)

**Pros:**
- Minimal visual clutter when collapsed
- Users can expand when needed
- Takes up very little space
- Clean design

**Cons:**
- Less discoverable (users might not notice it)
- Extra tap to access tools
- Nested collapsibles (wellness card → individual sections)

**Visual Layout:**
```
┌─────────────────────────────────────┐
│ [Mentor Coaching Card]              │
├─────────────────────────────────────┤
│ [Chat] [Deep Reflection]            │
├─────────────────────────────────────┤
│ ▶ Wellness Tools (18+) ← Collapsed  │  ← NEW: Single expandable card
├─────────────────────────────────────┤
│ [Dashboard Widgets...]              │
└─────────────────────────────────────┘

When expanded:
┌─────────────────────────────────────┐
│ ▼ Wellness Tools (18+)              │
│   ┌─ Crisis Support ─┐              │
│   │ • Get Help Now   │              │
│   └──────────────────┘              │
│   ▶ Clinical Tools (1)              │
│   ▶ Cognitive Techniques (4)        │
│   ▼ Physical Wellness (expanded)    │
│     • Weight Tracking               │
│     • Food Log                      │
│     ...                             │
└─────────────────────────────────────┘
```

**Implementation:**

File: `lib/screens/mentor_screen.dart`

### Step 1: Add import
```dart
import '../widgets/wellness_menu_widget.dart';
```

### Step 2: Create a collapsible card wrapper method
Add this method after `_buildActionButtons`:
```dart
/// Build collapsible wellness tools card
Widget _buildWellnessToolsCard(BuildContext context) {
  return Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(
          Icons.spa,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Row(
          children: [
            Text(
              'Wellness Tools',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '18+',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Evidence-based practices for mental health',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: WellnessMenuWidget(
              showHeader: false, // Hide header since card title shows it
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Step 3: Add to layout (same as Option A)
```dart
} else {
  // Standard list layout
  bool wellnessCardAdded = false;

  for (final config in layout.visibleWidgets) {
    // Add wellness card right after action buttons
    if (config.id == 'actionButtons' && !wellnessCardAdded) {
      final widget = _buildWidgetById(/* ... */);
      if (widget != null) {
        widgets.add(widget);
        widgets.add(AppSpacing.gapLg);
      }

      // Add collapsible wellness card
      widgets.add(_buildWellnessToolsCard(context));
      widgets.add(AppSpacing.gapLg);

      wellnessCardAdded = true;
      continue;
    }

    // ... rest of loop
  }
}
```

---

## Comparison Table

| Feature | Option A: Fixed | Option B: Customizable | Option C: Collapsible |
|---------|----------------|----------------------|---------------------|
| **Visibility** | Always visible | User controls | Collapsed by default |
| **Discoverability** | ⭐⭐⭐ High | ⭐⭐ Medium | ⭐ Low |
| **Space Usage** | Most space | Medium space | Minimal space |
| **User Control** | None | Full control | Expand/collapse only |
| **Implementation** | Simple | Medium | Simple |
| **Fits Pattern** | New pattern | ✅ Existing pattern | New pattern |
| **Best For** | Users who use wellness tools frequently | Power users who customize | Minimalist users |

---

## Recommended Approach: **Option A (Fixed Position)** ⭐

**Why:**
1. ✅ **High discoverability** - Users will immediately see wellness tools
2. ✅ **Simple implementation** - Just add the widget in one place
3. ✅ **No configuration needed** - Works out of the box
4. ✅ **Consistent experience** - All users see the same thing
5. ✅ **Physical Wellness expanded by default** - Most-used section is visible

**When users might prefer other options:**
- **Option B** if your users are power users who customize everything
- **Option C** if home screen is already cluttered and you want minimal impact

---

## Implementation Steps (Option A)

1. ✅ Created `lib/widgets/wellness_menu_widget.dart`
2. Add import to `lib/screens/mentor_screen.dart`:
   ```dart
   import '../widgets/wellness_menu_widget.dart';
   ```
3. Add wellness menu after action buttons (see Step 3 in Option A above)
4. Test the implementation

---

## Testing Checklist

After implementing, test:
- [ ] Wellness menu appears after action buttons
- [ ] Crisis Support section is always visible
- [ ] Physical Wellness section is expanded by default
- [ ] Other sections are collapsed by default
- [ ] Tapping sections expands/collapses them
- [ ] Section states are saved (persist across app restarts)
- [ ] All wellness tools navigate correctly
- [ ] Home screen scrolls smoothly with wellness menu
- [ ] Bottom nav bar doesn't obscure content (add extra padding if needed)

---

## Next Steps

1. Choose which option you want (A, B, or C)
2. I'll implement it for you
3. We'll test it together
4. Adjust styling/positioning as needed

Which option would you like to try first? I recommend **Option A** for maximum visibility and ease of use.
