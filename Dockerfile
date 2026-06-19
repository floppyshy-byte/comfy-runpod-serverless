# Trigger rebuild test
FROM runpod/worker-comfyui:5.8.5-base

# Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends tree libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

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
     pip install -r requirements.txt -q

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

# Efficiency nodes (provides LoRA Stacker node)
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/jags111/efficiency-nodes-comfyui && \
     cd efficiency-nodes-comfyui && \
     pip install -r requirements.txt -q

# rgthree
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/rgthree/rgthree-comfy && \
     cd rgthree-comfy && \
     pip install -r requirements.txt -q

# ── LIGHTWEIGHT CUSTOM NODES (no pip installs) ──────────────────────────────
# Fix numpy conflict + add matplotlib for Comfyroll
RUN pip install -q "numpy>=2.0.0" matplotlib

RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale --recursive

# Comfyroll (provides CR VAE Decode, CR SDXL Aspect Ratio, CR Apply LoRA Stack)
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes

# SaveImageWithMetaData
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/nkchocoai/ComfyUI-SaveImageWithMetaData

# ComfyUI-Custom-Scripts
RUN cd /comfyui/custom_nodes && \
     git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts

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
