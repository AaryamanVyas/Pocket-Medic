"""
Maps OpenStreetMap tags → survival feature types used by the app.

Only tags listed here are extracted from the PBF. Everything else is ignored
to keep the SQLite database small and relevant for offline survival use.
"""

from __future__ import annotations

from typing import Dict, Iterable, List, Optional, Tuple

# Canonical feature type strings stored in SQLite `features.type`.
FEATURE_TYPES: Tuple[str, ...] = (
    "hospital",
    "clinic",
    "pharmacy",
    "police",
    "fire_station",
    "campsite",
    "wilderness_hut",
    "shelter",
    "drinking_water",
    "spring",
    "river",
    "stream",
    "lake",
    "pond",
    "waterfall",
    "village",
    "town",
    "city",
    "road",
    "hiking_trail",
    "peak",
    "cave",
    "forest",
)

# place=* values used by reverse_geocode (nearest settlement).
SETTLEMENT_TYPES: Tuple[str, ...] = ("city", "town", "village")

# highway=* values treated as general roads (not foot/hiking-focused).
ROAD_HIGHWAYS: frozenset[str] = frozenset(
    {
        "motorway",
        "trunk",
        "primary",
        "secondary",
        "tertiary",
        "unclassified",
        "residential",
        "service",
        "living_street",
        "track",
        "road",
    }
)

# highway=* values treated as hiking / walking routes.
HIKING_HIGHWAYS: frozenset[str] = frozenset(
    {
        "path",
        "footway",
        "bridleway",
        "steps",
    }
)


def classify_tags(tags: Dict[str, str]) -> Optional[str]:
    """
    Return the first matching survival feature type for an OSM object's tags,
    or None if the object should be skipped.

    Order matters when tags could match multiple categories: more specific
    survival features are preferred over broad ones (e.g. waterfall before river).
    """
    amenity = tags.get("amenity")
    tourism = tags.get("tourism")
    healthcare = tags.get("healthcare")
    natural = tags.get("natural")
    waterway = tags.get("waterway")
    water = tags.get("water")
    place = tags.get("place")
    highway = tags.get("highway")
    landuse = tags.get("landuse")
    route = tags.get("route")

    # Emergency / services
    if amenity == "hospital" or healthcare == "hospital":
        return "hospital"
    if amenity == "clinic" or healthcare in {"clinic", "doctor", "centre", "center"}:
        return "clinic"
    if amenity == "pharmacy":
        return "pharmacy"
    if amenity == "police":
        return "police"
    if amenity == "fire_station":
        return "fire_station"

    # Shelter / camping
    if tourism == "camp_site":
        return "campsite"
    if tourism == "wilderness_hut":
        return "wilderness_hut"
    if amenity == "shelter" or tourism == "shelter":
        return "shelter"

    # Water points & hydrology
    if amenity == "drinking_water":
        return "drinking_water"
    if natural == "spring":
        return "spring"
    if waterway == "waterfall" or natural == "waterfall":
        return "waterfall"
    if waterway == "river":
        return "river"
    if waterway == "stream":
        return "stream"
    if natural == "water":
        if water == "pond":
            return "pond"
        if water in {"lake", "reservoir", "lagoon", "oxbow"} or water is None:
            # Untagged natural=water is commonly a lake/reservoir polygon.
            return "lake"
    if landuse == "reservoir":
        return "lake"

    # Settlements
    if place == "city":
        return "city"
    if place == "town":
        return "town"
    if place == "village":
        return "village"

    # Terrain / cover
    if natural == "peak":
        return "peak"
    if natural == "cave_entrance":
        return "cave"
    if landuse == "forest" or natural == "wood":
        return "forest"

    # Trails before general roads (path/footway / marked hiking tracks).
    if (
        highway in HIKING_HIGHWAYS
        or route == "hiking"
        or tags.get("sac_scale") is not None
        or (highway == "track" and tags.get("trail_visibility") is not None)
    ):
        return "hiking_trail"

    if highway in ROAD_HIGHWAYS:
        return "road"

    return None


def preferred_name(tags: Dict[str, str]) -> str:
    """Best-effort display name from common OSM name tags."""
    for key in ("name", "name:en", "official_name", "alt_name", "loc_name"):
        value = tags.get(key)
        if value:
            return value
    # Fallbacks so unnamed objects are still identifiable in the UI.
    ref = tags.get("ref")
    if ref:
        return ref
    return ""


def iter_tag_dict(osm_tags: Iterable) -> Dict[str, str]:
    """
    Convert osmium TagList (or any iterable of .k/.v) into a plain dict.
    """
    out: Dict[str, str] = {}
    for tag in osm_tags:
        # osmium tags expose .k / .v
        out[str(tag.k)] = str(tag.v)
    return out
