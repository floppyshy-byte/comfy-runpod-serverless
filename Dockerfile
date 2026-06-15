FROM runpod/worker-comfyui:5.8.5-base

# Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends tree && rm -rf /var/lib/apt/lists/*

# Prevent custom nodes from auto-downloading models during build
RUN touch /comfyui/custom_nodes/skip_download_model

# ── CUSTOM NODES ─────────────────────────────────────────────────────────────

# ComfyUI-GGUF — supports GGUF quantized models (Q5_K_S, etc.) for low VRAM
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF && \
    cd ComfyUI-GGUF && \
    pip install -r requirements.txt -q

# Shared nodes required by prompt-studio / ModelRouter workflows
# Impact Pack + Subpack (large, has install.py)
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack && \
     cd ComfyUI-Impact-Pack && \
     pip install -r requirements.txt -q && \
     python install.py

RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack && \
     cd ComfyUI-Impact-Subpack && \
     pip install -r requirements.txt -q

# Inspire Pack (provides KSampler //Inspire)
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack && \
     cd ComfyUI-Inspire-Pack && \
     pip install -r requirements.txt -q

# KJNodes (provides ImagePreviewFromLatent+)
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/kijai/ComfyUI-KJNodes && \
     cd ComfyUI-KJNodes && \
     pip install -r requirements.txt -q

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/jags111/efficiency-nodes-comfyui && \
    cd efficiency-nodes-comfyui && \
    pip install -r requirements.txt -q

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes

# Local custom nodes
COPY comfyui_custom_nodes /comfyui/custom_nodes/comfyui_custom_nodes

# ── HANDLER + SETUP ─────────────────────────────────────────────────────────

# Install cryptography for AES-256-GCM payload encryption
RUN pip install --no-cache-dir cryptography

# Override the base image handler with our custom one
COPY handler.py /handler.py
COPY comfy_worker /comfy_worker

# Pre-start hook: runs model setup before the base image starts ComfyUI
COPY pre-start.sh /pre-start.sh
RUN chmod +x /pre-start.sh

# Wrap the original startup so setup runs before ComfyUI starts
ENTRYPOINT ["/pre-start.sh"]
