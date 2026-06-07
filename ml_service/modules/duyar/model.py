"""Duyar ses sınıflandırma modeli — küçük 2D CNN.

Telefonda gerçek zamanlı çalışacak kadar hafif; log-mel spektrogram üzerinde
çalışır. ONNX/TFLite export'a uygundur.
"""
import torch
import torch.nn as nn

from .labels import NUM_CLASSES


class DuyarNet(nn.Module):
    def __init__(self, n_classes: int = NUM_CLASSES):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(1, 16, 3, padding=1), nn.BatchNorm2d(16), nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(16, 32, 3, padding=1), nn.BatchNorm2d(32), nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, 3, padding=1), nn.BatchNorm2d(64), nn.ReLU(),
            nn.AdaptiveAvgPool2d(1),         # (B, 64, 1, 1) — girdi boyutundan bağımsız
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Dropout(0.3),
            nn.Linear(64, n_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (B, 1, N_MELS, T)
        return self.classifier(self.features(x))


def build_model() -> DuyarNet:
    return DuyarNet()
