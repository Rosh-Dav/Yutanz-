# 📊 Yutanz

<p align="center">
  <strong>Modern YouTube Analytics & AI Comment Sentiment Intelligence for Creators and Marketers</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Python-3.9+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Hive-NoSQL%20Cache-FFA000?style=for-the-badge&logo=hive&logoColor=white" alt="Hive" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

---

## 📱 App Screenshots

<table align="center">
  <tr>
    <td align="center" width="25%">
      <img src="screenshots/01_home_search.png" alt="Home & Channel Search" width="100%" />
      <br /><strong>1. Channel Search</strong>
    </td>
    <td align="center" width="25%">
      <img src="screenshots/02_channel_dashboard.png" alt="Channel Overview Dashboard" width="100%" />
      <br /><strong>2. Channel Dashboard</strong>
    </td>
    <td align="center" width="25%">
      <img src="screenshots/03_videos_list.png" alt="Full Videos Catalogue" width="100%" />
      <br /><strong>3. Videos Catalogue</strong>
    </td>
    <td align="center" width="25%">
      <img src="screenshots/04_videos_filtered_tab.png" alt="Long-Form Videos Filter" width="100%" />
      <br /><strong>4. Long-form Videos</strong>
    </td>
  </tr>
  <tr>
    <td align="center" width="25%">
      <img src="screenshots/05_shorts_grid_view.png" alt="YouTube Shorts 2-Column Grid" width="100%" />
      <br /><strong>5. Shorts Grid</strong>
    </td>
    <td align="center" width="25%">
      <img src="screenshots/06_video_details.png" alt="Video Details & Metrics" width="100%" />
      <br /><strong>6. Video Performance</strong>
    </td>
    <td align="center" width="25%">
      <img src="screenshots/07_sentiment_analysis.png" alt="AI Sentiment Analysis" width="100%" />
      <br /><strong>7. Sentiment Analysis</strong>
    </td>
    <td align="center" width="25%">
      <img src="screenshots/08_channel_insights.png" alt="Channel Insights & Frequency" width="100%" />
      <br /><strong>8. Channel Insights</strong>
    </td>
  </tr>
</table>

---

## ✨ Key Features

### 1. 📈 Channel Overview & Dashboard
- **Channel Header:** View high-res avatar, verified badge, subscriber count, and bio.
- **Key Metrics Grid:** Total views (e.g. 5.8B), public videos count, average engagement rate, and average likes per video.
- **Quick Insights:** Exact channel launch date, average views per video, and total lifetime engagement.
- **Recent Uploads:** Quick previews of recent videos with duration badges, view counts, and engagement tags.

### 2. 🎬 Smart Videos & Shorts Categorization
- **YouTube-Style Category Tabs:**
  - **All Uploads:** Full pagination across the entire library with no arbitrary video caps.
  - **Videos:** Dedicated filter for standard long-form videos.
  - **Shorts:** Dedicated 2-column portrait (9:16) grid for YouTube Shorts (≤180s) with duration overlays.
- **Multi-Criteria Sorting:** Sort by **Latest**, **Oldest** (with First Upload spotlight), **Popular**, **Likes**, and **Engagement Rate**.
- **Transparency Notice:** Shows public video count alongside any private/unlisted videos.

### 3. 🎯 Robust Engagement & Performance Metrics
- **Mathematical Accuracy:** Engagement Rate = `((Likes + Comments) / Views) * 100`.
- **Hidden Likes Protection:** Videos where creators disabled like counts are detected automatically:
  - Displays `Hidden / N/A` badges instead of misleading `0%` or false "Below Average" ratings.
  - Excluded from channel average calculations so they do not artificially depress channel metrics.
  - Cleanly placed at the end when sorting by likes or engagement.
- **Performance Rating Tiers:** Benchmark grading (**Exceptional >10%**, **Excellent >5%**, **Good >2%**, **Average >1%**, **Below Average <1%**) with tailored recommendations.

### 4. 🧠 ML-Powered Comment Sentiment Analysis
- **Hybrid AI Engine:** Powered by an ensemble backend combining **VADER** and **TF-IDF + Naive Bayes**.
- **Comprehensive Coverage:** Analyzes up to **50 comments** per video, including both top-level comments and comment replies.
- **Polished Sentiment Distribution:** Donut chart showing exact percentage breakdowns for Positive, Neutral, and Negative sentiments with zero visual overlap.
- **Key Community Highlights:**
  - **Top Positive Comments:** Ranked by confidence score and like count.
  - **Top Negative Comments:** Immediate visibility into critical viewer feedback.
  - **Frequent Words Cloud:** Word frequency chips highlighting active discussion topics.

