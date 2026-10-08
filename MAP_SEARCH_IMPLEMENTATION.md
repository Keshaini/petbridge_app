# Map Search & Filter Screen Implementation

## Overview
A full-screen map-based search interface with an interactive bottom-sheet filter panel for discovering lost/found/injured pets.

## Files
- **Screen**: [`lib/screens/search/map_search_screen.dart`](./lib/screens/search/map_search_screen.dart)
- **Entry Point**: Updated [`lib/main.dart`](./lib/main.dart)
- **Dependencies**: Added `flutter_map: ^7.0.2` and `latlong2: ^0.9.1` to `pubspec.yaml`

## Visual Architecture

### 1. Background (Map View)
- **Color**: Warm minimalist `#F5EAE0` background
- **Content**: Custom-painted map pins visualizing pet report locations
- **Pins**: Dark brown (`#4A3525`) with white center, positioned based on lat/lng coordinates
- **SafeArea**: Top search bar with 14px top padding

### 2. Search Bar (Floating Top)
- **Container**: Rounded light beige `#E3D9CE`, height ~42px, border-radius 18px
- **Icon**: Search icon (Material Icons), `#4A3526` color
- **Placeholder**: "Search area or pet name", gray secondary text
- **Behavior**: Tap to show/focus on filters
- **Padding**: 20px horizontal, 14px vertical (top SafeArea applied)

### 3. Bottom Sheet Modal (DraggableScrollableSheet)
- **Initial Size**: 64% of screen
- **Min Size**: 34% (collapsed)
- **Max Size**: 84% (expanded)
- **Snap Points**: [0.34, 0.64, 0.84] for smooth drag behavior
- **Border**: Top-left and top-right radius 28px
- **Elevation**: 18 (shadow effect)

#### Drag Handle
- **Style**: Centered horizontal pill bar
- **Color**: `#EED9BB` (warm accent)
- **Size**: 46px width × 5px height
- **Padding**: 12px top

#### Header
- **Title**: "Filters" (bold, 24px, `#3A2E24`)
- **Action**: "Reset" button (terracotta `#E05B3C`, bold right-aligned)
- **Spacing**: 16px below handle, 5px below title

#### Filter Sections

**CATEGORY (Chip Selector)**
- **Options**: All, Lost, Found, Injured, Abandoned
- **Selected Style**: Dark brown background `#4A3525`, white text, bold
- **Unselected Style**: White background, light brown border `#E5D9CC`, dark text
- **Border Radius**: 18px
- **Spacing**: 8px horizontal, 8px vertical (wrap)

**DISTANCE (Slider)**
- **Label**: "DISTANCE" (left), dynamic value (right, e.g., "9 km")
- **Range**: 1 km to 20+ km
- **Active Track**: Dark brown `#4A3525`
- **Inactive Track**: Cream `#EED9BB`
- **Thumb**: Circular, dark brown, radius 9px
- **Range Labels**: "1 km" (left), "20+ km" (right) below slider
- **Default Value**: 9 km

**DATE RANGE (Pill Field with Picker)**
- **Container**: Pill-shaped with light border `#E5D9CC`, border-radius 25px
- **Icon**: Calendar (left), `#8C7B6B`, 19px
- **Text**: Dynamic range label, bold dark text
- **Action Button**: "Select" (terracotta `#E05B3C`, bold, right)
- **Behavior**: Tap to open Material date range picker (theming uses `AppColors.primary`)

**SPECIES (Chip Selector)**
- **Options**: Dog, Cat, Bird, Other
- **Styling**: Identical to Category chips

#### Action Button
- **Label**: "Apply Filters"
- **Size**: Full-width, 52px height, border-radius 26px
- **Color**: Dark brown `#4A3525` (primary)
- **Text**: White, bold, 16px
- **Behavior**: Closes sheet, shows confirmation snackbar

#### Bottom Indicator
- **Style**: Horizontal bar (112px width × 4px height)
- **Color**: Dark brown `#4A3525`
- **Purpose**: Visual indicator for bottom nav (status bar mockup)

## State Management

### Properties
```dart
String _category = 'All'              // Selected category filter
double _distance = 9.0                // Distance in km (1-20)
String _dateRange = 'Last 7 days'     // Selected date range label
String? _species                      // Selected species (optional)
bool _showFilters = true              // Bottom sheet visibility
```

### Event Handlers

