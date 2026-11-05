# AI agent를 이용한 의학통계

발표: 김진섭 · 30분 · Quarto revealjs 슬라이드

참석자가 본인 연구에 AI agent(Claude Code)를 직접 쓸 수 있도록 설치, 기본 세팅(CLAUDE.md), 사용법, 표·그림 저장 방법을 소개하고, 가상자료로 RACING trial(Lancet 2022) 분석을 재현하는 과정을 영상으로 보여준다.

## 슬라이드 구성

| 구간 | 내용 |
|---|---|
| 도입 | 강의 순서, AI agent가 하는 일, ChatGPT와 Claude |
| 의료데이터와 AI | 플랜별 데이터 전송·보관, 보건의료데이터 활용 가이드라인 |
| 설치와 세팅 | Claude 데스크톱 설치, 작업 폴더, CLAUDE.md 작성법(예시 3종), 승인 방식 |
| Claude 사용법 | 자주 쓰는 기능, 지시 방법, 주요 패키지, Excel·PPT 저장 코드 |
| RACING 재현 | 연구 소개, 준비물, 데모 지시, 데모 영상, 생성된 파일, 결과 확인 |
| 마무리 | 내 연구 적용 순서, 주의사항 |

## 폴더 구조

```
ysfn2026/
├── index.qmd            슬라이드 원본
├── index.html           렌더링 결과
├── slides_assets/       테마·CSS (ysfn.css: 이 덱 전용 크기 조정)
├── img/                 Claude 데스크톱·결과물 스크린샷 (01–06)
├── video/
│   └── racing_demo.mp4  RACING 재현 화면 녹화 (1분 34초, 배속 편집)
└── racing-demo/         데모용 작업 폴더
    ├── CLAUDE.md        RACING 분석 지침 (변수, 표·그림별 방법, 확인 항목)
    ├── data/            RACING_synthetic_data.csv (가상자료 3,780명 × 57변수)
    ├── paper/           RACING 원 논문 PDF
    ├── global.R         전처리, varlist, out, out.label, out.long
    ├── analysis.R       Table 1–4, Figure 1–3
    ├── results/         RACING_Tables.xlsx, RACING_primary_PH_assumption.xlsx
    └── figures/         RACING_Figures.pptx
```

## 렌더링

```bash
cd docs/ysfn2026
quarto render index.qmd
```

## RACING 데모 다시 돌리기

Claude 데스크톱 Code 탭에서 `racing-demo` 폴더를 열고 아래 두 지시를 차례로 입력한다.

1. `data 폴더 자료 읽어서 CLAUDE.md 지침대로 global.R 만들어줘.`
2. `analysis.R 만들어서 Table 1–4, Figure 1–3 만들어줘. 표는 Excel, 그림은 PPT로 저장해줘.`

- analysis.R 단계는 약 8분 걸린다. 발표에서는 녹화 영상을 쓰고, 결과 파일은 `results/`, `figures/`에 미리 넣어 두었다.
- R에서 직접 돌리려면 `racing-demo`를 작업 디렉토리로 두고 `source("analysis.R")`를 실행한다. 필요한 패키지: data.table, magrittr, jstable, jskm, survival, ggplot2, flextable, flexlsx, openxlsx2, officer, rvg, forestploter

## 참고

- `RACING_synthetic_data.csv`는 RACING trial 구조를 따라 만든 가상자료다. 결과는 원 논문 수치와 같지 않다.
- Figure 1의 약제 불내성 중단 수치(88/1,846, 150/1,832)는 원 논문 요약값을 가져온 것이다 (그림 주석에 출처 표기).
