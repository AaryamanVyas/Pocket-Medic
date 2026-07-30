"""
Pure-math geospatial helpers (no online APIs, no GDAL required).

Used to:
  - build a bounding box for candidate filtering in SQLite
  - compute accurate Haversine distances for ranking / radius checks
"""

from __future__ import annotations

import math
from typing import Iterable, List, Sequence, Tuple

EARTH_RADIUS_M = 6_371_000.0


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance between two WGS84 points, in meters."""
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(d_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2.0) ** 2
    )
    return 2.0 * EARTH_RADIUS_M * math.asin(math.sqrt(a))


def bbox_for_radius(
    latitude: float,
    longitude: float,
    radius_meters: float,
) -> Tuple[float, float, float, float]:
    """
    Approximate lat/lon bounding box around a point for a given radius.

    Returns (min_lat, max_lat, min_lon, max_lon).
    Slightly oversized on purpose so Haversine can filter false positives.
    """
    # 1° latitude ≈ 111_320 m
    lat_delta = (radius_meters / 111_320.0) * 1.05
    # Longitude degrees shrink with cos(latitude)
    cos_lat = math.cos(math.radians(latitude))
    meters_per_deg_lon = max(111_320.0 * abs(cos_lat), 1e-6)
    lon_delta = (radius_meters / meters_per_deg_lon) * 1.05

    return (
        latitude - lat_delta,
        latitude + lat_delta,
        longitude - lon_delta,
        longitude + lon_delta,
    )


def centroid(points: Sequence[Tuple[float, float]]) -> Tuple[float, float]:
    """
    Simple arithmetic mean of (lat, lon) samples.

    Good enough as a representative point for ways/areas in a survival
    nearest-search index. Not a geodesic centroid.
    """
    if not points:
        raise ValueError("centroid() requires at least one point")
    lat = sum(p[0] for p in points) / len(points)
    lon = sum(p[1] for p in points) / len(points)
    return lat, lon


def valid_wgs84(lat: float, lon: float) -> bool:
    return -90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0
