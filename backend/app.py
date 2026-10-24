"""Sentiment service (Gradio Space): VADER (lexicon) + Naive Bayes (trained) ensemble.

API used by the Flutter app (Gradio HTTP API):
  POST /gradio_api/call/analyze   body: {"data": ["<json string of comments>"]}  -> {"event_id": "..."}
  GET  /gradio_api/call/analyze/<event_id>                                      -> server-sent event with the result
"""
import json
import os

# pyrefly: ignore[missing-import]
import spaces

import gradio as gr
from nltk.sentiment.vader import SentimentIntensityAnalyzer

from train import clean, ensure_nltk, load_model, train_and_save

MAX_COMMENTS = 500
MAX_CHARS = 1000
VADER_T = 0.05      # standard VADER thresholds
ENSEMBLE_T = 0.15   # threshold used when the two models disagree
NB_CONFIDENT = 0.80 # NB must be this sure to override a neutral VADER result

ensure_nltk([("sentiment/vader_lexicon.zip", "vader_lexicon")])
_vader = SentimentIntensityAnalyzer()

MODEL_PATH = os.environ.get("MODEL_PATH", "model.joblib")
try:
    _model = load_model(MODEL_PATH)
    print("Loaded saved model")
except Exception as e:
    # Model file missing or built with another scikit-learn version -> retrain
    print(f"Training a fresh model ({e})")
    _model = train_and_save(out=MODEL_PATH)
_classes = [str(c) for c in _model.classes_]


def vader_label(c: float) -> str:
    return "positive" if c >= VADER_T else "negative" if c <= -VADER_T else "neutral"


def combine(compound: float, nb_probs: dict, nb_label: str, v_label: str):
    """Ensemble rule:
    1. Both models agree -> use that label.
    2. VADER sees no sentiment words (neutral) -> trust Naive Bayes only if it is
       very confident (>= NB_CONFIDENT), otherwise stay neutral.
    3. VADER is polar but NB disagrees -> weighted average of both scores."""
    nb_score = nb_probs.get("positive", 0.0) - nb_probs.get("negative", 0.0)
    score = 0.5 * compound + 0.5 * nb_score
    if nb_label == v_label:
        return nb_label, score
    if v_label == "neutral":
        if nb_probs[nb_label] >= NB_CONFIDENT:
            return nb_label, score
        return "neutral", score
    label = "positive" if score >= ENSEMBLE_T else "negative" if score <= -ENSEMBLE_T else "neutral"
    return label, score


@spaces.GPU
def analyze_items(items: list) -> dict:
    """items: list of strings or {"id": ..., "text": ...} dicts."""
    if len(items) > MAX_COMMENTS:
        raise gr.Error(f"Max {MAX_COMMENTS} comments per request")
    ids = [i.get("id") if isinstance(i, dict) else None for i in items]
    texts = [str(i.get("text", "") if isinstance(i, dict) else i)[:MAX_CHARS] for i in items]
    probs = _model.predict_proba([clean(t) or " " for t in texts]) if texts else []

    results, counts = [], {"positive": 0, "neutral": 0, "negative": 0}
    for cid, text, p in zip(ids, texts, probs):
        compound = _vader.polarity_scores(text)["compound"]
        v_lab = vader_label(compound)
        nb_probs = {c: float(x) for c, x in zip(_classes, p)}
        nb_lab = max(nb_probs, key=nb_probs.get)
        label, score = combine(compound, nb_probs, nb_lab, v_lab)
        counts[label] += 1
        results.append({
            "id": cid, "label": label, "score": round(score, 4),
            "vader": {"compound": compound, "label": v_lab},
            "naive_bayes": {"label": nb_lab, "probabilities": {k: round(v, 4) for k, v in nb_probs.items()}},
        })
    n = len(results) or 1
    return {
        "total": len(results),
        "counts": counts,
        "percentages": {k: round(v * 100 / n, 2) for k, v in counts.items()},
        "results": results,
    }


def analyze_api(comments_json: str) -> dict:
    """API endpoint. comments_json = JSON list of strings or {"id","text"} objects."""
    try:
        items = json.loads(comments_json)
        if not isinstance(items, list):
            raise ValueError
    except ValueError:
        raise gr.Error("Send a JSON list of comments")
    return analyze_items(items)


def analyze_ui(text: str):
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    out = analyze_items(lines)
    return [[l, r["label"], r["score"], r["vader"]["label"], r["naive_bayes"]["label"]]
            for l, r in zip(lines, out["results"])]


with gr.Blocks(title="YT Analyzer Sentiment API") as demo:
    gr.Markdown("# YT Analyzer - Sentiment API\nVADER + Naive Bayes. Try it here:")

    # ── Interactive UI ────────────────────────────────────────────────────────
    box = gr.Textbox(lines=8, label="Comments (one per line)")
    btn = gr.Button("Analyze")
    table = gr.Dataframe(
        headers=["Comment", "Final", "Score", "VADER", "Naive Bayes"], wrap=True
    )
    btn.click(analyze_ui, inputs=box, outputs=table, api_name=False)

    # ── JSON API endpoint used by the Flutter app ─────────────────────────────
    # Exposed as POST /gradio_api/call/analyze
    # Input:  a JSON string (list of {"id": ..., "text": ...} objects)
    # Output: a dict with counts, percentages, and per-comment results
    with gr.Row(visible=False):
        _api_in  = gr.Textbox(label="comments_json")
        _api_out = gr.JSON(label="result")
    _api_in.submit(analyze_api, inputs=_api_in, outputs=_api_out, api_name="analyze")

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",
        server_port=int(os.environ.get("PORT", 7860)),
        ssr_mode=False,
    )