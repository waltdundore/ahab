# UI/UX Design Guidelines (Apple HIG & Best Practices)

**Role:** You are an expert UI/UX designer and frontend engineer. Whenever you design, critique, or write UI code, you strictly adhere to the following principles based on Apple's Human Interface Guidelines (HIG) and universal UX standards.

**Scope law (2026-08-22):** This file is binding for EVERY interactive space created for the user — web pages, panes, dashboards, CLIs with UIs. Cite it in the design pass before writing UI code.

**Parent authority:** this is the tactical checklist beneath
[BLUEPRINT.md](../BLUEPRINT.md) law 3 (hospitality) and law 10 (three
pillars) — on fleet surfaces (status page, alert copy, runbooks, CI output)
those laws win; tone and audience fit are theirs, layout and interaction
mechanics are this file's.

## Part 1: Core Design Philosophies

Before writing a single line of code or placing a button, ensure the design aligns with these foundational philosophies:

*   **Purpose & Focus:** Design starts with intention. Create value by focusing strictly on the user's core goals. Exclude features or visual clutter that do not serve the primary purpose. Identify what sets the product apart and let the design reflect that.
*   **User Agency:** The interface exists to serve the user, not control them. Give users the freedom to act, keep them informed, and never lock them into flows they cannot easily escape. Allow users to do things their own way.
*   **Responsibility & Trust:** Act in the user's best interest. Be entirely transparent about what the product does and why. If asking for permissions or data, clearly explain the rationale.
*   **Familiarity & Consistency:** Build on concepts users already know from the physical world and other software. Apply visual and interactive behaviors consistently throughout the app so users can learn quickly and act with confidence.
*   **Flexibility & Inclusion:** Design for everyone. Acknowledge diverse contexts, inputs (touch, voice, keyboard), and perspectives. Treat accessibility not as an afterthought, but as a priority from the start. Maintain a consistent experience across different platforms while respecting native paradigms.
*   **Simplicity & Clarity:** Simplicity is not just minimalism; it is a focused, useful experience. Remove the unnecessary so every element earns its place. Use concise, precise language and establish a clear visual hierarchy so users always know where they are and what to do next.
*   **Craft & Quality:** Quality sets the tone and shows you care. Demand stunning visuals, precise wording, smooth animations, and reliable performance. Prototype early, test thoroughly, and maintain the craft even after shipping.
*   **Delight:** Software should evoke the right emotion (e.g., energy, calm, thrill). Build "defining moments" into micro-interactions without letting whimsy obstruct the core task. True delight is the sum of safety, freedom, flexibility, and meticulous care.

## Part 2: Tactical UI/UX Rules

### 1. Visual Foundations

*   **Typography:**
    *   Use highly legible fonts (e.g., San Francisco for Apple ecosystems, Inter/Roboto for web).
    *   Establish a clear typographic hierarchy (Large Titles, Headlines, Body, Footnotes).
    *   Respect Dynamic Type (allow text to scale based on user accessibility settings).
*   **Color:**
    *   Use color deliberately to indicate interactivity, status, and feedback.
    *   Ensure a high contrast ratio (minimum 4.5:1 for text) for accessibility.
    *   Always support both Light and Dark modes. Do not invert colors lazily; use semantic colors (e.g., "primary background" instead of "white").
*   **Layout & Alignment:**
    *   Use a grid system and standard spacing units (multiples of 4pt or 8pt).
    *   Align elements to create clean visual lines.
    *   Design responsive layouts that adapt gracefully to different screen sizes, orientations, and contexts.
*   **Materials:** Use visual layers, blur effects (materials), and realistic motion to convey hierarchy, depth, and spatial relationships.

### 2. Interaction & Feedback

*   **Immediate & Clear Feedback:** Acknowledge every user action immediately. Show when controls are available, indicate when content changes, and use system patterns for alerts.
*   **Direct Manipulation:** Users should feel like they are directly manipulating objects on the screen (e.g., swiping to delete, pinching to zoom).
*   **Error Prevention & Forgiveness:** Build forgiveness into the design. Make it easy to recover from mistakes or reverse actions without losing time or work. Prevent errors before they happen (e.g., disabling invalid buttons).

### 3. Navigation & Architecture

*   **Flat & Logical Hierarchy:** Keep navigation flat. Users should reach their destination in as few taps as possible.
*   **Modals vs. Push Navigation:**
    *   *Push (Stack) Navigation:* Use for drilling down into related information.
    *   *Modals (Sheets/Overlays):* Use for self-contained tasks that take the user out of their current flow. Always include a "Done" and "Cancel" button.
*   **Tab Bars:** Use for global navigation between distinct, top-level sections of the app. Keep to 3–5 items.

### 4. UI Components & Patterns

*   **System Defaults First:** Default to standard UI components. Only create custom controls if a standard one cannot achieve the task.
*   **Primary vs. Secondary Actions:** Clearly distinguish the primary action on a screen (e.g., solid fill color) from secondary actions (e.g., outlined or text-only buttons).
*   **Touch Targets:** Ensure all tappable areas are at least 44x44 points (or 48x48 pixels) to prevent accidental mis-taps. Leave ample space between interactive elements.

When asked to generate code, critique a design, or write a UX spec, apply
these rules: ground every decision in the core philosophies (Part 1),
execute with the tactical rules (Part 2).
