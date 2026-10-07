# Unit Life

Vista SQL en vivo (`dbo.vw_unit_life`, Microsoft SQL Server / AirlinkDR) que replica el **Assurant Shipment Master File** (hoja `Raw Data`, 135 columnas), una fila por **GCN**.

| Archivo | Para qué |
|---|---|
| `sql/vw_unit_life.sql` | La vista. Columnas en el mismo orden que el Excel; las que aún no tienen origen salen `NULL` marcadas `/* PENDIENTE #n */`. |
| `mapping/column_map.csv` | Control de avance: por columna, `estado` (hecho / parcial / pendiente), `origen` y `regla`. |

## Fuentes conectadas

| Alias | Tabla | Enlace | Columnas |
|---|---|---|---|
| `u` | `AirlinkDR.dbo.Receiving` | GCN (tabla base) | gcn, imei, po |
| `un` | `AirlinkDR.dbo.Unit` | IMEI | model, color, capacity, carrier |
| `sk` | `AirlinkDR.dbo.PRD_JV_Skus` | *pendiente* | itemnumber (`Partnumber`), item_description |
| `c` | — | *regla pendiente* | enclosure / backglass / lcd condition |
| `rt` | `AirlinkDR.dbo.PRD_JV_ROUTING` | (Enclosure, BackGlass, LCD) | route |

Constantes: battery, wptlcd, wptbackglass, pentalobe = `NEW`; speaker, vibrator, earpiece = `USED (POP & SWAP)`.
