import os
import re

try:
    import spaces  # only exists on Hugging Face Spaces; must be imported before torch
    gpu = spaces.GPU(duration=20)
except Exception:
    def gpu(fn):
        return fn

import torch
import gradio as gr
from transformers import AutoTokenizer, AutoModelForSequenceClassification

MODEL_ID = os.environ.get("MODEL_ID", "roshan050/yt-sentiment-roberta")
tok = AutoTokenizer.from_pretrained(MODEL_ID)
model = AutoModelForSequenceClassification.from_pretrained(MODEL_ID).eval()
LABELS = [model.config.id2label[i].lower() for i in range(model.config.num_labels)]

def prep(t):
    t = re.sub(r"https?://\S+", "http", str(t))
    t = re.sub(r"@[\w.\-]+", "@user", t)
    return re.sub(r"\s+", " ", t).strip()

@gpu
def predict(comments):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model.to(device)
    texts = [prep(c) for c in comments[:200]]
    out = []
    with torch.no_grad():
        for i in range(0, len(texts), 32):
            enc = tok(texts[i:i + 32], truncation=True, max_length=96,
                      padding=True, return_tensors="pt").to(device)
            probs = torch.softmax(model(**enc).logits, dim=-1).cpu().tolist()
            for p in probs:
                k = max(range(len(p)), key=lambda j: p[j])
                out.append({"label": LABELS[k],
                            "scores": {LABELS[j]: round(p[j], 4) for j in range(len(p))}})
    return out

demo = gr.Interface(fn=predict, inputs=gr.JSON(), outputs=gr.JSON(), api_name="predict")

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0")