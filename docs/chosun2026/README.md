# 인허가 임상시험 이야기

발표: 김진섭 · 조선대학교 치과대학 · Quarto revealjs 슬라이드 (본편 35장 + 부록 6장)

피지컬 AI·AI 의료기기를 만들려는 치대생에게 인허가 개념을 소개한다. 인허가 틀 (의료기기 여부·등급·제출 자료·허가 경로) 과 임상시험 기본은 짧게 두고, 직접 참여한 DSMB 와 흉부 CT AI (자문 중)·루닛·RACING (Lancet 2022)·에버엑스·신라젠 지원 사례로 AI 단독 성능 시험·판독자 연구·비열등성·대상자 수·중간분석·항암 1상을 설명한다. 끝으로 허가 이후 AI 변경 관리와 생성형 AI 기준을 다룬다.

## 슬라이드 구성

| 구간 | 내용 |
|---|---|
| 도입 | 내 AI 기기가 환자에게 가기까지 (로드맵, 오늘 순서) |
| 의료기기 인허가 | 의료기기 여부와 등급 (치과 품목), 허가에 내는 자료 (기술문서·규격), 허가에서 진료까지, 디지털의료기기·혁신의료기기·해외 |
| 임상시험 기본 | 정의와 공정한 비교의 조건 (RCT), 참여자 관계도, DSMB 구조와 참여 연구, DSMB 통계 위원이 보는 것 (무작위배정, 중간분석) |
| 의료기기 임상 설계 | 신약 vs 의료기기, 피지컬 AI 임상 평가 (임플란트 로봇 예), 치과 분석 단위 |
| 지원 사례 | 흉부 CT AI (단독 성능 시험 구조와 식약처 사전검토에서 받는 질문, 통계 검토에서 고치는 것, 정확 이항검정 대상자 수 가상 예시), 루닛 (제품, 판독자 연구 설계와 심사 질문, 허가 이후 근거), RACING (연구 설계, 비열등성, 대상자 수, 통계 지원), 에버엑스 (탐색 → 확증 → 허가, 대상자 수), 신라젠 (파이프라인, BAL0891 1상) |
| 허가 이후와 생성형 AI | AI 변경 관리 (PCCP, 변경관리계획), 생성형 AI 의료기기와 보건의료 분야 LLM 활용 기준, 정리 체크리스트 |
| 부록 | 나라별 규제기관, 연구 윤리, 신약 단계와 허가 확률, 진단 성능 2×2, 항암 1상 용량 증량, 허가 문서와 안전성 보고 |

## 폴더 구조

```
chosun2026/
├── index.qmd              슬라이드 원본
├── index.html             렌더링 결과
├── Chosun_2026_Slides.pdf PDF (decktape)
├── script.md              발표 대본 (슬라이드별, 약 49분, 부록 메모 포함)
├── make_figs.R            img/ 의 R 그림 생성 (가상 데이터 그림 포함)
├── fit.js                 슬라이드별 zoom 측정 → slides_assets/chosun-fit.css
├── img/                   그림: R 생성 그림, RACING 대상자 수 계산기 화면, LLM 활용 기준 원문 표
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

- 3+3 용량 증량, MRMC 판독 설계, 진단 성능 2×2·PPV 곡선, 대상자 수 곡선, 메타분석 forest, 모니터링 웹 화면, AI 판독 화면, DSMB 흐름도, 임플란트 군집·split-mouth·식립 정확도 그림은 가상 데이터·예시 그림이다.
- 중간분석 그림의 유의 기준은 gsDesign 으로 계산한 O'Brien–Fleming·Pocock 경계 (중간분석 1회, 자료 50%, 양측 α 0.05) 이다.
- 비열등성 그림의 B행, 대상자 수, 결과 수치는 RACING 논문 (Lancet 2022; 400: 380–90) 값이다.
- DSMB 참여 연구는 공개 등록 정보 (ClinicalTrials.gov NCT05995600, NCT06649240) 만 담았다. 준비 중인 연구는 이름을 넣지 않았다.
- 의료기기 등급은 식약처 고시 「의료기기 품목 및 품목별 등급에 관한 규정」 제2023-41호 (2023.6.12) 기준이다.
- 허가 확률은 BIO, Informa, QLS. Clinical Development Success Rates 2011–2020 (2021) 값이다.
- 루닛·에버엑스·신라젠 사례는 공개된 정보 (제품, 허가·학회 발표 보도, ClinicalTrials.gov) 와 일반적인 설계·통계 내용만 담았다. 고객사 내부 수치는 넣지 않았다.
- 흉부 CT AI 사례는 진행 중인 자문이라 회사·제품 이름, 일정, 계획서 수치를 넣지 않고 일반적인 설계와 검토 항목만 담았다. 이항검정 그림은 가상 수치다 (병변 CT 70건, 기준값 0.75, 기대 성능 0.90, 95% Clopper–Pearson 하한 기준).
