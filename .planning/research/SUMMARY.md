# Research Summary: Drinky Drinky v1.5 Charts

**Researched:** 2026-06-16
**Milestone:** v1.5 Charts (monthly bar chart + day detail screen)
**Confidence:** HIGH

---

## Stack Additions

`fl_chart: ^1.2.0` è l'**unica nuova dipendenza**. Nessun conflitto — richiede Flutter >= 3.27.4, il progetto è su 3.44.1. Nessuna code generation richiesta.

```yaml
# pubspec.yaml — unica aggiunta
fl_chart: ^1.2.0
```

Lo stack esistente già fornisce tutto il resto: `intl` per i label, Riverpod family providers, stream Drift.

---

## Feature Table Stakes

### Monthly Bar Chart (embedded in HistoryScreen)

| Feature | Note implementativa |
|---------|---------------------|
| Una barra per giorno, colore verde/primario | Riutilizza logica `_findActiveTarget()` del calendario |
| Linea orizzontale dashed per il target | `ExtraLinesData → HorizontalLine(y: targetMl, dashArray: [8,4])` |
| Label asse X: giorni 1, 5, 10, 15, 20, 25, ultimo | 31 label overflow su mobile |
| Label asse Y in ml, `reservedSize: 40` | Valori a 4 cifre clippano col default 22 |
| Touch tooltip con ml esatti | `handleBuiltInTouches: true` — mai `showingTooltipIndicators` (bug crash) |
| Empty state se mese senza dati | `if (monthTotals.isEmpty)` → mostra widget testuale, non il chart |
| Giorni futuri assenti (solo mese corrente) | Genera barre solo per giorni <= oggi |
| Sincronizzato con `focusedMonthProvider` | Mai aggiungere stato mese separato per il chart |
| Dark mode via `Theme.of(context).colorScheme` | |

Differentiator a basso costo: angoli arrotondati, tap barra → naviga al day detail.

### Day Detail Screen (nuova schermata push)

| Feature | Note implementativa |
|---------|---------------------|
| Una barra per entry, x=index, y=amountMl | Index-based evita sovrapposizioni tra entry nello stesso orario |
| Label asse X: HH:mm da `loggedAt` | `DateFormat.Hm()` da `intl` |
| Testo "Totale: X ml" | Somma di tutte le entry |
| Touch tooltip con ml + orario | `getTooltipItem` callback |
| Empty state per giorni senza entry | |
| AppBar con data formattata, back navigation | |

### Defer

Background bars per target per-giorno, label testo sopra le barre, gradienti colore, accessibilità semantica.

---

## Architecture

**Nessun lavoro sul data layer.** Zero nuovi Drift query, DAO, repository o Riverpod provider.

**Provider esistenti già pronti (zero modifiche):**

| Provider | Ritorna | Usato da |
|----------|---------|----------|
| `calendarMonthProvider(year, month)` | `Stream<Map<String, int>>` | Monthly bar chart |
| `waterEntriesForDateProvider(dateKey)` | `Stream<List<WaterEntryEntity>>` | Day detail chart |
| `allTargetHistoryProvider` | `Stream<List<TargetHistoryEntry>>` | Linea target mensile |
| `focusedMonthProvider` | `DateTime` | Mese visualizzato nel chart |

**Build order:**

1. `pubspec.yaml` — aggiungi `fl_chart: ^1.2.0`
2. `lib/presentation/widgets/monthly_bar_chart.dart` — widget stateless, dati via costruttore
3. `lib/presentation/screens/history_screen.dart` — embedding chart, `onDaySelected` naviga al detail
4. `lib/presentation/screens/day_detail_screen.dart` — ConsumerWidget, riceve `dateKey` da GoRouter
5. `lib/core/router/app_router.dart` — child route `GoRoute(path: 'day/:dateKey')` sotto `/history`
6. ARB files (4 lingue) — stringhe chart: empty state, tooltip, titolo, totale

**File NON toccati:** data layer completo (DAO, repository, database, providers).

---

## Watch Out For

1. **`maxY` sempre esplicito** (Critico). Dati vuoti → `maxY = 0` → chart bianco silenzioso. Impostare `maxY: max(actualMax, dailyTarget) * 1.1`. Se `monthTotals.isEmpty` → empty state widget, no chart.

2. **Artefatti animazione al cambio mese** (Critico). Lerp tra 28→31 giorni causa barre animate sugli x sbagliati. Soluzione: `ValueKey('$year-$month')` su `BarChart`.

3. **Mai `showingTooltipIndicators`** (Critico). Bug #1911 confermato: se lo stream aggiorna e un indice pinnato non esiste, crash durante paint. Usare solo `handleBuiltInTouches: true`.

4. **Altezza bounded** (Critico). `BarChart` in `Column` senza bounds → assertion Flutter. Wrappare in `SizedBox(height: 200)` o `AspectRatio(aspectRatio: 1.8)`.

5. **Route day detail come child di `/history`** (Critico). Route top-level rompe lo stack del tab. Path param, non `state.extra`.

6. **`reservedSize: 40` su asse Y** (Moderato). Valori a 4 cifre clippa col default 22.

7. **Tooltip ml localizzato** (Moderato). `getTooltipItem` non ha `BuildContext`. Passare `NumberFormat` dal `build` method del parent.

---

*Research completed: 2026-06-16 | Ready for roadmap: sì*
