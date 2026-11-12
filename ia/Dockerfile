FROM python:3.12-slim
WORKDIR /service
COPY requirements.txt .
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu && pip install --no-cache-dir -r requirements.txt
COPY main.py .
RUN python -c "from torchvision.models import mobilenet_v3_small, MobileNet_V3_Small_Weights; mobilenet_v3_small(weights=MobileNet_V3_Small_Weights.IMAGENET1K_V1)"
RUN useradd --system --uid 10001 miar && mkdir -p /data/descriptors && chown -R miar /data
ENV DESCRIPTOR_CACHE=/data/descriptors
USER miar
EXPOSE 8001
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
