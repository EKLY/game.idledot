import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit(
        "Pillow is required. Install with: pip install pillow"
    ) from exc


def convert_one(src: Path, size: int) -> None:
    if not src.exists():
        raise FileNotFoundError(f"Missing source file: {src}")

    name = src.stem.replace("_org", "")
    dst_icon = src.with_name(f"{name}.png")
    dst_tile = src.with_name(f"{name}_tile.png")

    with Image.open(src) as img:
        img = img.convert("RGBA")
        resized = img.resize((size, size), Image.Resampling.NEAREST)
        resized.save(dst_icon)
        resized.save(dst_tile)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Resize *_org.png building images to icon and tile outputs."
    )
    default_dir = (
        Path(__file__).resolve().parents[1] / "assets" / "sprites" / "buildings"
    )
    parser.add_argument(
        "--dir",
        default=str(default_dir),
        help="Directory containing *_org.png files",
    )
    parser.add_argument(
        "--size",
        type=int,
        default=64,
        help="Output size (square). Default 64",
    )
    parser.add_argument(
        "--file",
        help="Single file to convert (e.g., b001_org.png)",
    )

    args = parser.parse_args()
    base_dir = Path(args.dir)
    print(f"Scanning for *_org.png in: {base_dir.resolve()}")

    if args.file:
        convert_one(base_dir / args.file, args.size)
        return

    for src in base_dir.glob("*_org.png"):
        convert_one(src, args.size)


if __name__ == "__main__":
    main()
