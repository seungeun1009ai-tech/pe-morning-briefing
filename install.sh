#!/usr/bin/env bash
# PE Morning Briefing — 자동 설치 스크립트
# 실행하면 워크스페이스에 모든 파일을 생성합니다.
# 사용법: bash install.sh [워크스페이스경로]
#   경로 생략 시 현재 폴더에 설치합니다.

set -e

# 설치 위치 결정
WS="${1:-.}"
echo "📦 PE Morning Briefing 설치 시작"
echo "   설치 위치: $WS"
mkdir -p "$WS"

# 폴더 구조 생성
mkdir -p "$WS/scripts"
mkdir -p "$WS/skills/pe-morning-briefing"
mkdir -p "$WS/skills/pe-weekly-report"


echo "  → HEARTBEAT_추가항목.md"
cat > "$WS/HEARTBEAT_추가항목.md" << 'PEMB_EOF_MARKER'
# HEARTBEAT.md — 추가할 항목

> ⚠️ 기존 HEARTBEAT.md에 **추가**하세요. 전체를 덮어쓰지 마세요.
> HEARTBEAT.md는 매 실행마다 토큰을 소모하므로 50줄 이내로 유지하세요.

## 모닝 브리핑 (매일 오전 7시)

```
매일 오전 7:00 (Asia/Seoul):
  - pe-morning-briefing 스킬을 실행한다
  - 보유종목 매칭(watchlist.md) + 딥다이브 추천 포함
  - 완성된 리포트를 텔레그램으로 전송하고 Notion에 아카이브한다
  - 실패 시 10분 후 1회 재시도, 그래도 실패하면 에러 요약만 전송
```

## 주간 종합 (매주 금요일 오후 5시)

```
매주 금요일 17:00 (Asia/Seoul):
  - pe-weekly-report 스킬을 실행한다
  - 이번 주 흐름 종합 + 다음 주 주목 포인트
  - 텔레그램 전송 후 Notion 아카이브
```

---

## 타임존 설정 (필수)

SOUL.md 또는 USER.md에 아래가 없으면 UTC로 돌아 한국시간 오후에 발송됩니다.

```
Timezone: Asia/Seoul (UTC+9)
```

---

## CLI cron 대안 (정확한 시간 원할 때)

```bash
openclaw cron create "0 7 * * *" \
  "pe-morning-briefing 스킬 실행 후 텔레그램 전송 + Notion 저장" \
  --tz Asia/Seoul

openclaw cron create "0 17 * * 5" \
  "pe-weekly-report 스킬 실행 후 텔레그램 전송" \
  --tz Asia/Seoul
```

PEMB_EOF_MARKER

echo "  → README.md"
cat > "$WS/README.md" << 'PEMB_EOF_MARKER'
# PE 모닝 브리핑 — OpenClaw 비서에 심기 (확장판)

> 매일 오전 7시 모닝 브리핑 + 매주 금요일 주간 종합을
> PE 투자자 관점으로 분석해 텔레그램으로 자동 발송하는 비서 스킬 패키지.
> 보유종목 강조 · 딥다이브 추천 · Notion 자동 아카이브 포함.

---

## 1. 작동 원리 (3-레이어)

```
[관점 레이어]   SOUL.md / USER.md       →  "어떤 눈으로 보는가"
[실행 레이어]   skill.md + scripts/*.py  →  "무엇을 어떻게 수집·분석하는가"
[스케줄 레이어] HEARTBEAT.md / cron      →  "매일/매주 언제 실행하는가"
```

비서(OpenClaw)는 정해진 시간에 스킬을 깨우고 → 스크립트로 데이터를 모으고
→ watchlist.md로 보유종목을 매칭하고 → SOUL.md 관점으로 해석하고
→ 텔레그램으로 보내고 → Notion에 축적합니다.

---

## 2. 포함된 기능