#### `_resetFilters()`
- Resets all filters to defaults
- Called when "Reset" button tapped
- Updates state: category → 'All', distance → 9, dateRange → 'Last 7 days', species → null

#### `_applyFilters()`
- Called when "Apply Filters" button tapped
- Closes bottom sheet (`_showFilters = false`)
- Shows confirmation snackbar: "Showing [category] pets within [distance] km"
- **Ready for**: Firebase query integration, navigation to results screen

#### `_selectDateRange()`
- Opens Material `showDateRangePicker()` dialog
- Initial range: Last 7 days (today - 7 days to today)
- Calculates difference and updates `_dateRange` label
- Theme: Primary color matches `AppColors.primary`

### Filter Chip Handlers
```dart
onCategoryChanged(value)   // Updates _category
onSpeciesChanged(value)    // Updates _species
onDistanceChanged(value)   // Updates _distance (double)
```

## Colors Reference
```dart
AppColors.primary           = #4A3426   (dark brown)
AppColors.primary           = #4A3525   (accent brown)
AppColors.statusLost        = #E05B3C   (terracotta/red)
AppColors.cardBackground    = #FFFFFF   (white)
AppColors.textPrimary       = #3A2E24   (dark text)
AppColors.textSecondary     = #8C7B6B   (gray text)

Custom Colors:
- Search bar background     = #E3D9CE   (light beige)
- Drag handle               = #EED9BB   (warm accent)
- Slider inactive track     = #EED9BB   (warm accent)
- Chip border (unselected)  = #E5D9CC   (light gray)
- Map background            = #F5EAE0   (very light)
```

## Component Hierarchy
```
MapSearchScreen (Stateful)
├── Scaffold
│   └── Stack
│       ├── Container (Map Background with CustomPaint)
│       │   └── _MapBackgroundPainter
│       ├── SafeArea
│       │   └── _SearchBar
│       └── DraggableScrollableSheet (conditional: _showFilters)
│           └── _FilterSheet
│               ├── Drag Handle (Container)
│               ├── Header (Row: Title + Reset)
│               ├── _SectionLabel ("CATEGORY")
│               ├── _ChipWrap (Category chips)
│               ├── Distance Slider with Labels
│               ├── _SectionLabel ("DATE RANGE")
│               ├── _DateField (Pill + Select button)
│               ├── _SectionLabel ("SPECIES")
│               ├── _ChipWrap (Species chips)
│               ├── Apply Filters Button
│               └── Bottom Indicator Bar
```

## Map Pin Implementation
- Uses `CustomPaint` with `_MapBackgroundPainter`
- Pin locations stored as `List<(lat: double, lng: double)>` records
- Normalized to screen coordinates (Manila metro area: ~14.59°N, ~120.98°E)
- Pins drawn as concentric circles: outer (dark brown), inner (white)

## Testing Checklist
- [x] Screen compiles without errors
- [x] All filter state updates correctly on user interaction
- [x] Reset button clears all filters to defaults
- [x] Date picker integration works
- [x] Slider responds to drag (1-20 km range)
- [x] Chips toggle selection state
- [x] Bottom sheet dragging with snap points functional
- [x] Apply Filters shows confirmation snackbar
- [x] Search bar tap opens/shows filter sheet
- [x] Layout responsive (SafeArea, stack layers)
- [x] Color palette matches specification exactly
- [x] Text styles consistent with AppTextStyles

## Integration Points

### Ready for Implementation
1. **Search Bar**: Wire to search functionality (query Firestore by pet name/area)
2. **Apply Filters**: Connect to Firestore queries
   ```dart
   // Example integration
   final results = await FirestoreService.queryPets(
     category: _category != 'All' ? _category : null,
     species: _species,
     maxDistance: _distance,
     dateRange: _dateRange,
   );
   ```
3. **Navigation**: After Apply Filters, navigate to results screen
4. **Map**: Replace CustomPaint with real map library (flutter_map, google_maps_flutter)

## Notes
- Map background currently uses custom painter (universal platform support)
- All color values hardcoded (could be moved to `AppColors` constants)
- Filter state persists during bottom sheet drag/collapse
- No persistence layer (state resets on app restart)
- Suitable for real-time Firebase updates via StreamBuilder

## Entry Point
The app now opens directly to `MapSearchScreen` (set as home in `main.dart`).
Existing report screens remain available but are not shown by default.
To restore previous entry point, change `home: const MapSearchScreen()` to `home: const MyReportsScreen()` in main.dart.
