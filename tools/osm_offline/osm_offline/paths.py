"""
Cross-platform path helpers for locating OSM PBF inputs on Windows/Linux.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable, List, Optional, Sequence


def expand_user_path(path: Path | str) -> Path:
    """Expand ~ and environment variables, return a Path (not yet resolved)."""
    return Path(os.path.expandvars(os.path.expanduser(str(path))))


def resolve_existing_file(path: Path | str) -> Optional[Path]:
    """Return absolute path if `path` is an existing file, else None."""
    candidate = expand_user_path(path)
    try:
        if candidate.is_file():
            return candidate.resolve()
    except OSError:
        return None
    return None


def search_osm_pbf(
    filename_hint: Optional[str] = None,
    *,
    extra_roots: Sequence[Path | str] = (),
) -> List[Path]:
    """
    Search common locations for *.osm.pbf files.

    Search order:
      1. extra_roots (caller-provided)
      2. current working directory + ./data
      3. tools/osm_offline/data
      4. ~/Downloads
      5. user home (exact filename only)
      6. Pocket-Medic project root (recursive *.osm.pbf)

    Returns unique existing files, preferring exact filename matches first.
    """
    cwd = Path.cwd()
    tools_osm_root = Path(__file__).resolve().parents[1]  # .../tools/osm_offline
    repo_root = tools_osm_root.parents[1]  # .../Pocket-Medic
    home = Path.home()

    roots: List[Path] = []
    for r in extra_roots:
        roots.append(expand_user_path(r))
    roots.extend(
        [
            cwd,
            cwd / "data",
            tools_osm_root / "data",
            tools_osm_root,
            home / "Downloads",
            home,
            repo_root,
            repo_root / "data",
        ]
    )

    found: List[Path] = []
    seen: set[str] = set()

    def _add(path: Path) -> None:
        try:
            key = str(path.resolve()).lower()
        except OSError:
            key = str(path).lower()
        if key in seen:
            return
        if path.is_file():
            seen.add(key)
            found.append(path.resolve())

    # Exact filename hits first (non-recursive in roots).
    names: List[str] = []
    if filename_hint:
        names.append(Path(filename_hint).name)
    names.append("southern-zone-260729.osm.pbf")

    for root in roots:
        if not root.exists():
            continue
        for name in names:
            _add(root / name)

    # Broader glob in shallow dirs (not full home recurse — too slow/dangerous).
    shallow_glob_roots = [
        cwd,
        cwd / "data",
        tools_osm_root / "data",
        tools_osm_root,
        home / "Downloads",
        repo_root,
    ]
    for root in shallow_glob_roots:
        if not root.is_dir():
            continue
        try:
            for match in root.glob("*.osm.pbf"):
                _add(match)
            for match in root.glob("*.pbf"):
                _add(match)
        except OSError:
            continue

    # Optional deeper search under project only.
    if repo_root.is_dir():
        try:
            for match in repo_root.rglob("*.osm.pbf"):
                _add(match)
        except OSError:
            pass

    if filename_hint:
        hint = Path(filename_hint).name.lower()
        found.sort(key=lambda p: (0 if p.name.lower() == hint else 1, str(p).lower()))
    return found


def resolve_pbf_path(
    requested: Path | str,
    *,
    auto_discover: bool = True,
) -> Path:
    """
    Resolve a user-supplied PBF path.

    If the requested path exists, return it.
    If missing and auto_discover=True, search common locations and use the
    best match (same filename preferred).
    """
    requested_path = expand_user_path(requested)
    direct = resolve_existing_file(requested_path)
    if direct is not None:
        return direct

    if not auto_discover:
        raise FileNotFoundError(_missing_pbf_message(requested_path, []))

    matches = search_osm_pbf(requested_path.name)
    if matches:
        # Prefer exact filename match.
        for m in matches:
            if m.name.lower() == requested_path.name.lower():
                return m
        return matches[0]

    raise FileNotFoundError(_missing_pbf_message(requested_path, matches))


def _missing_pbf_message(requested: Path, searched_hits: Sequence[Path]) -> str:
    tools_data = Path(__file__).resolve().parents[1] / "data"
    downloads = Path.home() / "Downloads"
    lines = [
        f"PBF not found at: {requested}",
        f"Resolved attempt: {requested.resolve() if requested.exists() or requested.is_absolute() else (Path.cwd() / requested)}",
        f"Current working directory: {Path.cwd()}",
        "",
        "Place your .osm.pbf file here:",
        f"  {tools_data}",
        "or here:",
        f"  {downloads}",
        "",
        "Then run:",
        f'  python -m osm_offline import "{tools_data / requested.name}" -o "{tools_data / "survival.sqlite"}"',
    ]
    if searched_hits:
        lines.append("")
        lines.append("Search also found unrelated PBF files:")
        for hit in searched_hits[:10]:
            lines.append(f"  - {hit}")
    return "\n".join(lines)


def default_place_locations() -> Iterable[Path]:
    tools_data = Path(__file__).resolve().parents[1] / "data"
    yield tools_data
    yield Path.home() / "Downloads"
