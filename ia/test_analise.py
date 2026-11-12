import io
import numpy as np
from PIL import Image, ImageEnhance
from fastapi.testclient import TestClient
from main import app, TOKEN
from pathlib import Path


def test_descritores_reais_e_erros():
    root = Path(__file__).resolve().parent.parent
    dog = (root / 'prototipos/assets/img/ocorrencia-cao-grande.jpg').read_bytes()
    cat = (root / 'prototipos/assets/img/ocorrencia-gato-filhote.jpg').read_bytes()
    headers = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'image/jpeg'}
    with TestClient(app) as client:
        assert client.post('/descriptor', content=dog).status_code == 401
        assert client.post('/descriptor', content=b'invalida', headers=headers).status_code == 422
        first = np.array(client.post('/descriptor', content=dog, headers=headers).json()['vetor'])
        second = np.array(client.post('/descriptor', content=dog, headers=headers).json()['vetor'])
        different = np.array(client.post('/descriptor', content=cat, headers=headers).json()['vetor'])
        assert len(first) == 576
        assert np.allclose(first, second)
        assert np.isclose(np.linalg.norm(first), 1, atol=1e-5)
        assert float(first @ different) < .90
        buf = io.BytesIO()
        ImageEnhance.Brightness(Image.open(io.BytesIO(dog))).enhance(.9).save(buf, format='JPEG')
        altered = np.array(client.post('/descriptor', content=buf.getvalue(), headers=headers).json()['vetor'])
        assert float(first @ altered) > .90
