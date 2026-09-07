# Where Is Superstore Losing Money? An Excel-to-SQL Profitability Diagnostic

**Tools:** Excel (PivotTables, PivotCharts) &middot; MySQL / MySQL Workbench (data cleaning, aggregate queries, CASE, GROUP BY / HAVING)
**Dataset:** Sample Superstore order-level data (region, category, sub-category, sales, profit, discount)

## The problem

Revenue and profit are not the same thing, and a dataset with sales, profit, and discount fields for every order is exactly the kind of place that difference hides. I set out to answer a simple question — *where is this business actually losing money, and why* — using a two-stage approach: fast exploratory analysis in Excel to find where to look, then row-level SQL queries to confirm (or correct) what the exploration suggested.

## Stage 1 — Exploratory analysis in Excel

I built four PivotTables against the raw order data:

1. **Revenue and profit by Region and Category** — to separate "big" from "profitable"
2. **Monthly sales trend** — to rule out a decline story before looking for other explanations
3. **Profit by discount level** (total and average) — to check whether discounting was eroding margin
4. **Sub-categories sorted by profit, worst first** — to find the specific product lines responsible

This surfaced the first real signal: **Furniture generated nearly as much revenue as Technology, but a fraction of the profit**, and **Central was the weakest-margin region despite not having the lowest sales** — the opposite pattern you'd expect if the issue were simply market size. The discount pivot hinted at a tipping point where profit turned negative, and the sub-category pivot pointed at Tables and Bookcases as the likely cause.

At this stage, the working hypothesis was: *Central's weak margin comes from over-discounted Furniture, specifically Tables and Bookcases.*

## Stage 2 — Cleaning the data for SQL

Importing the same CSV into MySQL Workbench exposed problems Excel's pivot engine had silently tolerated:

- The `Profit` column imported as `TEXT`, not numeric — a stray currency symbol (rendering as a mangled `?` character due to an encoding mismatch) was blocking every row from being read as a number. Diagnosed with a regex filter (`NOT REGEXP '^-?[0-9]+\.?[0-9]*$'`) to isolate the malformed rows, cleaned with `REPLACE`/`TRIM`, then converted with `ALTER TABLE ... MODIFY COLUMN`.
- `Order Date` and `Ship Date` also imported as text, and the initial assumed date format (`MM-DD-YYYY`) turned out to be wrong — a failed `STR_TO_DATE` conversion on a value like `15-04-2015` proved the day and month were transposed, revealing the real format as `DD-MM-YYYY`. Corrected the format string and re-ran the conversion before the `ALTER TABLE` succeeded.

This stage mattered as much as the analysis itself: a pivot table will happily sum a text column that *looks* numeric, but SQL won't, and that difference is exactly what caught a data quality issue that would otherwise have gone unnoticed.

## Stage 3 — Confirming (and correcting) the hypothesis in SQL

With clean data, I rebuilt each pivot as a query and then went one level deeper than the Excel view could easily go:

```sql
SELECT Region, `Sub-Category`,
       COUNT(*)      AS n_orders,
       AVG(Discount) AS avg_discount,
       SUM(profit)   AS total_profit
FROM superstore_sql
WHERE `Sub-Category` IN ('Tables', 'Bookcases')
GROUP BY Region, `Sub-Category`
ORDER BY total_profit ASC;
```

The results **confirmed part of the hypothesis and corrected another part of it.** Confirmed: discount and profit are cleanly related — every region/sub-category pair averaging above ~20% discount lost money; every pair at or below it didn't. Corrected: the single worst-performing line in the entire dataset wasn't in Central at all — it was **East's Tables** (−₹11,025 profit at a 37.4% average discount, nearly triple any other region's Tables loss). Central's actual problem, confirmed with a `HAVING SUM(profit) < 0` query across every region/sub-category combination, was breadth: Central appeared in **7 of the 15 loss-making combinations** in the dataset, more than double any other region — a wide, shallow bleed across seven different sub-categories rather than one bad product line.

## Key findings

| Finding | Evidence |
|---|---|
| Furniture's margin (2.3%) trails Office Supplies and Technology (both ~17%) despite comparable sales | Category-level `GROUP BY` with margin calculation |
| Profit turns negative at 21%+ average discount and worsens sharply above 30% | Discount-band `CASE WHEN` aggregation |
| East's Tables line is the single largest loss-maker, driven by a 37.4% average discount | Region &times; sub-category breakdown |
| Central's weak regional margin comes from breadth (7 loss-making sub-categories), not one product line | `HAVING`-filtered aggregate across all region/sub-category pairs |

## What this demonstrates

- **Cross-tool fluency** — moving the same analytical question between Excel and SQL, and knowing which tool suits which stage (fast exploration vs. rigorous confirmation)
- **Data cleaning under real conditions** — diagnosing and fixing encoding artifacts and date-format mismatches using targeted diagnostic queries, not guesswork
- **Intellectual honesty in analysis** — treating an initial hypothesis as a starting point to test rather than a conclusion to confirm, and reporting the correction rather than the version that would have looked cleaner
- **Business-relevant output** — translating query results into a specific, actionable recommendation (a defensible discount ceiling, a targeted regional review) rather than stopping at the numbers

*A full interactive dashboard summarizing these findings is available on request / linked below.*
