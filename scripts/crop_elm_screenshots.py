from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FIGURES = ROOT / "experiments" / "figures"
SOURCE = FIGURES / "elm_dashboard_full.png"


def main() -> None:
    Image.open(SOURCE).save(FIGURES / "elm_dashboard.png")
    top = Image.open(FIGURES / "viewport_top.png")
    matrix = Image.open(FIGURES / "viewport_matrix.png")
    crops = {
        "elm_chord.png": (top, (24, 244, 515, 712)),
        "elm_timeline.png": (top, (535, 244, 1241, 712)),
        "elm_matrix.png": (matrix, (24, 142, 1241, 694)),
    }
    for name, (image, box) in crops.items():
        image.crop(box).save(FIGURES / name)
        print(FIGURES / name)


if __name__ == "__main__":
    main()
