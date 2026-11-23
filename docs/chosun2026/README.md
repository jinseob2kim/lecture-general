# 인허가 임상시험 이야기

발표: 김진섭 · 조선대학교 치과대학 · Quarto revealjs 슬라이드 (본편 47장 + 부록 6장)

피지컬 AI·AI 의료기기를 만들려는 치대생에게 인허가 개념을 소개한다. 의료기기 등급·제출 자료·허가 경로, 임상시험 기본, 의료기기·AI 임상 설계를 설명하고, 루닛·RACING (Lancet 2022)·에버엑스·신라젠 지원 사례, 허가 이후 AI 변경 관리와 생성형 AI 기준을 다룬다.

## 슬라이드 구성

| 구간 | 내용 |
|---|---|
| 도입 | 내 AI 기기가 환자에게 가기까지 (로드맵), 강의 순서 |
| 의료기기 인허가 | 의료기기 여부와 등급 (치과 품목), 허가에 내는 자료 (기술문서·규격), 허가에서 진료까지, 디지털의료기기·혁신의료기기, 나라별 규제기관 |
| 임상시험 기본 | 정의, RCT 흐름, 비교 임상시험의 조건, 연구 윤리, 참여자 관계도, 문서와 통계, 신약 개발 흐름, 신약 단계와 허가 확률 |
| 의료기기·AI 임상 설계 | 설계 비교, 치과 인허가 임상, 피지컬 AI 임상 평가 (임플란트 로봇 예), 치과 분석 단위, 진단 성능 2×2, AI 의료기기 임상, MRMC |
| 사례 1: 루닛 | 제품, AI 판독자 연구의 통계 질문, 허가 이후 근거 (RWE, 메타분석) |
| 사례 2: RACING | 연구 설계, 비열등성 (기기 예 포함), 대상자 수 계산, 결과, 통계 지원 내용 |
| 사례 3: 에버엑스 | 디지털치료기기 허가까지 (탐색 → 확증 → 허가), 탐색에서 확증으로 대상자 수 정하기 |
| 사례 4: 신라젠 | 파이프라인, BAL0891 1상 |
| 허가 이후와 생성형 AI | AI 변경 관리 (PCCP, 변경관리계획), 생성형 AI 의료기기, 보건의료 분야 LLM 활용 기준, 정리 체크리스트 |
| 부록 | 허가까지 갈 확률, 항암 1상 용량 증량, Simon 2단계, 항암 1상 결과 그림, 허가 문서와 안전성 보고 |

## 폴더 구조

```
chosun2026/
├── index.qmd              슬라이드 원본
├── index.html             렌더링 결과
├── Chosun_2026_Slides.pdf PDF (decktape)
├── script.md              발표 대본 (슬라이드별, 약 58분, 부록 메모 포함)
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

- 3+3 용량 증량, Simon 2단계 특성 곡선, MRMC ROC·판독 설계, 진단 성능 2×2·PPV 곡선, 대상자 수 곡선, waterfall, swimmer, 메타분석 forest, 모니터링 웹 화면, AI 판독 화면, 임플란트 군집·split-mouth·식립 정확도 그림은 가상 데이터·예시 그림이다.
- 비열등성 그림의 B행, 대상자 수, 결과 수치는 RACING 논문 (Lancet 2022; 400: 380–90) 값이다.
- 의료기기 등급은 식약처 고시 「의료기기 품목 및 품목별 등급에 관한 규정」 제2023-41호 (2023.6.12) 기준이다.
- 허가 확률은 BIO, Informa, QLS. Clinical Development Success Rates 2011–2020 (2021) 값이다.
- 루닛·에버엑스·신라젠 사례는 공개된 정보 (제품, 허가·학회 발표 보도, ClinicalTrials.gov) 와 일반적인 설계·통계 내용만 담았다. 고객사 내부 수치는 넣지 않았다.