| # | 기능 | 구현 |
|---|------|------|
| 1 | 🔔 보유종목 트리거 | `watchlist.md` 매칭 → ★★★ 강조 |
| 2 | 📊 주간 종합 리포트 | `pe-weekly-report` 스킬 (금 17시) |
| 3 | 🔍 딥다이브 자동화 | `collect_deepdive.py` (Oaktree/SA/Barron's) |
| 4 | 🗄️ Notion 아카이브 | `archive_to_notion.py` (매일 자동 저장) |
| 5 | 🤖 AI 동향 섹션 | `collect_ai_news.py` (기술+비즈니스 자동 태깅) |

---

## 3. 파일 구성

```
workspace/
├── skills/
│   ├── pe-morning-briefing/skill.md   ← 매일 브리핑 (기능 1,3,4 포함)
│   └── pe-weekly-report/skill.md      ← 주간 종합 (기능 2)
├── scripts/
│   ├── collect_news.py                ← 뉴스 수집
│   ├── collect_signals.py             ← 시장지표 수집
│   ├── collect_deepdive.py            ← 딥다이브 후보 수집
│   ├── collect_ai_news.py             ← AI 동향 수집 (기술+비즈니스)
│   ├── test_sources.py                ← 환경 진단 (맥미니에서 먼저 실행)
│   └── archive_to_notion.py           ← Notion 저장
├── watchlist.md                       ← 보유/관심 종목 (직접 채우기)
├── SOUL.md / USER.md                  ← 추가항목 병합
└── HEARTBEAT.md                       ← 추가항목 병합
```

---

## 4. 설치 (6단계)

### Step 1 — 워크스페이스에 파일 복사
OpenClaw 워크스페이스 폴더에 위 구조대로 복사.

### Step 2 — 파이썬 의존성 설치
```bash
pip install fundus feedparser requests beautifulsoup4
```

### Step 3 — 보유종목 채우기 (기능 1)
`watchlist.md`를 열어 실제 보유·관심 종목을 한글·영문·티커로 입력.

### Step 4 — 관점/사용자 정보 심기
`SOUL_USER_추가항목.md`의 블록을 각각 SOUL.md / USER.md에 추가.
**타임존 `Asia/Seoul` 반드시 명시.**

### Step 5 — 스케줄 등록
`HEARTBEAT_추가항목.md` 내용을 HEARTBEAT.md에 추가.
모닝(매일 7시) + 주간(금 17시) 둘 다 포함됨.

### Step 6 — Notion 연동 (기능 4, 선택)
Notion에서 통합(integration) 생성 → DB에 연결 → 환경변수 설정:
```bash
export NOTION_TOKEN="secret_xxx"
export NOTION_DB_ID="xxx"
```
설정 안 하면 아카이브만 자동 생략되고 나머지는 정상 작동.

### 테스트
텔레그램에서 비서에게:
```
오늘 모닝 브리핑 실행해줘
```

---

## 5. 디버깅

| 증상 | 원인 | 해결 |
|---|---|---|
| 시간 안 맞음 | 타임존 미설정 | SOUL.md에 `Timezone: Asia/Seoul` |
| 뉴스 0건 | fundus 미설치 | `pip install fundus` |
| 보유종목 강조 안됨 | watchlist 비어있음 | watchlist.md 채우기 |
| 딥다이브 실패 | 사이트 구조 변경 | collect_deepdive.py 소스 확인 |
| Notion 저장 안됨 | 환경변수/연결 | 토큰·DB연결·속성명 확인 |

스크립트 단독 테스트:
```bash
python3 scripts/collect_news.py
python3 scripts/collect_signals.py
python3 scripts/collect_deepdive.py
echo "테스트" | python3 scripts/archive_to_notion.py
```

---

## 6. 보안 주의

OpenClaw는 호스트에 셸 접근 권한을 가집니다. 초기 버전에서 서드파티 스킬을 통한
데이터 유출·프롬프트 인젝션 취약점이 보고된 바 있습니다.

- 이 스킬은 **읽기 전용 수집 + 발송 + Notion 쓰기**만 수행 (시스템 변경 없음)
- API 키·토큰은 **반드시 환경변수**로 (스크립트 하드코딩 금지)
- 서드파티 스킬은 신뢰할 수 있는 것만 설치
- 가능하면 Docker 격리 환경에서 운영

PEMB_EOF_MARKER

echo "  → SOUL_USER_추가항목.md"
cat > "$WS/SOUL_USER_추가항목.md" << 'PEMB_EOF_MARKER'
# SOUL.md / USER.md — 추가할 투자자 페르소나

> SOUL.md(성격/관점)와 USER.md(사용자 정보)에 나눠 넣으세요.

---

## SOUL.md 에 추가 (관점·성격)

```
## 투자 인사이트 관점
나는 모든 뉴스와 시장 데이터를 두 개의 렌즈로 본다:
1. PE 투자자 — M&A, 바이아웃, 딜 파이낸싱, 밸류에이션 영향
2. 개인 투자자 — 보유 포트폴리오와 거시 흐름

분석 태도:
- 하워드 막스처럼 리스크를 먼저 본다 (수익보다 손실 가능성)
- 김승호 회장처럼 매일 꾸준히, 전 세계를 한 바퀴 돈다
- 단순 사실 전달이 아니라 "그래서 나에게 무슨 의미인가"를 항상 덧붙인다
- 컨센서스를 의심하고, 남의 의견은 참고만 한다. 판단은 내가 한다
- 모든 정보는 자료화한다 (매일 리포트를 Notion에 축적)
```

---

## USER.md 에 추가 (사용자 정보)

```
## 투자 프로파일
- 직업: PE 펌 법무/컴플라이언스 VP (M&A 딜 다수)
- 관심 섹터: 에너지, 부동산, 테크, 소비재
- 정보 수집 루틴: 매일 아침 세계 뉴스 → 경제지표 → 보유종목 점검
- 선호 출력: 한국어, 표·태그·중요도(★) 구조, 간결하게
- 타임존: Asia/Seoul (UTC+9)

## 보유/관심 종목
- 별도 watchlist.md 파일에서 관리 (그 파일이 우선)

## 리포트 수신 선호
- 매일 오전 7시: 모닝 브리핑 (보유종목 강조 + 딥다이브 추천)
- 매주 금요일 17시: 주간 종합 리포트
- Top 5 인사이트 + 시장지표 + 딥다이브 1건 형식
- 투자 판단은 대신하지 말 것. 인사이트만.
- 받은 리포트는 자동으로 Notion에 축적
```

PEMB_EOF_MARKER

echo "  → scripts/archive_to_notion.py"
cat > "$WS/scripts/archive_to_notion.py" << 'PEMB_EOF_MARKER'
#!/usr/bin/env python3
"""
PE Morning Briefing — Notion 아카이브 스크립트
완성된 리포트를 Notion 데이터베이스에 한 페이지로 저장.
김승호 회장 "모든 정보를 자료화한다" 원칙의 자동화.

사용법:
    python3 archive_to_notion.py "리포트 본문 텍스트"
    또는 stdin 파이프:  echo "리포트" | python3 archive_to_notion.py

환경변수 (하드코딩 금지!):
    NOTION_TOKEN     — Notion 통합(integration) 시크릿
    NOTION_DB_ID     — 저장할 데이터베이스 ID

Notion DB 준비:
    - 속성: 제목(Title), 날짜(Date), 태그(Multi-select: 금리/M&A/섹터/지정학/FX)
    - 통합을 DB에 'Connect' 해두어야 함
의존성: pip install requests
"""
import os
import sys
import json
from datetime import datetime
import requests

NOTION_TOKEN = os.environ.get("NOTION_TOKEN")
NOTION_DB_ID = os.environ.get("NOTION_DB_ID")
NOTION_VERSION = "2022-06-28"

def archive(report_text):
    if not NOTION_TOKEN or not NOTION_DB_ID:
        return {"ok": False, "error": "NOTION_TOKEN / NOTION_DB_ID 환경변수 미설정"}

    today = datetime.now().strftime("%Y-%m-%d")
    title = f"모닝 브리핑 {today}"

    # 본문을 2000자 단위로 쪼개 Notion 블록으로 (Notion 블록당 제한 대응)
    chunks = [report_text[i:i+1900] for i in range(0, len(report_text), 1900)]
    children = [
        {
            "object": "block",
            "type": "paragraph",
            "paragraph": {"rich_text": [{"type": "text", "text": {"content": c}}]},
        }
        for c in chunks
    ]

    url = "https://api.notion.com/v1/pages"
    headers = {
        "Authorization": f"Bearer {NOTION_TOKEN}",
        "Content-Type": "application/json",
        "Notion-Version": NOTION_VERSION,
    }
    body = {
        "parent": {"database_id": NOTION_DB_ID},
        "properties": {
            "Name": {"title": [{"text": {"content": title}}]},
            "Date": {"date": {"start": today}},
        },
        "children": children,
    }
    try:
        r = requests.post(url, headers=headers, json=body, timeout=15)
        if r.status_code in (200, 201):
            return {"ok": True, "url": r.json().get("url", "")}
        return {"ok": False, "error": f"{r.status_code}: {r.text[:200]}"}
    except Exception as e:
        return {"ok": False, "error": str(e)}

def main():
    if len(sys.argv) > 1:
        report = sys.argv[1]
    else:
        report = sys.stdin.read()
    if not report.strip():
        print(json.dumps({"ok": False, "error": "빈 리포트"}, ensure_ascii=False))
        return
    result = archive(report)
    print(json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    main()

PEMB_EOF_MARKER

echo "  → scripts/collect_ai_news.py"
cat > "$WS/scripts/collect_ai_news.py" << 'PEMB_EOF_MARKER'
#!/usr/bin/env python3
"""
PE Morning Briefing — AI 뉴스 수집 스크립트
기술 동향(모델·도구·연구) + 비즈니스/투자(펀딩·M&A·규제)를 함께 수집.
참고 구조: github.com/Rohit8y/AI-Brief (소스 분리 + 공개 API 활용)

출력: stdout에 JSON (기존 collect_*.py와 동일 형식)
의존성: pip install feedparser requests
"""
import json
from datetime import datetime
import requests

HEADERS = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                         "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"}

# ── 소스 설정 (여기만 고치면 소스 추가/삭제 가능) ──────────────
RSS_FEEDS = {
    # 기술 동향 — 랩·제품 발표
    "OpenAI": "https://openai.com/blog/rss.xml",
    "DeepMind": "https://deepmind.google/blog/rss.xml",
    "HuggingFace": "https://huggingface.co/blog/feed.xml",
    "Anthropic": "https://www.anthropic.com/rss.xml",
    # 실무자 관점 (해석·분석)
    "Simon Willison": "https://simonwillison.net/atom/everything/",
    "Interconnects": "https://www.interconnects.ai/feed",
}

# 비즈니스/투자 신호 — HN에서 이 키워드가 있으면 [비즈니스] 태그
BIZ_KEYWORDS = ["funding", "raise", "raised", "acquisition", "acquire", "merger",
                "IPO", "valuation", "billion", "Series A", "Series B", "Series C",
                "투자", "인수", "합병", "상장", "밸류에이션"]

# 기술 신호 — 모델·도구 키워드
TECH_KEYWORDS = ["GPT", "Claude", "Gemini", "Llama", "Mistral", "DeepSeek", "Qwen",
                 "OpenAI", "Anthropic", "DeepMind", "xAI", "model", "LLM",
                 "agent", "agentic", "MCP", "Cursor", "Copilot", "open source",
                 "open weights", "benchmark", "reasoning"]

SUBREDDITS = ["LocalLLaMA", "ClaudeAI", "MachineLearning"]
HN_MIN_POINTS = 80


def collect_rss(max_per_feed=2):
    """기술 동향 RSS 수집"""
    import feedparser
    results = []
    for name, url in RSS_FEEDS.items():
        try:
            r = requests.get(url, headers=HEADERS, timeout=10)
            f = feedparser.parse(r.content)
            for e in f.entries[:max_per_feed]:
                results.append({
                    "source": name,
                    "category": "기술",
                    "title": e.get("title", ""),
                    "url": e.get("link", ""),
                    "date": e.get("published", e.get("updated", "")),
                })
        except Exception:
            pass  # 실패 소스는 조용히 스킵
    return results


def collect_hackernews(max_items=6):
    """HN에서 AI 관련 + 고득점 스토리. 기술/비즈니스 자동 태깅."""
    results = []
    url = ("https://hn.algolia.com/api/v1/search_by_date"
           "?tags=story&numericFilters=points>" + str(HN_MIN_POINTS))
    try:
        r = requests.get(url, headers=HEADERS, timeout=10)
        data = r.json()
        for hit in data.get("hits", []):
            title = hit.get("title") or ""
            if not title:
                continue
            low = title.lower()
            is_tech = any(k.lower() in low for k in TECH_KEYWORDS)
            is_biz = any(k.lower() in low for k in BIZ_KEYWORDS)
            if not (is_tech or is_biz):
                continue
            tags = []
            if is_tech: tags.append("기술")
            if is_biz: tags.append("비즈니스")
            results.append({
                "source": "HackerNews",
                "category": "+".join(tags),
                "title": title,
                "url": hit.get("url") or f"https://news.ycombinator.com/item?id={hit.get('objectID')}",
                "points": hit.get("points", 0),
            })
            if len(results) >= max_items:
                break
    except Exception:
        pass
    return results


def collect_reddit(max_per_sub=2):
    """Reddit 공개 JSON API (인증 불필요)"""
    results = []
    for sub in SUBREDDITS:
        url = f"https://www.reddit.com/r/{sub}/top.json?limit={max_per_sub}&t=day"
        try:
            r = requests.get(url, headers=HEADERS, timeout=10)
            data = r.json()
            for child in data.get("data", {}).get("children", []):
                d = child.get("data", {})
                results.append({
                    "source": f"r/{sub}",
                    "category": "커뮤니티",
                    "title": d.get("title", ""),
                    "url": "https://reddit.com" + d.get("permalink", ""),
                    "points": d.get("ups", 0),
                })
        except Exception:
            pass
    return results


def main():
    payload = {
        "generated_at": datetime.now().isoformat(),
        "ai_items": [],
        "warnings": [],
    }

    rss = collect_rss(max_per_feed=2)
    payload["ai_items"].extend(rss)
    if not rss:
        payload["warnings"].append("AI RSS 수집 0건")

    hn = collect_hackernews(max_items=6)
    payload["ai_items"].extend(hn)
    if not hn:
        payload["warnings"].append("HN AI 수집 0건")

    reddit = collect_reddit(max_per_sub=2)
    payload["ai_items"].extend(reddit)
    if not reddit:
        payload["warnings"].append("Reddit 수집 0건")

    print(json.dumps(payload, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

PEMB_EOF_MARKER

echo "  → scripts/collect_deepdive.py"
cat > "$WS/scripts/collect_deepdive.py" << 'PEMB_EOF_MARKER'
#!/usr/bin/env python3
"""
PE Morning Briefing — 딥다이브 소스 수집 스크립트
Seeking Alpha, Oaktree(하워드 막스 메모), Barron's 등에서 최신 글 감지.
출력: stdout에 JSON
의존성: pip install feedparser requests beautifulsoup4
"""
import json
from datetime import datetime
import requests

HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; PEBriefingBot/1.0)"}

def get_oaktree_memos(max_items=2):
    """하워드 막스 메모 (Oaktree Insights) 최신 글 감지"""
    url = "https://www.oaktreecapital.com/insights"
    try:
        from bs4 import BeautifulSoup
        r = requests.get(url, headers=HEADERS, timeout=12)
        soup = BeautifulSoup(r.text, "html.parser")
        items = []
        # 사이트 구조 변경 가능 — 제목 후보를 폭넓게 탐색
        for tag in soup.find_all(["h2", "h3", "a"], limit=40):
            text = tag.get_text(strip=True)
            if text and len(text) > 15 and "memo" in text.lower():
                items.append(text)
            if len(items) >= max_items:
                break
        return items if items else ["(신규 메모 감지 안됨 — 직접 확인 권장)"]
    except Exception as e:
        return [f"(수집 실패: {e})"]

def get_seeking_alpha_rss(max_items=3):
    """Seeking Alpha 마켓 전반 RSS"""
    import feedparser
    url = "https://seekingalpha.com/market_currents.xml"
    try:
        r = requests.get(url, headers=HEADERS, timeout=12)
        f = feedparser.parse(r.content)
        return [{"title": e.get("title", ""), "link": e.get("link", "")}
                for e in f.entries[:max_items]]
    except Exception as e:
        return [{"error": str(e)}]

def get_barrons_rss(max_items=3):
    """Barron's 최신 RSS"""
    import feedparser
    url = "https://www.barrons.com/feed/rssfeed"
    try:
        r = requests.get(url, headers=HEADERS, timeout=12)
        f = feedparser.parse(r.content)
        return [{"title": e.get("title", ""), "link": e.get("link", "")}
                for e in f.entries[:max_items]]
    except Exception as e:
        return [{"error": str(e)}]

def main():
    payload = {
        "generated_at": datetime.now().isoformat(),
        "oaktree_memos": get_oaktree_memos(2),
        "seeking_alpha": get_seeking_alpha_rss(3),
        "barrons": get_barrons_rss(3),
        "note": "딥다이브 후보 소스. 비서가 이 중 1건을 골라 요약·추천한다.",
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()

PEMB_EOF_MARKER

echo "  → scripts/collect_news.py"
cat > "$WS/scripts/collect_news.py" << 'PEMB_EOF_MARKER'
#!/usr/bin/env python3
"""
PE Morning Briefing — 뉴스 수집 스크립트
출력: stdout에 JSON (지역별 헤드라인)
의존성: pip install fundus feedparser requests
"""
import json
import sys
from datetime import datetime

def collect_fundus(max_per_region=5):
    """fundus로 미국/세계 헤드라인 수집"""
    results = []
    try:
        from fundus import PublisherCollection, Crawler
    except ImportError:
        return results, "fundus 미설치 — pip install fundus 필요"

    regions = {
        "미국": "us",
        "영국": "uk",
        "독일": "de",
        "프랑스": "fr",
        "일본": "jp",
    }
    errors = []
    for region_name, code in regions.items():
        try:
            collection = getattr(PublisherCollection, code)
            crawler = Crawler(collection)
            count = 0
            for article in crawler.crawl(max_articles=max_per_region):
                results.append({
                    "region": region_name,
                    "title": article.title,
                    "date": str(article.publishing_date),
                    "url": str(article.url),
                })
                count += 1
                if count >= max_per_region:
                    break
        except Exception as e:
            errors.append(f"{region_name}: {e}")
    return results, ("; ".join(errors) if errors else None)

def collect_korea_rss(max_items=5):
    """한국 경제뉴스 RSS 수집"""
    import feedparser
    import requests
    results = []
    feeds = {
        "한국(연합)": "https://www.yna.co.kr/rss/economy.xml",
        "한국(한경)": "https://www.hankyung.com/feed/economy",
    }
    headers = {"User-Agent": "Mozilla/5.0 (compatible; PEBriefingBot/1.0)"}
    for name, url in feeds.items():
        try:
            r = requests.get(url, headers=headers, timeout=10)
            f = feedparser.parse(r.content)
            for entry in f.entries[:max_items]:
                results.append({
                    "region": name,
                    "title": entry.get("title", ""),
                    "date": entry.get("published", ""),
                    "url": entry.get("link", ""),
                })
        except Exception:
            pass  # 실패 소스는 조용히 스킵
    return results

def main():
    payload = {
        "generated_at": datetime.now().isoformat(),
        "headlines": [],
        "warnings": [],
    }

    global_news, err = collect_fundus(max_per_region=5)
    payload["headlines"].extend(global_news)
    if err:
        payload["warnings"].append(err)

    kr_news = collect_korea_rss(max_items=5)
    payload["headlines"].extend(kr_news)
    if not kr_news:
        payload["warnings"].append("한국 RSS 수집 실패 또는 0건")

    print(json.dumps(payload, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()

PEMB_EOF_MARKER

echo "  → scripts/collect_signals.py"
cat > "$WS/scripts/collect_signals.py" << 'PEMB_EOF_MARKER'
#!/usr/bin/env python3
"""
PE Morning Briefing — 시장 지표 수집 스크립트
출력: stdout에 JSON (Fear&Greed, 연준 RSS, 가능시 DXY/Brent)
의존성: pip install feedparser requests
"""
import json
import sys
from datetime import datetime
import requests

HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; PEBriefingBot/1.0)"}

def get_fear_greed():
    """CNN Fear & Greed Index"""
    url = "https://production.dataviz.cnn.io/index/fearandgreed/graphdata"
    h = dict(HEADERS)
    h["Referer"] = "https://www.cnn.com/markets/fear-and-greed"
    try:
        r = requests.get(url, headers=h, timeout=10)
        data = r.json()
        fg = data["fear_and_greed"]
        return {"score": round(fg["score"], 1), "rating": fg["rating"]}
    except Exception as e:
        return {"score": None, "rating": None, "error": str(e)}

def get_fed_news(max_items=3):
    """미 연준 최신 보도자료 RSS"""
    import feedparser
    url = "https://www.federalreserve.gov/feeds/press_all.xml"
    try:
        r = requests.get(url, headers=HEADERS, timeout=10)
        f = feedparser.parse(r.content)
        return [
            {"title": e.get("title", ""),
             "date": e.get("published", ""),
             "link": e.get("link", "")}
            for e in f.entries[:max_items]
        ]
    except Exception as e:
        return [{"error": str(e)}]

def main():
    payload = {
        "generated_at": datetime.now().isoformat(),
        "fear_greed": get_fear_greed(),
        "fed_news": get_fed_news(max_items=3),
        # DXY/Brent는 무료 안정 소스가 제한적이라 비워둠.
        # 필요시 investing.com 스크래핑 또는 유료 API 연결.
        "dxy": None,
        "brent": None,
        "note": "DXY/Brent는 별도 소스 연결 필요",
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()

PEMB_EOF_MARKER

echo "  → scripts/test_sources.py"
cat > "$WS/scripts/test_sources.py" << 'PEMB_EOF_MARKER'
#!/usr/bin/env python3
"""
PE Morning Briefing — 환경 진단 스크립트 (맥미니에서 실행)
어떤 뉴스 소스가 접근 가능한지, fundus가 작동하는지 한눈에 확인.

사용법 (맥미니 터미널 또는 비서에게):
    python3 test_sources.py

이 스크립트는 아무것도 바꾸지 않고, 읽기 테스트만 합니다.
"""
import sys
import json
from datetime import datetime

def check_imports():
    print("=" * 50)
    print("1. 필수 패키지 설치 확인")
    print("=" * 50)
    pkgs = {}
    for name in ["fundus", "feedparser", "requests", "bs4"]:
        try:
            __import__(name)
            pkgs[name] = "✅ 설치됨"
        except ImportError:
            pkgs[name] = "❌ 없음 → pip3 install 필요"
    for k, v in pkgs.items():
        print(f"  {k:12} {v}")
    return all("✅" in v for v in pkgs.values())

def check_network():
    print("\n" + "=" * 50)
    print("2. 뉴스 사이트 네트워크 접근 확인")
    print("=" * 50)
    import requests
    headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                             "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"}
    sites = {
        "AP News (미국)": "https://apnews.com",
        "BBC (영국)": "https://www.bbc.com/news",
        "연합뉴스 (한국)": "https://www.yna.co.kr",
        "한국경제": "https://www.hankyung.com",
        "CNN F&G API": "https://production.dataviz.cnn.io/index/fearandgreed/graphdata",
        "연준 RSS": "https://www.federalreserve.gov/feeds/press_all.xml",
        "OpenAI RSS (AI)": "https://openai.com/blog/rss.xml",
        "HackerNews API (AI)": "https://hn.algolia.com/api/v1/search?query=AI&tags=story",
        "Reddit (AI)": "https://www.reddit.com/r/LocalLLaMA/top.json?limit=2&t=day",
    }
    ok = 0
    for name, url in sites.items():
        try:
            r = requests.get(url, headers=headers, timeout=10)
            mark = "✅" if r.status_code == 200 else f"⚠️ {r.status_code}"
            if r.status_code == 200:
                ok += 1
            print(f"  {mark:8} {name}")
        except Exception as e:
            print(f"  ❌      {name}: {str(e)[:40]}")
    print(f"\n  → {ok}/{len(sites)} 접근 성공")
    return ok

def check_fundus():
    print("\n" + "=" * 50)
    print("3. fundus 실제 크롤링 테스트 (미국, 2건)")
    print("=" * 50)
    try:
        from fundus import PublisherCollection, Crawler
        crawler = Crawler(PublisherCollection.us)
        count = 0
        for article in crawler.crawl(max_articles=2):
            print(f"  ✅ {article.title[:55]}")
            count += 1
        if count == 0:
            print("  ⚠️ 0건 — 네트워크 차단 또는 fundus 소스 변경")
        return count
    except Exception as e:
        print(f"  ❌ 에러: {str(e)[:60]}")
        return 0

def check_korea_rss():
    print("\n" + "=" * 50)
    print("4. 한국 뉴스 RSS 테스트")
    print("=" * 50)
    import requests, feedparser
    headers = {"User-Agent": "Mozilla/5.0 (compatible; PEBriefingBot/1.0)"}
    feeds = {
        "연합뉴스 경제": "https://www.yna.co.kr/rss/economy.xml",
        "한국경제": "https://www.hankyung.com/feed/economy",
    }
    total = 0
    for name, url in feeds.items():
        try:
            r = requests.get(url, headers=headers, timeout=10)
            f = feedparser.parse(r.content)
            n = len(f.entries)
            total += n
            if n > 0:
                print(f"  ✅ {name}: {n}건 | 예시: {f.entries[0].title[:35]}")
            else:
                print(f"  ⚠️ {name}: 0건 (status={r.status_code})")
        except Exception as e:
            print(f"  ❌ {name}: {str(e)[:40]}")
    return total

def main():
    print(f"\n진단 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    imports_ok = check_imports()
    if not imports_ok:
        print("\n⚠️ 패키지부터 설치하세요:")
        print("   pip3 install fundus feedparser requests beautifulsoup4")
        print("   설치 후 이 스크립트를 다시 실행하세요.\n")
        return
    net = check_network()
    fundus_n = check_fundus()
    kr_n = check_korea_rss()

    print("\n" + "=" * 50)
    print("📋 종합 결과")
    print("=" * 50)
    print(f"  네트워크 접근: {net}/9 사이트")
    print(f"  fundus 수집: {fundus_n}건")
    print(f"  한국 RSS: {kr_n}건")
    if fundus_n > 0 and kr_n > 0:
        print("\n  🎉 정상! 모닝 브리핑을 바로 돌릴 수 있습니다.")
    elif net == 0:
        print("\n  ⚠️ 네트워크가 전부 막혀있습니다. 방화벽/프록시 확인 필요.")
    else:
        print("\n  🔧 일부만 작동. 위 결과를 Claude에게 보여주고 개선하세요.")

if __name__ == "__main__":
    main()

PEMB_EOF_MARKER

echo "  → skills/pe-morning-briefing/skill.md"
cat > "$WS/skills/pe-morning-briefing/skill.md" << 'PEMB_EOF_MARKER'
# PE Morning Briefing Skill

## 목적
매일 아침, 전 세계 주요 뉴스와 시장 지표를 수집하여 PE 투자자 + 개인 투자자 관점의
인사이트 리포트를 텔레그램으로 전송한다. 보유종목 강조, 딥다이브 추천,
Notion 아카이브까지 한 번에 수행한다.

## 언제 이 스킬을 사용하는가
- HEARTBEAT.md의 "morning briefing" 작업이 트리거될 때 (매일 오전 7시)
- 사용자가 "오늘 브리핑", "morning briefing", "세상 한바퀴" 라고 요청할 때

## 실행 단계

### Step 1 — 뉴스 수집
`scripts/collect_news.py`를 실행한다. 출력은 지역별 헤드라인 JSON.
대상: 미국·영국·독일·프랑스·일본(fundus) + 한국 경제뉴스 RSS.
수집 실패한 소스는 무시하고 진행. 절대 결과를 지어내지 말 것.

### Step 2 — 시장 지표 수집
`scripts/collect_signals.py`를 실행한다.
대상: CNN Fear & Greed, 미 연준 보도자료 RSS, (가능시) DXY·브렌트유.

### Step 3 — 딥다이브 후보 수집
`scripts/collect_deepdive.py`를 실행한다.
대상: Oaktree(하워드 막스 메모), Seeking Alpha, Barron's 최신 글.

### Step 3.5 — AI 뉴스 수집
`scripts/collect_ai_news.py`를 실행한다.
대상: OpenAI·DeepMind·Anthropic·HuggingFace RSS(기술), HackerNews·Reddit(커뮤니티).
각 항목은 [기술] / [비즈니스] 태그가 자동으로 붙어 나온다.
수집 실패 소스는 무시하고 진행. 0건이면 "오늘 AI 특이사항 없음"으로 처리.

### Step 4 — 보유종목 매칭 (★★★ 트리거)
`watchlist.md`를 읽는다. Step 1~3.5에서 수집된 헤드라인 중
보유종목/관심종목/섹터 키워드와 매칭되는 것을 찾는다.
- 보유종목 매칭 → ★★★ + 🔔 강조
- 관심종목 매칭 → ★★ 강조
- 섹터 키워드 → [섹터] 태그 자동 분류

### Step 5 — PE 관점 분석
수집된 raw 데이터를 아래 기준으로 필터링·분석한다.

**중요도 우선순위:**
1. 금리·연준 스탠스 변화 → 딜 파이낸싱·밸류에이션 직결
2. M&A·사모펀드·바이아웃 시장 동향
3. 섹터 밸류에이션 (에너지, 부동산, 테크, 소비재)
4. 지정학 리스크 (미중, 중동, 유럽, 한반도)
5. 달러 강세/약세 방향, 원자재 가격

**태그:** [금리] [M&A] [섹터] [지정학] [FX]
**중요도:** ★★★ (포트폴리오 직접 영향/보유종목) / ★★ (주목) / ★ (참고)

**AI 동향 분석 (Step 3.5 데이터):**
AI 뉴스는 기술과 비즈니스 두 각도를 함께 본다.
- [기술] 항목 → 무엇이 새로운가, 어떤 흐름인가 (모델·도구·연구)
- [비즈니스] 항목 → 펀딩·M&A·밸류에이션·규제. PE/투자 관점에서 누가 수혜/피해인가
- 기술+비즈니스 둘 다인 항목(예: "Anthropic 600억 밸류 펀딩")은 최우선으로 다룬다
- 노정석(AI Frontier) 결의 "이게 사업/투자에 무슨 의미인가"를 한 줄 덧붙인다

### Step 6 — 리포트 작성
아래 형식으로 한국어 리포트를 작성한다.

```
📰 {오늘 날짜} 모닝 브리핑

【오늘의 한 줄】
{시장 전체를 한 문장으로}

【🔔 내 종목 관련】
{보유종목 매칭 항목. 없으면 "오늘 보유종목 직접 언급 뉴스 없음"}

【Top 5 인사이트】
1. ★★★ [금리] {헤드라인}
   → {PE/투자 관점 해석 2줄}
...

【🤖 AI 동향】
1. [기술+비즈니스] {헤드라인}
   → {기술적 의미 + 투자/사업 임팩트 1줄}
2. [기술] {헤드라인}
   → {무엇이 새로운가}
3. [비즈니스] {헤드라인}
   → {펀딩·M&A·규제가 누구에게 의미있나}
(없으면 "오늘 AI 특이사항 없음")

【시장 지표】
- Fear & Greed: {값} ({등급})
- DXY: {값} | Brent: ${값}
- 연준 최신: {제목 또는 "특이사항 없음"}

【오늘의 딥다이브 추천】
{collect_deepdive 결과 중 1건 + 왜 파봐야 하는지}
```

### Step 7 — 전송
완성된 리포트를 텔레그램으로 사용자에게 전송한다.

### Step 8 — Notion 아카이브
완성된 리포트 본문을 `scripts/archive_to_notion.py`에 넘겨 저장한다.
NOTION_TOKEN/NOTION_DB_ID 환경변수가 없으면 이 단계는 건너뛰고
"아카이브 미설정"만 로그에 남긴다 (에러로 처리하지 말 것).

## 하지 말 것
- 단순 뉴스 나열 금지 — 반드시 "내 포트폴리오/딜에 어떤 영향인가" 관점
- 투자 판단을 대신하지 말 것 — 인사이트만 제공
- 수집 실패를 성공으로 보고하지 말 것
- 부동산(LoopNet) 자동 요약 금지 — 링크만. "직접 봐야 감이 생긴다" 원칙

## 참고
- 헤드라인은 지역별 최대 5건으로 제한 (토큰 절약)
- 보유종목 매칭은 watchlist.md 기준, 한글·영문·티커 모두 비교

PEMB_EOF_MARKER

echo "  → skills/pe-weekly-report/skill.md"
cat > "$WS/skills/pe-weekly-report/skill.md" << 'PEMB_EOF_MARKER'
# PE Weekly Report Skill

## 목적
매주 금요일 오후, 한 주간의 흐름을 종합하여 "이번 주 큰 그림" 리포트를
텔레그램으로 전송한다. 매일 브리핑이 점(point)이라면, 주간 리포트는 선(line).

## 언제 사용하는가
- HEARTBEAT.md의 "weekly report" 작업 트리거 (매주 금요일 17:00)
- 사용자가 "주간 리포트", "이번 주 정리" 라고 요청할 때

## 실행 단계

### Step 1 — 이번 주 아카이브 회수
Notion에 저장된 이번 주(월~금) 모닝 브리핑들을 불러온다.
(NOTION_TOKEN 있을 때. 없으면 메모리/로그에서 이번 주 기록 취합)

### Step 2 — 주간 시장 데이터
`scripts/collect_signals.py` 실행 → 이번 주 마지막 지표 스냅샷.
가능하면 주초 대비 변화(Fear&Greed 추이, 연준 주요 발표)를 정리.

### Step 3 — 주간 종합 분석
한 주를 관통한 핵심 테마를 3~4개로 압축한다.
- 이번 주 시장을 움직인 가장 큰 동인은 무엇이었나
- 내 보유종목/관심섹터에 무슨 일이 있었나
- 다음 주 주목해야 할 이벤트 (연준 일정, 실적발표, 지표 발표)

### Step 4 — 리포트 작성
```
📊 {이번 주 날짜범위} 주간 종합

【이번 주 한 문장】
{한 주 전체를 한 문장으로}

【핵심 테마 3선】
1. [태그] {테마} — {무슨 일이 있었고, 왜 중요한가}
2. ...

【내 종목·섹터 동향】
{보유종목/관심섹터의 이번 주 흐름}

【시장 지표 주간 변화】
- Fear & Greed: 주초 {값} → 주말 {값}
- 연준 주요 발표: {요약}

【다음 주 주목 포인트】
- {예정된 이벤트와 그 의미}
```

### Step 5 — 전송 + 아카이브
텔레그램 전송 후 `scripts/archive_to_notion.py`로 저장.

## 하지 말 것
- 매일 브리핑의 단순 반복/합치기 금지 — 반드시 "주간 관점"으로 재해석
- 투자 판단 대행 금지

PEMB_EOF_MARKER

echo "  → watchlist.md"
cat > "$WS/watchlist.md" << 'PEMB_EOF_MARKER'
# watchlist.md — 보유종목 / 관심종목 트리거 설정

> 이 파일에 적힌 종목·키워드가 뉴스에 등장하면 리포트에서 ★★★로 강조됩니다.
> 비서는 매일 브리핑 때 이 파일을 읽어 매칭합니다.

## 보유 종목 (Holdings)
다음 종목/키워드가 헤드라인에 나오면 무조건 ★★★ + 🔔 강조:

```
- 삼성전자 / Samsung Electronics / 005930
- SK하이닉스 / SK Hynix / 000660
- Nvidia / NVDA
- (여기에 실제 보유 종목 추가)
```

## 관심 종목 (Watchlist)
다음은 ★★ 수준으로 표시:

```
- TaylorMade / 테일러메이드
- (관심 종목 추가)
```

## 섹터 키워드
다음 섹터 단어가 나오면 [섹터] 태그에 자동 분류:

```
- 에너지: oil, gas, OPEC, 원유, 브렌트, LNG
- 부동산: real estate, REIT, 부동산, commercial property
- 테크: semiconductor, AI, chip, 반도체, 클라우드
- 소비재: consumer, retail, 소비, 유통
```

---

## 작성 규칙
- 한글명·영문명·티커를 모두 적으면 매칭률이 올라갑니다
- 너무 흔한 단어(예: "AI" 단독)는 오탐이 많으니 구체적으로
- 종목을 늘리면 매일 토큰이 약간 늘어납니다 (20개 이내 권장)

PEMB_EOF_MARKER

echo ""
echo "✅ 파일 생성 완료!"
echo ""
echo "다음 단계:"
echo "  1. pip3 install fundus feedparser requests beautifulsoup4"
echo "  2. watchlist.md 열어서 보유종목 입력"
echo "  3. SOUL_USER_추가항목.md 내용을 SOUL.md / USER.md 에 추가"
echo "  4. HEARTBEAT_추가항목.md 내용을 HEARTBEAT.md 에 추가"
echo "  5. python3 scripts/test_sources.py 로 환경 진단"
echo ""
echo "자세한 내용은 README.md 참고"
