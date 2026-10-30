# VEDA Black Marble

Nighttime lights processing pipeline for NASA VEDA, combining VIIRS nighttime lights with Landsat data to create urban-focused imagery.

## Installation

Requires Python 3.11+.

```bash
# Clone the repository
git clone https://github.com/NASA-IMPACT/veda-black-marble.git
cd veda-black-marble

# Install in editable mode
pip install -e .
# or with uv
uv pip install -e .
```

## Quick Start

```bash
# Set your NASA Earthdata token (required for VIIRS data)
export EARTHDATA_TOKEN="your-token-here"

# Process nighttime lights for San Francisco
blackmarble \
  --bbox "-122.55,37.69,-122.32,37.81" \
  --date 2023-06-15 \
  --output-path san_francisco_lights.tif
```

## CLI Options

| Option | Default | Description |
|--------|---------|-------------|
| `--bbox` | required | Bounding box for processing (WGS84) |
| `--date` | required | Target date for processing |
| `--output-path`, `-o` | `black_marble_output.tif` | Output COG file path |
| `--data-dir` | `./data` | Directory to store/cache data |
| `--config`, `-c` | `default` | Preset: `default`, `high_quality`, or `fast` |
| `--save-diagnostics`, `-d` | False | Save intermediate outputs to `{data-dir}/diagnostics/` |
| `--wgs84`, `-w` | False | Also export EPSG:4326 version |
| `--earthdata-token`, `-t` | ENV_VAR | NASA Earthdata token (or use EARTHDATA_TOKEN) |
| `--log-level`, `-l` | `INFO` | Logging level: `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `--osm-source` | `overpass` | OSM backend source: `overpass` or `layercake` |

Run `blackmarble --help` for complete options.

## OSM Sources

Road data can be fetched from either:

- `overpass` (default): Overpass API queries via OSMnx
- `layercake`: OpenStreetMap US [Layercake parquet](https://openstreetmap.us/our-work/layercake/) source

Layercake fetches directly from parquet extracts and can be faster to retrieve data, not timeout over large areas or areas of high density, but is experimental and may not be as fresh.


## Examples

### High-Quality Urban Analysis
```bash
# Paris with high quality settings and WGS84 export
blackmarble \
  --bbox "2.08,48.80,2.42,48.92" \
  --date 2023-08-01 \
  --config high_quality \
  --wgs84 \
  --output-path paris_lights_hq.tif
```

### Quick Diagnostic Run
```bash
# Kansas City with diagnostics for QA
blackmarble \
  --bbox "-94.74,38.97,-94.42,39.20" \
  --date 2023-05-15 \
  --config fast \
  --save-diagnostics \
  --output-path kansas_test.tif
```

### Using Layercake for OSM data

```bash
blackmarble \
  --bbox "-122.55,37.69,-122.32,37.81" \
  --date 2023-06-15 \
  --osm-source layercake \
  --output-path sf_layercake.tif
```

## Documentation

For detailed algorithm documentation (QA masking, temporal compositing, urban field enhancement), see [`docs/pipeline-steps/`](docs/pipeline-steps/). Start with [`README.md`](docs/pipeline-steps/README.md) for an overview.

## Python API

```python
from blackmarble.pipeline import pipeline
from datetime import datetime

# Process a region
result = pipeline(
    bbox=(-122.55, 37.69, -122.32, 37.81),  # (min_lon, min_lat, max_lon, max_lat)
    date=datetime(2023, 6, 15),
    output_path="san_francisco.tif"
)
```

## Module Organization

The pipeline follows a clear data flow from acquisition through export:

```
blackmarble/
├── acquire/          # Async downloads: Landsat, VIIRS, OSM roads
│   ├── landsat.py      # Scene selection with date-grouped approach
│   ├── viirs.py        # VIIRS nighttime lights (VNP46A2)
│   └── osm.py          # OpenStreetMap road networks
├── prepare/          # Data preparation and quality control
│   ├── landsat_qa.py   # Cloud/shadow masking with QA bands
│   └── spatial.py      # Reprojection to common grid
├── analyze/          # Core algorithms
│   ├── indices.py      # NDVI, NDWI calculation
│   ├── temporal.py     # Temporal compositing (85th percentile NDVI)
│   └── urban_fields.py # Multi-scale urban enhancement
├── enhance/          # Visualization
│   ├── contrast.py     # Dynamic range adjustment
│   └── visualize.py    # Colormap application
└── export/           # Output generation
    ├── cog.py          # Cloud-Optimized GeoTIFF creation
    └── metadata.py     # Processing metadata
```

## Output

The pipeline produces:
- **Cloud-Optimized GeoTIFF** with embedded metadata
- **RGB visualization** using the inferno colormap
- **Optional EPSG:4326 version** for web mapping (use `--wgs84`)
- **Optional diagnostics** including intermediate processing steps

## Requirements

- Python 3.11+
- NASA Earthdata account (free) for VIIRS data
- ~8GB RAM for typical 100x100km regions


## OGC / MAAP DPS

Thin OGC Application Package layer (branch `ogc-thin-wrapper`):

| File | Role |
|------|------|
| `build.sh` | Install `uv` + `maap-py`; `uv sync` this repo |
| `run.sh` | Secrets → `uv run blackmarble` → `output/` |
| `resolve_earthdata_token.py` | Load token from env or MAAP Secrets (never CLI) |
| `environment.yml` / `Dockerfile` | Packaging image |
| `algorithm_config.yml` / `maap_dps_algorithm_config.yml` | Register metadata |
| `workflows/commandline.cwl` | OGC Application Package |

Earthdata auth (create once in ADE):

```python
from maap.maap import MAAP
MAAP().secrets.add_secret("EARTHDATA_TOKEN", "<your-token>")
```

Register with repository `https://github.com/NASA-IMPACT/veda-black-marble`,
version/branch `ogc-thin-wrapper`, build `veda-black-marble/build.sh`,
run `veda-black-marble/run.sh`.

## License

[Apache License 2.0](LICENSE) - National Aeronautics and Space Administration (NASA)

Originally created by NASA Goddard Earth Sciences

## Contributing

Issues and pull requests welcome! Report bugs and request features at https://github.com/NASA-IMPACT/veda-black-marble/issues
