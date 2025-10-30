from collections.abc import Sequence

import torch
from torch import Tensor, nn
from torch.utils.data import DataLoader, Dataset


class CBOWFFModel(nn.Module):
    """Continuous Bag Of Events model."""

    def __init__(self, vocab_size: int, emb_dim: int = 8, block_size: int = 3) -> None:
        super().__init__()
        self.block_size = block_size

        self.emb = nn.Embedding(vocab_size, emb_dim)
        self.clf = nn.Linear((self.block_size - 1) * emb_dim, vocab_size)
        self.act_fun = nn.ReLU()

    def forward(self, x: Tensor):
        _, blockx = x.shape

        assert blockx == self.block_size - 1, (
            f"expected {self.block_size - 1} length input, got {blockx}"
        )

        x = self.emb(x)  # -> (bs, blockx, embd)

        # concatenate embedded inputs
        x = x.flatten(1, 2)  # -> (bs, blockx*emb)

        x = self.act_fun(x)
        return self.clf(x)  # ->  (bs, vocab)


class EventCBOWDataset(Dataset):
    def __init__(
        self, sequences: Sequence[list[int]], block_size: int = 3, verbose: bool = True
    ) -> None:
        super().__init__()

        assert block_size >= 3, "at least one on each side"
        assert block_size % 2 == 1, "expects odd number"

        side_count = block_size // 2  # predict middle label
        self.block_size = block_size

        samplesX = []
        samplesY = []
        for seq in sequences:
            assert len(seq) >= block_size, "sequence shorter than blocksize is useless"
            for p in range(len(seq) - block_size + 1):
                left = seq[p : p + side_count]
                right = seq[p + side_count + 1 : p + block_size]
                samplesX.append(left + right)
                samplesY.append(seq[p + side_count])

        self.x = torch.tensor(samplesX)
        self.y = torch.tensor(samplesY)
        assert len(self.x) == len(self.y)

        if verbose:
            print(f"{len(sequences)} sequences -> {len(self)} blocks")

    def __getitem__(self, index) -> tuple[Tensor, Tensor]:
        return self.x[index], self.y[index]

    def __len__(self):
        return len(self.y)

    def __str__(self) -> str:
        return f"dataset: {len(self)} samples, blocksize: {self.block_size}"


def train_cbow_ff(
    model: CBOWFFModel,
    dl_train: DataLoader,
    dl_val: DataLoader | None,
    label_smoothing=0.0,
    start_lr=1e-2,
    lrs_patience=8,
    stop_patience=12,
    max_iter: int = 1000,
):
    assert stop_patience > lrs_patience + 1, "dont stop before stepping down lr?"

    loss_fn = torch.nn.CrossEntropyLoss(label_smoothing=label_smoothing)

    def loss_batch(xb: Tensor, yb: Tensor):
        pred = model(xb)
        return loss_fn(pred, yb)

    opt = torch.optim.AdamW(model.parameters(), lr=start_lr)
    lrs = torch.optim.lr_scheduler.ReduceLROnPlateau(
        opt, factor=0.5, patience=lrs_patience
    )

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"{device=}")
    model.to(device)

    loss_train = []
    loss_val = []
    lr_hist = []

    best_vl = float("inf")
    best_epoch = 0

    model.train()
    for epoch in range(max_iter):
        loss_agg_va = 0.0

        with torch.no_grad():
            # validation loss
            if dl_val is not None:
                for xb, yb in dl_val:
                    loss_agg_va += loss_batch(xb.to(device), yb.to(device)).item()
        loss_agg_tr = 0.0
        for xb, yb in dl_train:
            loss = loss_batch(xb.to(device), yb.to(device))
            loss.backward()
            opt.step()
            opt.zero_grad()
            loss_agg_tr += loss.item()

        loss_agg_tr /= len(dl_train)
        if dl_val is not None:
            loss_agg_va /= len(dl_val)
        loss_train.append(loss_agg_tr)
        loss_val.append(loss_agg_va)

        # LRS
        lrs.step(loss_agg_va)
        lr_hist.append(opt.param_groups[0]["lr"])

        if loss_agg_va < best_vl:
            best_vl = loss_agg_va
            best_epoch = epoch

        print(
            f"{epoch=: 3d} | Train: {loss_agg_tr:.3f} | Val: {loss_agg_va:.3f}"
            + f" | {best_epoch=: 3d} (Val: {best_vl:.3f}) | LR: {lr_hist[-1]:.1e}\r",
            end="",
        )
        if epoch > best_epoch + stop_patience:
            print("\nEARLY STOPPING")
            break

    print("\ndone")
    if dl_val is None:
        loss_val = None

    return loss_train, loss_val, lr_hist
