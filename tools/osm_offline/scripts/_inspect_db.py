import sqlite3
from pathlib import Path

p = Path("data/survival.sqlite")
print("exists", p.exists())
print("size", p.stat().st_size if p.exists() else 0)
c = sqlite3.connect(str(p))
try:
    tables = [r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
    print("tables", tables)
    if "features" in tables:
        print("count", c.execute("SELECT COUNT(*) FROM features").fetchone()[0])
        print(
            "types",
            c.execute(
                "SELECT type, COUNT(*) AS c FROM features GROUP BY type ORDER BY c DESC"
            ).fetchall()[:20],
        )
    if "meta" in tables:
        print("meta", c.execute("SELECT key, value FROM meta").fetchall())
except Exception as e:
    print("ERR", type(e).__name__, e)
finally:
    c.close()
