#!/usr/bin/env python3
"""Genera el CREATE VIEW de Unit Life a partir de mapping/column_map.csv.

Cada fila del CSV es una columna del Excel "Assurant Shipment Master File".
Cuando se llenan source_db / source_schema / source_table / source_column,
la columna sale de esa tabla, enlazada por GCN contra la tabla base (spine)
definida en mapping/config.json.

Columnas del CSV que usa este script:
  source_db, source_schema, source_table, source_column
      De donde sale el dato. source_db puede ser "servidor.db" (linked server).
  key_column
      Columna de la tabla origen que contiene el GCN (default: "gcn").
  pick_order_by
      Si la tabla tiene varias filas por GCN (tests, reworks, envios...),
      se toma una sola fila ordenando por esta expresion, p.ej.
      "test_date DESC" = la mas reciente. Vacio = LEFT JOIN directo.
  filter
      Condicion extra sobre la tabla origen, usando el alias "x",
      p.ej. "x.test_name = 'ROXER 1'".
  expression
      Transformacion opcional. {col} se reemplaza por la columna origen,
      p.ej. "CAST({col} AS date)". Sin tabla origen, es una expresion SQL
      libre que puede usar "u." (la tabla base).

Columnas que comparten (db, schema, table, key_column, pick_order_by, filter)
se resuelven con un solo JOIN.

Uso:
  python3 tools/build_view.py            # escribe sql/vw_unit_life.sql
  python3 tools/build_view.py --stdout
"""
import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP_CSV = ROOT / "mapping" / "column_map.csv"
CONFIG = ROOT / "mapping" / "config.json"
OUT_SQL = ROOT / "sql" / "vw_unit_life.sql"

NULL_TYPES = {
    "sqlserver": {"varchar": "nvarchar(255)", "bigint": "bigint", "decimal": "decimal(18,4)", "datetime": "datetime2"},
    "postgres": {"varchar": "text", "bigint": "bigint", "decimal": "numeric(18,4)", "datetime": "timestamp"},
}


def quote(name, dialect):
    if dialect == "sqlserver":
        return "[" + name.replace("]", "]]") + "]"
    return '"' + name.replace('"', '""') + '"'


def qualified(db, schema, table, dialect):
    parts = [p for p in db.split(".") if p] if db else []
    parts += [p for p in (schema, table) if p]
    return ".".join(quote(p, dialect) for p in parts)


def build(cfg, rows):
    dialect = cfg.get("dialect", "sqlserver")
    if dialect not in NULL_TYPES:
        sys.exit(f"dialect no soportado: {dialect}")
    q = lambda n: quote(n, dialect)
    spine = cfg["spine"]
    if not spine.get("table"):
        sys.exit("Falta definir spine.table en mapping/config.json")
    spine_gcn = spine.get("gcn_column", "gcn")
    use_excel_names = cfg.get("column_names", "excel") == "excel"
    include_unmapped = cfg.get("include_unmapped", True)
    spine_key = (spine.get("db", ""), spine.get("schema", ""), spine["table"], spine_gcn, "", "")

    joins = {}  # group key -> alias
    select_lines = []
    pending = 0

    for r in rows:
        out_name = r["excel_name"] if use_excel_names else r["alias"]
        table = r["source_table"].strip()
        col = r["source_column"].strip()
        expr = r["expression"].strip()

        if table and col:
            key = (
                r["source_db"].strip(), r["source_schema"].strip(), table,
                r["key_column"].strip() or "gcn",
                r["pick_order_by"].strip(), r["filter"].strip(),
            )
            if key == spine_key:
                alias = "u"  # la columna vive en la misma tabla base, sin JOIN
            else:
                alias = joins.setdefault(key, f"s{len(joins) + 1}")
            src = f"{alias}.{q(col)}"
            value = expr.replace("{col}", src) if expr else src
        elif expr:
            value = expr
        elif r["alias"] == "gcn":
            value = f"u.{q(spine_gcn)}"
        else:
            pending += 1
            if not include_unmapped:
                continue
            null_type = NULL_TYPES[dialect].get(r["tipo_excel"], NULL_TYPES[dialect]["varchar"])
            select_lines.append(f"CAST(NULL AS {null_type}) AS {q(out_name)} /* PENDIENTE #{r['n']} */")
            continue
        select_lines.append(f"{value} AS {q(out_name)}")

    from_lines = [f"FROM {qualified(spine.get('db', ''), spine.get('schema', ''), spine['table'], dialect)} AS u"]
    for (db, schema, table, key_col, pick, flt), alias in joins.items():
        src = qualified(db, schema, table, dialect)
        cond = f"x.{q(key_col)} = u.{q(spine_gcn)}" + (f" AND ({flt})" if flt else "")
        if pick:
            if dialect == "sqlserver":
                from_lines.append(f"OUTER APPLY (SELECT TOP 1 x.* FROM {src} AS x WHERE {cond} ORDER BY {pick}) AS {alias}")
            else:
                from_lines.append(f"LEFT JOIN LATERAL (SELECT x.* FROM {src} AS x WHERE {cond} ORDER BY {pick} LIMIT 1) AS {alias} ON TRUE")
        else:
            on = f"{alias}.{q(key_col)} = u.{q(spine_gcn)}" + (f" AND ({flt.replace('x.', alias + '.')})" if flt else "")
            from_lines.append(f"LEFT JOIN {src} AS {alias} ON {on}")

    where = f"\nWHERE {spine['filter']}" if spine.get("filter") else ""
    view = cfg.get("view_name", "dbo.vw_unit_life")
    create = "CREATE OR ALTER VIEW" if dialect == "sqlserver" else "CREATE OR REPLACE VIEW"
    header = (
        "-- Generado por tools/build_view.py desde mapping/column_map.csv. No editar a mano.\n"
        f"-- Columnas mapeadas: {len(rows) - pending} / {len(rows)}  |  JOINs: {len(joins)}\n"
    )
    body = ",\n    ".join(select_lines)
    return f"{header}{create} {view} AS\nSELECT\n    {body}\n" + "\n".join(from_lines) + where + ";\n", pending


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stdout", action="store_true")
    args = ap.parse_args()
    cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    with MAP_CSV.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    sql, pending = build(cfg, rows)
    if args.stdout:
        sys.stdout.write(sql)
    else:
        OUT_SQL.parent.mkdir(exist_ok=True)
        OUT_SQL.write_text(sql, encoding="utf-8")
        print(f"{OUT_SQL.relative_to(ROOT)}: {len(rows) - pending}/{len(rows)} columnas mapeadas, {pending} pendientes")


if __name__ == "__main__":
    main()
