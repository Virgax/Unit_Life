# Unit Life

Stored procedure por request (`dbo.usp_UnitLife`, Microsoft SQL Server / AirlinkDR) que replica el **Assurant Shipment Master File** (hoja `Raw Data`, 135 columnas), una fila por **GCN**.

| Archivo | Para qué |
|---|---|
| `sql/usp_unit_life.sql` | El SP. Recibe una lista de GCNs y devuelve las columnas en el mismo orden que el Excel; las que aún no tienen origen salen `NULL` marcadas `/* PENDIENTE #n */`. |
| `mapping/column_map.csv` | Control de avance: por columna, `estado` (hecho / parcial / pendiente), `origen` y `regla`. |

## Fuentes conectadas

| Alias | Tabla | Enlace | Columnas |
|---|---|---|---|
| `u` | `AirlinkDR.dbo.Receiving` | GCN (único) | gcn, imei, po |
| `un` | `AirlinkDR.dbo.Unit` | IMEI | model, color, capacity, carrier |
| `sk` | `AirlinkDR.dbo.PRD_JV_Skus` | Model + Color + Capacity de Unit; carrier ATT → item `.ATT`, Unlocked/N/A → `.GENERIC` | itemnumber (`Partnumber`), item_description |
| `c` | — | *regla pendiente* | enclosure / backglass / lcd condition |
| `rt` | `AirlinkDR.dbo.PRD_JV_ROUTING` | (Enclosure, BackGlass, LCD) | route |

Constantes: battery, wptlcd, wptbackglass, pentalobe = `NEW`; speaker, vibrator, earpiece = `USED (POP & SWAP)`.

## Uso

```sql
EXEC dbo.usp_UnitLife @GCNs = 'CX411014,CX411642,CX413505';
```

`@GCNs` acepta separadores coma, punto y coma o salto de línea (se puede pegar una columna del Excel).
