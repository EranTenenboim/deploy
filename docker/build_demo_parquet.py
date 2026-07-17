#!/usr/bin/env python3
"""Build a small Santa Clara demo parquet for free-tier / Render deploys."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import duckdb

CITIES = (
    "Palo Alto",
    "San Jose",
    "Santa Clara",
    "Mountain View",
    "Sunnyvale",
    "Cupertino",
)

STREETS = (
    "University Ave",
    "El Camino Real",
    "Castro St",
    "Murphy Ave",
    "Stevens Creek Blvd",
    "Alma St",
)


def build(out_dir: Path, rows: int = 600) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = out_dir / "properties.parquet"
    summary_path = out_dir / "run_summary.json"
    finished = datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    city_lit = ", ".join(f"'{c}'" for c in CITIES)
    street_lit = ", ".join(f"'{s}'" for s in STREETS)

    con = duckdb.connect()
    con.execute(
        f"""
        CREATE OR REPLACE TABLE properties AS
        SELECT
          printf('demo-%06d', i) AS property_id,
          printf('cid-%06d', i) AS property_cid,
          printf('REQ-%06d', i) AS request_identifier,
          printf('APN-%06d', i) AS parcel_identifier,
          printf('APN-%06d', i) AS parcel_id,
          'demo-render' AS source_system,
          'Santa Clara' AS county_name,
          'CA' AS state_code,
          ([{street_lit}])[1 + ((i - 1) % {len(STREETS)})]
            || ' ' || cast(100 + (i % 800) AS VARCHAR) AS address_street,
          ([{city_lit}])[1 + ((i - 1) % {len(CITIES)})] AS address_city,
          printf('94%03d', 100 + (i % 90)) AS address_zip,
          37.35 + ((i % 100) * 0.001) AS latitude,
          -122.05 - ((i % 100) * 0.001) AS longitude,
          0.12 + ((i % 20) * 0.01) AS lot_size_acre,
          5000 + (i % 40) * 100 AS lot_area_sqft,
          'stucco' AS exterior_wall_material,
          'composition' AS roof_covering_material,
          'residential' AS property_type,
          'single_family' AS property_usage_type,
          1950 + (i % 70) AS built_year,
          1200 + (i % 50) * 20 AS livable_floor_area,
          1500 + (i % 50) * 25 AS total_area,
          800000 + i * 1000 AS assessed_value,
          900000 + i * 1100 AS market_value,
          500000 + i * 500 AS land_value,
          950000 + i * 1200 AS avm_value,
          'Owner ' || cast(i AS VARCHAR) AS owner_name,
          CASE WHEN i % 3 = 0 THEN 'regional investor LLC' ELSE 'local owner' END AS owners_text,
          1 AS owner_count,
          (i % 2 = 0) AS owner_occupied,
          CASE WHEN i % 4 = 0 THEN NULL
               ELSE CAST(date '2005-01-01' + CAST((i % 4000) AS INTEGER) AS DATE) END AS last_sale_date,
          CASE WHEN i % 4 = 0 THEN NULL ELSE 700000 + i * 100 END AS last_sale_price,
          'Demo Subdivision' AS subdivision,
          true AS has_permits,
          1 + (i % 5) AS permit_count,
          false AS has_sunbiz_tenant,
          false AS has_bbb_contractor,
          false AS hoa_flag,
          5 + (i % 40) AS roof_age_years,
          (i % 5 = 0) AS has_water_view,
          CASE WHEN i % 5 = 0 THEN 120 + (i % 200) ELSE 800 + (i % 500) END AS distance_to_water_m,
          CASE WHEN i % 4 = 0 THEN 15 + (i % 20) ELSE 3 + (i % 8) END AS years_since_ownership_change,
          (i % 3 = 0) AS is_regional_owner,
          100 + (i % 900) AS distance_to_public_transit_m,
          80 + (i % 1000) AS distance_to_starbucks_m
        FROM range(1, {rows + 1}) t(i)
        """
    )
    con.execute(
        f"COPY properties TO '{parquet_path.as_posix()}' (FORMAT PARQUET, COMPRESSION ZSTD)"
    )
    count = int(con.execute("SELECT count(*) FROM properties").fetchone()[0])
    con.close()

    summary = {
        "status": "completed",
        "county": "santa-clara",
        "mode": "demo-render",
        "started_at": finished,
        "finished_at": finished,
        "records_by_source": {
            "property": {
                "count": count,
                "collected_at": finished,
                "provenance": "Render free-tier demo sample",
            },
            "permit": {
                "count": count,
                "collected_at": finished,
                "provenance": "Render free-tier demo sample",
            },
            "ownership": {
                "count": count // 2,
                "collected_at": finished,
                "provenance": "Render free-tier demo sample",
            },
            "contractor": {
                "count": max(1, count // 10),
                "collected_at": finished,
                "provenance": "Render free-tier demo sample",
            },
            "business": {
                "count": max(1, count // 8),
                "collected_at": finished,
                "provenance": "Render free-tier demo sample",
            },
            "coordinate": {
                "count": count,
                "collected_at": finished,
                "provenance": "Render free-tier demo sample",
            },
        },
        "constraints": [
            "Demo sample baked into the Render free-tier image (not the full county extract).",
            "Set PARQUET_URL to a full properties.parquet for production-scale data.",
        ],
    }
    summary_path.write_text(json.dumps(summary, indent=2) + "\n")
    print(f"Wrote {count} rows -> {parquet_path}")
    print(f"Wrote summary -> {summary_path}")
    return parquet_path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=Path("data"))
    parser.add_argument("--rows", type=int, default=600)
    args = parser.parse_args()
    build(args.out, rows=args.rows)


if __name__ == "__main__":
    main()
