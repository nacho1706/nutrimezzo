# NutriMezzo

Personal calorie and macro tracker. A line of natural language is resolved to an Alimento; macros come from that Alimento, not from a fresh AI invention on every log.

## Language

**Alimento**:
A named edible whose nutrition is stored per 100 g. Created by confirming a Propuesta or by an explicit create — same object, not two species. Later matches reuse those macros scaled by Cantidad.
_Avoid_: comida (when meaning the food itself), custom (as a separate type)

**Cantidad**:
The amount of an Alimento in a log line, in grams. Typed (`100g`) or inferred at confirmation when the line has no grams (`banana chica`).
_Avoid_: porción (when meaning grams), serving size (as the stored nutrition basis)

**Renglón**:
One line inside a Comida: parsed Cantidad plus a reference to an Alimento after confirmation. Día Macros are calculated from those references; editing an Alimento recalculates the past.
_Avoid_: item, línea (as the domain object), comida (when meaning one line), snapshot of macros on the line

**Comida**:
A set of Renglones captured together in one notes-style list, submitted as a whole before confirmation. Belongs to one Día and may carry a Momento.
_Avoid_: using comida for the food itself (that is Alimento)

**Día**:
A calendar date in the user's local timezone. Comidas of that date roll up against the Meta.
_Avoid_: session, log (as the accounting unit)

**Meta**:
The daily target: calories, protein, carbs, and fat. There is no per-Momento budget in the MVP.
_Avoid_: goal, presupuesto por comida

**Momento**:
A label on a Comida for grouping (desayuno, almuerzo, cena, extra). Not a nutrition target.
_Avoid_: meal (as a budget), comida (when meaning the slot)

**Macros**:
Calories, protein, carbs, and fat. That is the only nutrition this context tracks.
_Avoid_: nutrients, micros (fiber, sugar, vitamins) as if they were in scope

**Patrón**:
The pattern on an Alimento that matches the name part of a Renglón, not the Cantidad. Derived from the Alimento name by default (normalized words); regex is an optional later edit. Among local hits, the most specific Patrón wins; ties go to the most recently used Alimento.
_Avoid_: treating regex as a numeric score (“más regex”)

**Propuesta**:
One candidate Alimento shown for a Renglón at confirmation. Slot 1 is the best local match when any Patrón hits; slot 2 is the best AI suggestion. If nothing local matches, both slots can be AI. AI is optional: with no usable model, unmatched Renglones offer create-Alimento instead of an AI slot.
_Avoid_: resultado, opción (as the domain object)
