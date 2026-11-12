"""CU11/RF05: descritores reais MobileNetV3, sem identificar automaticamente o animal."""
import hashlib
import io
import os
import secrets
import threading
from contextlib import asynccontextmanager
from pathlib import Path

import numpy as np
import torch
from fastapi import FastAPI, Header, HTTPException, Request
from PIL import Image, ImageOps, UnidentifiedImageError
from torchvision.models import MobileNet_V3_Small_Weights, mobilenet_v3_small

Image.MAX_IMAGE_PIXELS = 40_000_000
TOKEN = os.environ.get('IA_TOKEN', '')
CACHE = Path(os.environ.get('DESCRIPTOR_CACHE', '../.runtime/descriptors'))
lock = threading.Lock()
model = None
transform = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global model, transform
    if len(TOKEN) < 24:
        raise RuntimeError('Configure IA_TOKEN com pelo menos 24 caracteres.')
    CACHE.mkdir(parents=True, exist_ok=True)
    torch.set_num_threads(min(4, os.cpu_count() or 1))
    weights = MobileNet_V3_Small_Weights.IMAGENET1K_V1
    model = mobilenet_v3_small(weights=weights).eval()
    transform = weights.transforms()
    with torch.inference_mode():
        model.features(torch.zeros(1, 3, 224, 224))
    yield


app = FastAPI(title='MIAR - Análise de imagens', docs_url=None, redoc_url=None, lifespan=lifespan)


def descriptor(data: bytes) -> list[float]:
    key = hashlib.sha256(data).hexdigest()
    cached = CACHE / f'mobilenet-v3-small-v1-{key}.npy'
    if cached.exists():
        return np.load(cached, allow_pickle=False).tolist()
    try:
        im = Image.open(io.BytesIO(data))
        im.load()
        if min(im.size) < 32:
            raise ValueError('Fotografia muito pequena.')
        im = ImageOps.exif_transpose(im).convert('RGB')
        tensor = transform(im).unsqueeze(0)
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
        raise HTTPException(422, 'Fotografia inadequada para análise.')
    with lock, torch.inference_mode():
        vector = model.avgpool(model.features(tensor)).flatten(1)[0]
        vector = torch.nn.functional.normalize(vector, dim=0).cpu().numpy().astype(np.float32)
    # Cache derivado pode ser eliminado e reconstituído, não é entidade do domínio.
    temp = cached.with_suffix(f'.{secrets.token_hex(4)}.tmp')
    with temp.open('wb') as f:
        np.save(f, vector, allow_pickle=False)
    temp.replace(cached)
    return vector.tolist()


@app.get('/health')
def health():
    return {'ready': model is not None, 'model': 'mobilenet_v3_small-imagenet1k-v1', 'dimensions': 576}


@app.post('/descriptor')
async def analyze(request: Request, authorization: str = Header(default='')):
    if not secrets.compare_digest(authorization, f'Bearer {TOKEN}'):
        raise HTTPException(401, 'Acesso interno não autorizado.')
    data = bytearray()
    async for chunk in request.stream():
        data.extend(chunk)
        if len(data) > 10 * 1024 * 1024:
            raise HTTPException(413, 'Fotografia excede o limite técnico de envio.')
    # Executa a inferência fora do event loop do serviço HTTP.
    from starlette.concurrency import run_in_threadpool
    vector = await run_in_threadpool(descriptor, bytes(data))
    return {'vetor': vector, 'modelo': 'mobilenet_v3_small-imagenet1k-v1'}
