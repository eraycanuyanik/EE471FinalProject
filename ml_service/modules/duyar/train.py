"""Duyar modelini eğitir.

Örnek:
    python -m modules.duyar.train --epochs 5 --synthetic
    python -m modules.duyar.train --epochs 20 --data data   # gerçek veri
"""
import argparse
from pathlib import Path

import torch
from torch.utils.data import DataLoader, random_split

from .dataset import build_dataset
from .labels import LABELS
from .model import build_model

CKPT = Path(__file__).parent / "duyar_model.pt"


def train(epochs: int, synthetic: bool, data_root: str, batch_size: int, lr: float):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"[duyar] cihaz: {device} | sentetik: {synthetic}")

    ds = build_dataset(synthetic=synthetic, root=data_root)
    n_val = max(1, int(0.2 * len(ds)))
    train_ds, val_ds = random_split(
        ds, [len(ds) - n_val, n_val], generator=torch.Generator().manual_seed(42)
    )
    train_dl = DataLoader(train_ds, batch_size=batch_size, shuffle=True)
    val_dl = DataLoader(val_ds, batch_size=batch_size)

    model = build_model().to(device)
    opt = torch.optim.Adam(model.parameters(), lr=lr)
    loss_fn = torch.nn.CrossEntropyLoss()

    for ep in range(1, epochs + 1):
        model.train()
        total = 0.0
        for x, y in train_dl:
            x, y = x.to(device), y.to(device)
            opt.zero_grad()
            loss = loss_fn(model(x), y)
            loss.backward()
            opt.step()
            total += loss.item() * x.size(0)
        train_loss = total / len(train_ds)

        # doğrulama
        model.eval()
        correct = 0
        with torch.no_grad():
            for x, y in val_dl:
                x, y = x.to(device), y.to(device)
                correct += (model(x).argmax(1) == y).sum().item()
        acc = correct / len(val_ds)
        print(f"epoch {ep:>2}/{epochs}  loss={train_loss:.4f}  val_acc={acc:.3f}")

    torch.save({"state_dict": model.state_dict(), "labels": LABELS}, CKPT)
    print(f"[duyar] model kaydedildi -> {CKPT}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--epochs", type=int, default=5)
    p.add_argument("--synthetic", action="store_true", help="sentetik veriyle eğit")
    p.add_argument("--data", default="data", help="gerçek veri kök klasörü")
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    args = p.parse_args()
    train(args.epochs, args.synthetic, args.data, args.batch_size, args.lr)


if __name__ == "__main__":
    main()