### 5. 📊 Deep Channel Insights & Trends
- **12-Month Upload Frequency:** Monthly bar chart displaying upload volume over the past 12 months with monthly average and total count.
- **Top Keywords & Tags:** Tag frequency analysis identifying the most utilized content keywords for SEO optimization.
- **Performance Distribution:** View count categorization into **Viral (>100K)**, **High (10K–100K)**, **Moderate (1K–10K)**, and **Low (<1K)**.
- **Top Performing Videos:** Switch ranking criteria between **Engagement Rate**, **Total Views**, and **Total Likes**.

### 6. ⚡ Smart Local Caching (Hive NoSQL)
- Instant sub-second loading for revisited channels, video lists, and sentiment reports.
- Full offline persistence: preserves sentiment breakdowns, word frequencies, and top positive/negative comments.
- Quota-friendly: prevents redundant YouTube API quota consumption.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.x, Dart 3.x |
| **State Management** | `Provider` architecture |
| **Local Database** | `hive` & `hive_flutter` (Lightweight NoSQL key-value store) |
| **Charts & Graphics** | `fl_chart`, `flutter_animate`, `shimmer` |
| **Backend & ML** | Python 3.9+, Gradio / FastAPI, NLTK VADER, Scikit-learn |
| **Data Source** | YouTube Data API v3 |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0 or higher)
- [Python 3.9+](https://www.python.org/)
- Google Cloud Console [YouTube Data API v3 Key](https://console.cloud.google.com/)

---

### Step-by-Step Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/your-username/yutanz.git
cd yutanz
```

#### 2. Start the Python Sentiment Backend
The ML backend is located in the `backend/` directory:
```bash
cd backend
pip install -r requirements.txt
python app.py
```
The sentiment service will start at `http://localhost:7860`.

> 💡 **Tip:** You can also deploy `backend/` to a free [Hugging Face Space](https://huggingface.co/spaces) using the Gradio SDK and use your public Space URL.

#### 3. Configure Environment Variables
Return to the project root directory and create a `.env` file:
```bash
cd ..
cp .env.example .env
```
Edit `.env` with your credentials:
```env
# Your YouTube Data API v3 key
YOUTUBE_API_KEY=your_youtube_api_key_here

# Sentiment backend endpoint (local or Hugging Face Space URL)
SENTIMENT_API_URL=http://localhost:7860
```

#### 4. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

---

## 📁 Project Architecture

```text
Yt_Analyzer/
├── backend/                       # Python Sentiment Backend
│   ├── app.py                     # Gradio / FastAPI server
│   ├── train.py                   # Model training script
│   └── requirements.txt           # Python dependencies
├── lib/                           # Flutter Core
│   ├── models/                    # Data models
│   │   ├── analytics_model.dart   # ChannelAnalytics & SentimentAnalysis
│   │   ├── channel_model.dart     # Channel details
│   │   ├── comment_model.dart     # Comment structure & reply parser
│   │   └── video_model.dart       # Video metadata & engagement logic
│   ├── providers/                 # State management
│   │   ├── channel_provider.dart  # Channel & videos state
│   │   └── video_provider.dart    # Video comments & sentiment state
│   ├── screens/                   # User Interfaces
│   │   ├── dashboard_screen.dart  # Home & channel dashboard
│   │   ├── videos_screen.dart     # Videos & Shorts categorized tabs
│   │   ├── video_details_screen.dart # Performance & metrics
│   │   ├── sentiment_screen.dart  # Sentiment breakdown & charts
│   │   └── insights_screen.dart   # Frequency & top video insights
│   ├── services/                  # Network & Cache services
│   │   ├── youtube_api_service.dart # YouTube Data API v3 client
│   │   ├── sentiment_api_service.dart # Gradio API client
│   │   ├── sentiment_service.dart # On-device sentiment fallback
│   │   └── cache_service.dart     # Hive local database manager
│   ├── utils/                     # Formatting, helpers, transitions
│   └── widgets/                   # Reusable UI components
├── screenshots/                   # App demonstration screenshots
├── .env.example                   # Environment template
└── pubspec.yaml                   # Flutter dependencies
```

---

## 🔒 Security & Best Practices

- **`.env` Ignored in Version Control:** Credentials are kept strictly local through `.gitignore`.
- **API Quota Optimization:** Hive caching prevents unnecessary repetitive requests to YouTube API.
- **Fail-Safe Fallbacks:** The app includes a built-in on-device rule-based sentiment engine if the remote Python backend is unreachable.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
