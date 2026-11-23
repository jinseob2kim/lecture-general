# 인허가 임상시험 이야기

발표: 김진섭 · 조선대학교 치과대학 · Quarto revealjs 슬라이드 (44장)

임상시험의 정의와 설계, 신약·의료기기 인허가 과정, 신약과 의료기기 임상의 차이를 설명하고, RACING (Lancet 2022)과 루닛·신라젠 지원 사례, 생성형 AI 의료기기·의료데이터 활용 기준을 소개한다.

## 슬라이드 구성

| 구간 | 내용 |
|---|---|
| 임상시험이란 | 정의, RCT 흐름, 좋은 임상시험의 조건, 연구 윤리, 참여자 관계도, 1–4상, 허가까지 갈 확률 (BIO 2021) |
| 인허가 과정 | 신약 개발 흐름과 급여, 나라별 규제기관, 임상시험 문서와 통계, 의료기기 등급 (치과 품목), 의료기기 허가 흐름 |
| 신약 vs 의료기기 | 설계 비교, 항암 1상 용량 증량 (3+3), Simon 2단계 설계, 치과 인허가 임상, 치과 임상의 분석 단위, 진단 성능 2×2, AI 의료기기 임상, MRMC 판독자 연구 |
| RACING | 연구 설계, 비열등성, 대상자 수 계산, 결과, 통계 지원 내용 |
| 사례 1: 루닛 | 제품, 허가용 판독자 연구, 허가 이후 근거 (RWE, 메타분석) |
| 사례 2: 신라젠 | 파이프라인, BAL0891 1상, 항암 1상 결과 그림, 허가 문서와 안전성 보고 |
| 생성형 AI | 생성형 AI 의료기기 허가 흐름, 보건의료 분야 LLM 활용 기준 |

## 폴더 구조

```
chosun2026/
├── index.qmd              슬라이드 원본
├── index.html             렌더링 결과
├── Chosun_2026_Slides.pdf PDF (decktape)
├── script.md              발표 대본 (슬라이드별, 약 53분)
├── make_figs.R            img/ 의 R 그림 생성 (가상 데이터 그림 포함)
├── fit.js                 슬라이드별 zoom 측정 → slides_assets/chosun-fit.css
├── img/                   그림: R 생성 그림, RACING 논문 그림, LLM 활용 기준 원문 표
└── slides_assets/         테마·CSS (chosun.css: 덱 전용, chosun-fit.css: 슬라이드별 zoom)
```

## 렌더링

```bash
cd docs/chosun2026
Rscript make_figs.R          # 그림을 바꿨을 때만
quarto render index.qmd
```

- `chosun-fit.css` 는 슬라이드마다 내용이 화면 아래 800px 선까지 차도록 zoom 값을 측정해 넣은 파일이다. 슬라이드 내용을 바꾸면 다시 측정한다.

```bash
cd docs && python3 -m http.server 8765 --bind 127.0.0.1 &   # file:// 로는 reveal.js 가 안 뜸
cd chosun2026
printf '/* fit.js */\n' > slides_assets/chosun-fit.css     # 기존 zoom 지우고 측정
node fit.js http://127.0.0.1:8765/chosun2026/index.html slides_assets/chosun-fit.css 800 1592 1.7 0.75
decktape reveal --size 1600x900 --pause 800 \
  --chrome-path ~/.cache/ms-playwright/chromium-1140/chrome-linux/chrome --chrome-arg=--no-sandbox \
  http://127.0.0.1:8765/chosun2026/index.html Chosun_2026_Slides.pdf
```

## 참고

- 3+3 용량 증량, Simon 2단계 특성 곡선, MRMC ROC·판독 설계, 진단 성능 2×2·PPV 곡선, waterfall, swimmer, 메타분석 forest, 모니터링 웹 화면, AI 판독 화면, 임플란트 군집·split-mouth 그림은 가상 데이터·예시 그림이다.
- 비열등성 그림의 B행, 대상자 수, 결과 수치는 RACING 논문 (Lancet 2022; 400: 380–90) 값이다.
- 의료기기 등급은 식약처 고시 「의료기기 품목 및 품목별 등급에 관한 규정」 제2023-41호 (2023.6.12) 기준이다.
- 허가 확률은 BIO, Informa, QLS. Clinical Development Success Rates 2011–2020 (2021) 값이다.
- 루닛·신라젠 사례는 공개된 정보 (제품, 학회 발표, ClinicalTrials.gov) 와 일반적인 설계·통계 내용만 담았다.
