"""Train the Naive Bayes sentiment model.

Usage:
  python train.py                      # uses data/train.csv if present, else NLTK demo corpora
  python train.py --data my_data.csv   # CSV with columns: text + (label | stars)

label must be positive / neutral / negative. If you only have star ratings,
use a 'stars' column: 1-2 -> negative, 3 -> neutral, 4-5 -> positive.
"""
import argparse, json, os, re
import sys, tempfile
import joblib, pandas as pd, sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

LABELS = ["negative", "neutral", "positive"]
URL_RE = re.compile(r"https?://\S+|www\.\S+")
MENTION_RE = re.compile(r"@\w+")


def clean(text: str) -> str:
    text = URL_RE.sub(" ", str(text))
    text = MENTION_RE.sub(" ", text)
    return re.sub(r"\s+", " ", text).strip().lower()


def ensure_nltk(resources):
    """Download NLTK data if missing. resources: list of (find_path, download_name)."""
    import nltk
    for find_path, name in resources:
        try:
            nltk.data.find(find_path)
        except LookupError:
            nltk.download(name, quiet=True)


def load_model(path: str):
    """Load a saved model, but only if it was trained with the same scikit-learn
    version that is installed now (otherwise raise so the caller retrains)."""
    saved = joblib.load(path)
    if not isinstance(saved, dict) or saved.get("sklearn") != sklearn.__version__:
        raise ValueError("saved model is from a different scikit-learn version")
    return saved["model"]


def load_csv(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    if "label" not in df.columns:
        if "stars" not in df.columns:
            raise SystemExit("CSV needs a 'label' or 'stars' column")
        df["label"] = df["stars"].map(lambda s: "negative" if s <= 2 else "neutral" if s == 3 else "positive")
    df = df[["text", "label"]].dropna()
    df["label"] = df["label"].str.lower().str.strip()
    return df[df["label"].isin(LABELS)]


def load_demo() -> pd.DataFrame:
    """Demo data from NLTK corpora: tweets + movie-review sentences for
    positive/negative, objective sentences as 'neutral'."""
    ensure_nltk([("corpora/twitter_samples", "twitter_samples"),
                 ("corpora/subjectivity", "subjectivity"),
                 ("corpora/sentence_polarity", "sentence_polarity")])
    from nltk.corpus import sentence_polarity, subjectivity, twitter_samples
    rows = []
    for t in twitter_samples.strings("positive_tweets.json"): rows.append((t, "positive"))
    for t in twitter_samples.strings("negative_tweets.json"): rows.append((t, "negative"))
    for s in sentence_polarity.sents(categories="pos"): rows.append((" ".join(s), "positive"))
    for s in sentence_polarity.sents(categories="neg"): rows.append((" ".join(s), "negative"))
    for s in subjectivity.sents(categories="obj"): rows.append((" ".join(s), "neutral"))
    return pd.DataFrame(rows, columns=["text", "label"])


def train_and_save(path=None, out="model.joblib"):
    path = path or ("data/train.csv" if os.path.exists("data/train.csv") else None)
    df = load_csv(path) if path else load_demo()
    print(f"Data source: {path or 'NLTK demo corpora'}  rows={len(df)}")
    df["text"] = df["text"].map(clean)
    df = df[df["text"].str.len() > 0]
    print(df["label"].value_counts().to_string())

    X_tr, X_te, y_tr, y_te = train_test_split(
        df["text"], df["label"], test_size=0.2, random_state=42, stratify=df["label"])

    model = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=2, sublinear_tf=True,
                                  token_pattern=r"(?u)\b\w+\b|[^\w\s]")),
        ("nb", MultinomialNB(alpha=0.5)),
    ])
    model.fit(X_tr, y_tr)
    pred = model.predict(X_te)
    acc = accuracy_score(y_te, pred)
    print(f"\nHold-out accuracy: {acc:.4f}")
    print(classification_report(y_te, pred, digits=3))
    print("Confusion matrix (rows=true, cols=pred; order=%s)" % LABELS)
    print(confusion_matrix(y_te, pred, labels=LABELS))

    # refit on everything for the deployed model
    model.fit(df["text"], df["label"])
    payload = {"sklearn": sklearn.__version__, "model": model}
    try:
        joblib.dump(payload, out)
    except OSError:  # e.g. read-only app folder on a hosting service
        out = os.path.join(tempfile.gettempdir(), "model.joblib")
        joblib.dump(payload, out)
    print(f"Saved {out}")
    try:
        with open("metrics.json", "w") as f:
            json.dump({"accuracy": acc, "rows": len(df), "source": path or "nltk-demo"}, f, indent=2)
    except OSError:
        pass
    return model


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=None)
    ap.add_argument("--out", default="model.joblib")
    a = ap.parse_args()
    train_and_save(a.data, a.out)