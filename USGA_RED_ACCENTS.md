# USGA Red Accent Integration

## Overview
Added USGA red accents to the Eagle Match app to better reflect the official USGA branding. The red color (#CC2936) is now used strategically throughout the app to highlight important actions and provide visual hierarchy.

## Red Accent Colors Added
- **Primary Red**: `#CC2936` (USGATheme.accentRed)
- **Light Red**: `#E8384F` (USGATheme.lightRed)

## Where Red Accents Are Used

### 1. Navigation
- **Bottom Navigation Bar**: Selected tab icons use red accent color
- **Unselected tabs**: Use USGA light text color for consistency

### 2. Action Buttons
- **Create Match Button**: Primary red background for the main CTA
- **Request to Join Button**: Red background to encourage action
- **Link a Player Button**: Red background for primary duo action

### 3. Destructive/Decline Actions
- **Logout Button**: Red icon in account menu
- **Logout Confirmation**: Red "Logout" button in dialog
- **Decline Request**: Red outlined button for declining match requests

### 4. Theme Helper Methods
Added utility methods to USGATheme class:
- `redActionButton()`: Creates red-styled action buttons
- `errorContainer()`: Red-themed error/alert containers
- `redChip()`: Red accent chips/badges

## Design Philosophy
The red is used strategically to:
- **Highlight primary actions** (Create Match, Join Match)
- **Indicate destructive actions** (Logout, Decline)
- **Draw attention** to important interactive elements
- **Maintain USGA brand consistency**

## Color Balance
The red accents complement the existing USGA color palette:
- **Navy Blue**: Primary brand color for headers, main buttons
- **Gold**: Accent color for highlights and special elements  
- **Red**: Action color for CTAs and important interactions
- **White/Off-white**: Clean backgrounds and cards
- **Light Gray**: Subtle text and borders

This creates a balanced, professional look that maintains the USGA's authoritative golf aesthetic while improving user engagement through strategic use of the brand's red accent color.
