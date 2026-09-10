# NutriMezzo

Personal calorie, macro, and Pesaje tracker. A line of natural language is resolved to an Alimento; macros come from that Alimento, not from a fresh AI invention on every log.

## Language

**Alimento**:
A named edible whose nutrition is stored per 100 g. Created by confirming a Propuesta or by an explicit create — same object, not two species. Later matches reuse those macros scaled by Cantidad.
_Avoid_: comida (when meaning the food itself), custom (as a separate type)

**Cantidad**:
The amount of an Alimento in a log line, in grams. Typed (`100g`) or inferred at confirmation when the line has no grams (`banana chica`, `2 huevos`). A count or size in the name is not Cantidad; those grams are assumed for the whole line.
_Avoid_: porción (when meaning grams), serving size (as the stored nutrition basis), treating `2` in `2 huevos` as grams

**Renglón**:
One line inside a Comida: parsed Cantidad plus a reference to an Alimento after confirmation. Día Macros are calculated from those references; editing an Alimento recalculates the past.
_Avoid_: item, línea (as the domain object), comida (when meaning one line), snapshot of macros on the line

**Comida**:
The set of Renglones for one Momento on one Día. Another capture, or moving a Comida onto that Momento, joins it; Renglones already on it are not confirmed again.
_Avoid_: using comida for the food itself (that is Alimento), a second Comida for the same Momento on the same Día, treating a capture sitting as a separate Comida

**Día**:
A calendar date in the user's local timezone. Comidas of that date roll up against the Meta. That roll-up has a Cumplimiento when the Día has at least one Comida. A Día may also have a Pesaje; that does not create a Cumplimiento.
_Avoid_: session, log (as the accounting unit)

**Meta**:
The daily target: calories, protein, carbs, and fat. There is no per-Momento budget in the MVP.
_Avoid_: goal, presupuesto por comida, the calendar coloring of a Día (that is Cumplimiento)

**Cumplimiento**:
The judgment of a Día against the Meta as it stands now. A Día with no Comida has none. Otherwise calories are a ceiling and protein is a floor: red if kcal exceed the Meta, else yellow if protein is below the Meta, else green. Carbs and fat do not participate. Changing the Meta rejudges every Día. A Pesaje is not a Cumplimiento.
_Avoid_: a second Meta, a stored daily score, a snapshot of the Meta on that date, under-calories as a miss, using carbos or grasa to color a Día, coloring a Día from weight

**Pesaje**:
A recorded body mass in kilograms for one Día, greater than zero, to one decimal. A Día has at most one; recording again that date replaces it. Once a Día has a Pesaje, it is not cleared — only replaced. The Día may be today, past, or future. Independent of Comidas: a Día may have a Pesaje with no Comida, and vice versa. It is not Macros and not a Meta. Also the destination that shows those readings: the month cells are the mass, not a Cumplimiento color. The Promedio there is of the Semana that contains the selected Día.
_Avoid_: comida, cumplimiento, ayuno as a tracked state, treating weight as a nutrition target, a second Pesaje on the same Día, progreso, anotar, menú (as destination names), pounds, coloring a Pesaje day as Cumplimiento, deleting a Pesaje back to none, treating a future Pesaje as a Meta, zero or negative as a Pesaje

**Semana**:
Monday through Sunday in the user's local timezone — the same week the month calendar uses. It may span two months; a Promedio is not clipped to the displayed month. A Promedio is always of this window, never a rolling seven Días ending today.
_Avoid_: week starting Sunday, last 7 days, ISO week as a different object, clipping a Semana to one calendar month

**Promedio**:
The arithmetic mean of the Pesajes recorded in one Semana. A Semana with no Pesaje has none. Días without a Pesaje are omitted, not zero. Compared to the previous Semana only when both have a Promedio: a drop is down (green), a rise is up (red), a tie has no arrow. There is no Meta of weight.
_Avoid_: filling gaps with zero, comparing to a rolling 7-day mean, treating Promedio as Cumplimiento, a Meta of weight, inventing an arrow when the previous Semana has no Promedio

**Momento**:
The slot a Comida occupies on a Día (desayuno, almuerzo, cena, extra). A Día has at most one Comida per Momento. Not a nutrition target.
_Avoid_: meal (as a budget), comida (when meaning the slot), a second Momento of the same name on the same Día

**Macros**:
Calories, protein, carbs, and fat. That is the only nutrition this context tracks.
_Avoid_: nutrients, micros (fiber, sugar, vitamins) as if they were in scope

**Patrón**:
The pattern on an Alimento that matches the name part of a Renglón, not the Cantidad. Derived from the Alimento name by default (normalized words); regex is an optional later edit. Among local hits, the most specific Patrón wins; ties go to the most recently used Alimento.
_Avoid_: treating regex as a numeric score (“más regex”)

**Propuesta**:
One candidate Alimento shown for a Renglón at confirmation. Slot 1 is the best local match when any Patrón hits; slot 2 is the best AI suggestion. If nothing local matches, both slots can be AI. AI is optional: with no usable model, unmatched Renglones offer create-Alimento instead of an AI slot.
_Avoid_: resultado, opción (as the domain object)

**Cumplimiento**:
The judgment of a Día against the Meta as it stands now, shown as the month calendar of Días. A Día with no Comida has none. Calories are a ceiling; protein is a floor; carbs and fat do not participate. Changing the Meta rejudges every Día. Tapping a day in Cumplimiento opens that Día. Tapping a day in Pesaje selects it and stays on Pesaje. The selected Día is shared across Día, Cumplimiento, and Pesaje. UI copy for the destinations is Día, Cumplimiento, and Pesaje.
_Avoid_: progreso, anotar (as destination names), menú (as a screen), a second Meta, goal log, stored daily score
