# Unit Life

Vista SQL en vivo que replica el **Assurant Shipment Master File** (hoja `Raw Data`, 135 columnas), una fila por **GCN**.

## Cómo funciona

| Archivo | Para qué |
|---|---|
| `mapping/column_map.csv` | Inventario de las 135 columnas del Excel. Aquí se llena de dónde sale cada una. |
| `mapping/config.json` | Motor SQL, nombre de la vista y la **tabla base** (spine): la tabla que define qué GCNs aparecen. |
| `tools/build_view.py` | Lee lo anterior y genera `sql/vw_unit_life.sql`. |

Flujo: llenar columnas en el CSV → `python3 tools/build_view.py` → ejecutar `sql/vw_unit_life.sql` en el servidor.

Las columnas que aún no tienen origen salen como `NULL` (marcadas `/* PENDIENTE #n */`) para que la vista tenga desde el principio la misma forma que el Excel.

## Campos del mapeo

- `source_db`, `source_schema`, `source_table`, `source_column`: origen del dato.
- `key_column`: columna con el GCN en la tabla origen (default `gcn`).
- `pick_order_by`: si hay varias filas por GCN (tests Roxer, reworks, envíos), toma una ordenando por esto, p.ej. `x.test_date DESC` = la más reciente.
- `filter`: condición extra con alias `x`, p.ej. `x.test_name = 'ROXER 1'`.
- `expression`: transformación; `{col}` = la columna origen, p.ej. `CAST({col} AS date)`.

Columnas con el mismo origen (tabla + llave + pick + filtro) comparten un solo JOIN.

## Grupos de columnas

01 Identificación · 02 Build/partes · 03 Ensamble/rework Airlink · 04 Envío ARL→Assurant · 05 Assurant/FAI AT&T · 06 Evidencia · 07 X-Ray · 08 Roxer post FAI fail · 09 Análisis de falla · 10 Re-tests Roxer/rework CA nuevo · 11 Re-ensamble/cambio de partes · 12 Envío final/resultados Assurant
