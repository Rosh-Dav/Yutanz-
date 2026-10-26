# Sentiment Backend

This folder contains the sentiment service used by the Yutanz app. It classifies English YouTube comments as **negative**, **neutral** or **positive** with a fine-tuned RoBERTa model, and exposes the result through a small Gradio API.

You can use it in two ways:
- **Option A:** run it on your own computer.
- **Option B:** host it on your own free Hugging Face Space.

Either way, the app only needs one setting: `SENTIMENT_API_URL`.

---

## What is in this folder

| File | Purpose |
|---|---|
| `app.py` | The Gradio server. Loads the model and serves the `predict` API. |
| `requirements.txt` | Python dependencies for running on your computer. |
| `train_colab.ipynb` | Colab notebook used to fine-tune the model. |
| `METRICS.md` | Evaluation results of the trained model. |

---

## The model

- **Model:** [`roshan050/yt-sentiment-roberta`](https://huggingface.co/roshan050/yt-sentiment-roberta), public on the Hugging Face Hub. No account or token is needed to download it.
- **Base model:** [`cardiffnlp/twitter-roberta-base-sentiment-latest`](https://huggingface.co/cardiffnlp/twitter-roberta-base-sentiment-latest)
- **Training data:** [`AmaanP314/youtube-comment-sentiment`](https://huggingface.co/datasets/AmaanP314/youtube-comment-sentiment) (CC BY-SA 4.0), cleaned to English, without synthetic `_aug` rows.
- **Classes:** `negative`, `neutral`, `positive`.

Results on a held-out test set of 5,186 comments from videos never seen in training:

| Model | Accuracy | Macro-F1 |
|---|---|---|
| VADER (lexicon baseline) | 0.5605 | 0.5329 |
| Original cardiffnlp model | 0.6996 | 0.6902 |
| Fine-tuned model | 0.7601 | 0.7511 |

Limitations: English only; neutral is the hardest class; the training and test labels come from an AI model with some manual validation, so the scores measure agreement with those labels. Full details are in the model card and in the main README.

---

## The API

- **Endpoint name:** `predict`
- **Input:** one JSON list of comment strings. Only the first 200 comments of a request are processed, so split longer lists into chunks of at most 200.
- **Output:** a list with one object per input comment, in the same order. Labels are lowercase.

Example output:

```json
[
  {"label": "positive", "scores": {"negative": 0.0005, "neutral": 0.0013, "positive": 0.9982}},
  {"label": "negative", "scores": {"negative": 0.9902, "neutral": 0.0028, "positive": 0.0070}}
]
```

---

## Option A: Run it on your computer

Requirements: Python 3.10 or newer and about 2 GB of free RAM. A GPU is not needed.

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
python app.py
```

- The first run downloads the model (about 500 MB). Later runs start faster.
- The server starts at `http://localhost:7860`.
- In your app's `.env` file set:

```env
SENTIMENT_API_URL=http://localhost:7860
```

Using it from a device:
- **Android emulator:** use `http://10.0.2.2:7860`.
- **Physical phone on the same Wi-Fi:** use `http://<your-computer-IP>:7860` and allow port 7860 in your firewall. If Android blocks plain `http://` connections, use Option B instead.
- The server listens on all network interfaces. Only run it on networks you trust.

---

## Option B: Host your own Hugging Face Space

### 1. Create the Space
1. Create a free account at [huggingface.co](https://huggingface.co/join) and verify your email.
2. Click your profile picture, then **New Space**.
3. Give it a name (for example `yutanz-sentiment`).
4. Choose **Gradio** as the SDK and the **Blank** template.
5. Choose the hardware your account offers (see the note below) and set visibility to **Public**.
6. Click **Create Space**.

> **Hardware note (check the current Hugging Face docs, as plans can change).** At the time of writing, free personal accounts in good standing (verified email, account older than 30 days) can host up to 2 free ZeroGPU Spaces. Creating a Gradio Space on CPU hardware requires a paid plan. `app.py` works on both ZeroGPU and CPU: on ZeroGPU the `@spaces.GPU` function it contains is required, and on other hardware that line has no effect.

### 2. Upload the files
In your Space, open the **Files** tab and use **Add file, Upload files** (or **Create a new file** and paste the contents):

| Upload this | Name it in the Space |
|---|---|
| `backend/app.py` | `app.py` (replace the existing one if there is one) |
| `backend/requirements.txt` | `requirements.txt` |

Do not replace the `README.md` that Hugging Face created for your Space, because its header contains the Space settings. You may change its `title` line. (`backend/README.md` is only a reference copy of such a header.)

### 3. Wait for the build
The Space builds automatically after the upload. When the status at the top says **Running**, it is ready (the first start downloads the model, so allow a few minutes). If it shows a build error or "Runtime error", open the **Logs** and see Troubleshooting below.

### 4. Get your Space URL
Your URL has this form, in lowercase with hyphens:

```text
https://<your-username>-<your-space-name>.hf.space
```

You can also copy it from the Space page: three-dot menu, **Embed this Space**, **Direct URL**.

### 5. Test it
```python
# pip install gradio_client
from gradio_client import Client

client = Client("<your-username>/<your-space-name>")
print(client.predict(["great video, loved it!", "this is trash, waste of time"],
                     api_name="/predict"))
```

You should get a label and scores for each comment. The first request after the Space has been idle can take a minute.

### 6. Connect the app
In the project root, put your URL in `.env`:

```env
SENTIMENT_API_URL=https://<your-username>-<your-space-name>.hf.space
```

Then run `flutter run`. Keep the Space **Public**: the app does not send a Hugging Face token, so it cannot call a private Space.

---

## Using your own model (optional)

`app.py` reads the model name from the `MODEL_ID` setting and defaults to `roshan050/yt-sentiment-roberta`.

- **On a Space:** open **Settings, Variables and secrets, New variable**, name it `MODEL_ID`, and set its value to `your-username/your-model`. The Space restarts and loads your model.
- **On your computer (Windows PowerShell):**

```powershell
$env:MODEL_ID="your-username/your-model"
python app.py
```

- **On your computer (macOS / Linux):**

```bash
MODEL_ID=your-username/your-model python app.py
```

To train your own model, open `train_colab.ipynb` in [Google Colab](https://colab.research.google.com/) with a GPU runtime and run all cells (about 9 minutes on a free GPU). The notebook prints the accuracy, precision and recall. To publish your model, log in to Hugging Face with your own token inside the notebook. Never put a token in a file you commit.

---

## Costs and limits

- Running locally is free and has no usage quota.
- The model is public on the Hugging Face Hub, and downloading it is free.
- A Space on ZeroGPU is free to host within the limits of your plan. GPU time is counted against the quota of whoever calls it. Anonymous callers (such as the app, which sends no token) get a small daily quota (currently 2 minutes per day, tracked by IP address) and low priority. When it runs out, the API returns a quota error, and the app then uses its on-device sentiment engine instead.
- A Space on paid hardware is billed by the minute while it runs, even if nobody uses it. Pause it or switch the hardware back if you do not need it.
- The YouTube Data API is separate. Every user needs their own key in their own `.env`, and the key must never be committed to the repository.
- Hugging Face plans and quotas can change; check their documentation for the current rules.

---

## Troubleshooting

| Problem | What to try |
|---|---|
| Space shows **Runtime error: No @spaces.GPU function detected** | The Space is on ZeroGPU hardware but is running an `app.py` without a `@spaces.GPU` function. Upload the `app.py` from this folder. |
| Space build fails | Keep the `sdk_version` line in the Space's README header and keep `requirements.txt` containing only `transformers`. |
| `gradio_client` says the Space is in an invalid state | Open the Space page, read the red error message and the Logs, fix the cause, then wait for **Running**. |
| First request is very slow | The Space or the model is waking up. Wait a minute and retry. |
| Quota exceeded error | The daily GPU quota for your IP is used up. Wait for it to reset, or run the backend locally (Option A). |
| App cannot reach `localhost` from a phone | Use your computer's IP address or the emulator address (see Option A). |
| Model download is slow or fails | Check your internet connection and retry. The model is about 500 MB. |
| Unexpected predictions | The model is English only, and neutral is the hardest class. |

---

## Privacy and security

- `app.py` does not store or log the comments it receives.
- A public Space can be called by anyone who knows its URL. It only returns sentiment predictions; it exposes no secrets, as long as you never put tokens or keys in the Space files.
- Never commit `.env`, tokens, or keys to GitHub.

---

## Credits and licenses

- Base model: [cardiffnlp/twitter-roberta-base-sentiment-latest](https://huggingface.co/cardiffnlp/twitter-roberta-base-sentiment-latest)
- Training data: [AmaanP314/youtube-comment-sentiment](https://huggingface.co/datasets/AmaanP314/youtube-comment-sentiment) (CC BY-SA 4.0)
- Fine-tuned model: [roshan050/yt-sentiment-roberta](https://huggingface.co/roshan050/yt-sentiment-roberta)