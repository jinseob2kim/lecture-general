Quarto Revealjs 프레젠테이션 작업 가이드. 이 프로젝트는 HWP 원천 문서를 기반으로 Quarto revealjs 슬라이드를 제작하고, PDF export와 발표 대본을 함께 관리하는 구조이다.

## 작업 파이프라인 (전체 흐름)

1. **원천 문서(HWP) → hwp\_html 변환**: HWP 파일을 HTML로 변환하면 hwp\_html/ 폴더에 HTML과 이미지가 생성됨
2. **이미지 추출 및 네이밍**: hwp\_html에서 필요한 이미지를 `img/` 폴더로 복사. 네이밍 규칙: `p0XX\_imgN.jpeg` (XX = HWP 원본 페이지번호, N = 해당 페이지 내 이미지 순서). 로고는 `kangdong\_logo.svg`처럼 별도 네이밍
3. **QMD 작성**: 원천 문서의 내용과 구조를 기준으로 `index.qmd` 작성. 참고(ref) 슬라이드가 있으면 **시각 스타일만 참고**, 목차·흐름·내용은 원천 문서 기준
4. **렌더링**: `quarto render index.qmd` → `index.html` + `index\_files/` 생성 (Quarto 1.6.39)
5. **HTML 확인**: 브라우저에서 일반 모드 동작 확인
6. **PDF export 확인**: `?print-pdf` 파라미터로 print-pdf 모드 확인 → **실제 PDF 인쇄까지 반드시 검증** (화면과 인쇄 결과가 다를 수 있음)
7. **대본 동기화**: 슬라이드 내용 변경 시 `발표대본\_\*.docx`도 함께 수정 (변경된 부분만, 원본 텍스트는 절대 건드리지 않기)

## 프로젝트 구조

```
result/
├── index.qmd                  # 메인 슬라이드 소스
├── index.html                 # 렌더링 결과물
├── index\_files/               # 렌더링 시 자동 생성되는 Reveal.js 라이브러리 (수정 금지)
├── zarathu\_theme.scss         # SCSS 테마 (색상·폰트·heading 등 기본값 정의)
├── custom-style.css           # CSS 커스텀 스타일 (컴포넌트·레이아웃·테이블)
├── header-inject.html         # include-after-body로 주입 (로고·페이지번호·print-pdf 보정)
├── bg.png                     # 타이틀 슬라이드 배경 (1600x900 권장)
├── img/                       # 슬라이드용 이미지
└── CLAUDE.md                  # 이 파일
```

## 테마 아키텍처: zarathu\_theme.scss vs custom-style.css

**역할 분리를 명확히 지킬 것.**

* `zarathu\_theme.scss` — Reveal.js SCSS 변수 오버라이드만. 폰트 패밀리(`Noto Serif`, `Noto Serif KR`), heading 색상(`$zarathu\_main\_color: #2A3D21`), heading 크기(`$presentation-h2-font-size: 2.0em`), 링크 색상. **컴포넌트 스타일은 여기에 넣지 않음**
* `custom-style.css` — 슬라이드에서 사용하는 모든 **컴포넌트 클래스** 정의. highlight-box, card, summary-grid, 테이블 스타일, 리스트 커스텀 불릿, spacer 등. 새 컴포넌트가 필요하면 여기에 추가
* `header-inject.html` — print-pdf 모드 보정과 로고/페이지번호 관련 CSS·JS만. `include-after-body`로 본문 뒤에 주입됨

**폰트 우선순위 주의**: SCSS에서 `Noto Serif` 계열을 지정하지만, custom-style.css에서 `"Malgun Gothic", "맑은 고딕", "Noto Sans KR"` 을 `!important`로 덮어쓴다. 실제 렌더링되는 폰트는 맑은 고딕 계열.

## 색상 체계

메인 색상은 짙은 초록 `#2A3D21`. 5색 단계별 컬러를 highlight-box, summary-grid, process-flow, milestone 등에서 일관되게 사용:

|이름|메인 (보더/강조)|텍스트|배경|용도|
|-|-|-|-|-|
|**green**|`#2E7D32`|`#1B5E20`|`#E8F5E9`|기본·1단계·경제|
|**blue**|`#1565C0`|`#0D47A1`|`#E3F2FD`|2단계·기술|
|**teal**|`#00838F`|`#004D40`|`#E0F2F1`|3단계·혁신|
|**purple**|`#7B1FA2`|`#4A148C`|`#F3E5F5`|4단계·외부참여기관|
|**gray**|`#37474F`|`#263238`|`#ECEFF1`|5단계·기타|

기타 색상 용도:

* h2 제목, strong 텍스트, section-title: `#2A3D21`
* h2 하단 그라데이션: `#2A3D21 → #2E7D32 → #43A047 → #81C784`
* 리스트 불릿(다이아몬드 모양): 1단계 `#43A047`, 2단계(중첩) `#A5D6A7`
* 슬라이드 번호: `#333333`, 푸터: `#999`
* accent-box 배경: `linear-gradient(135deg, #1B5E20 0%, #2E7D32 100%)`, 내부 strong: `#C8E6C9` (연초록)
* card-navy 보더: `#263238` (진한 남색)
* 마지막 "감사합니다" 슬라이드 배경: `#2A3D21`

## 폰트 크기 계층

위에서 아래로 크기 순. **새 클래스를 만들 때 이 계층을 벗어나지 않도록 주의**:

|요소|크기|weight|용도|
|-|-|-|-|
|`h2`|`1.45em`|700|슬라이드 제목 (자동 하단 그라데이션)|
|`.section-title`|`0.9em`|700|소제목 (하단 `#81C784` 줄)|
|`.tl-header`|`0.85em`|600|타임라인 헤더|
|일반 `li`, `.body-text`, `.card`|`0.78em`|—|본문 글머리·텍스트·카드 내부|
|`.highlight-box` 계열|`0.75em`|—|강조 박스 내부|
|`.card-navy`|`0.72em`|—|남색 카드 (보조 정보)|
|`.summary-item`, `.micro-text`|`0.72em`|—|요약 그리드·축소 본문|
|`.team-grid`|`0.66em`|—|연구팀 그리드|
|`.schedule-table`|`0.64em`|—|일정 테이블|
|기본 `table`|`0.6em`|—|테이블 본문|
|`.footnote`|`0.6em`|—|각주 (회색 `#666`)|
|`.pstep` (프로세스)|`0.58em`|—|5단계 프로세스 카드|
|`.role-table`|`0.58em`|—|역할분담 테이블|
|`.footer`|`0.45em`|—|하단 푸터|

## QMD YAML 헤더

```yaml
---
title: "제목"
subtitle: "부제"
author: "발표자"
date: today
date-format: "YYYY년 M월 D일"
format:
  revealjs:
    theme: zarathu\_theme.scss
    css: custom-style.css
    title-slide-attributes:
      data-background-image: bg.png
      data-background-size: cover
      data-background-opacity: "0.3"
    footer: ""
    self-contained: false
    include-after-body: header-inject.html
    chalkboard:
      buttons: false
    preview-links: true
    show-notes: false
    slide-number: c/t
    width: 1600
    height: 900
---
```

* `self-contained: false` — 외부 리소스를 별도 폴더(`index\_files/`)로 분리. true로 바꾸면 단일 HTML이지만 용량 큼
* `slide-number: c/t` — "현재/전체" 형식 (예: "3/26")
* `width: 1600`, `height: 900` — 16:9 비율, 고정 해상도. 반응형 고려 불필요
* `data-background-opacity: "0.3"` — 타이틀 슬라이드 배경 투명도. 문자열로 감싸야 함
* `include-after-body` — header-inject.html이 `</body>` 직전에 삽입됨. Reveal.js 초기화 이후 시점

## QMD 슬라이드 작성 문법

### 기본 규칙

**새 슬라이드**: `## 제목` (H2)로 시작. H2에 하단 그라데이션 줄 자동 적용. H1(`#`)은 사용하지 않음 (마지막 슬라이드 제외)

**Quarto div 문법**: `:::` 3개로 열고 닫기. 중첩할 때는 바깥을 `::::` 4개로:

```markdown
:::: {.columns}          ← 4개 (바깥)
::: {.column width="50%"} ← 3개 (안쪽)
내용
:::                       ← 3개 닫기
::: {.column width="50%"}
내용
:::
::::                      ← 4개 닫기
```

* **중첩 규칙**: 바깥 div는 안쪽보다 콜론 수가 같거나 많아야 함. 3단 중첩이면 바깥 `:::::`(5개), 중간 `::::`(4개), 안쪽 `:::`(3개)
* **클래스 지정**: `{.클래스명}` 또는 `{.클래스1 .클래스2}` (복수)
* **인라인 스타일**: `{style="margin-top: -38px;"}` — 예외적으로 필요할 때만

### 이미지 삽입

```markdown
!\[](img/파일명.jpeg){width="100%" fig-align="center"}
!\[](img/파일명.jpeg){width="100%" height="200px" fig-align="center"}
```

**이미지 크기 가이드라인**:

|배치|width|height|예시|
|-|-|-|-|
|풀페이지 (이미지만)|`100%`|지정 안 함|시스템 아키텍처 다이어그램|
|2단 중 한쪽|`100%`|지정 안 함 또는 `height="768px"`|비즈니스 모델 이미지|
|2단 중 작은 이미지|`100%`|`height="200px"` \~ `height="400px"`|Propensity Score 그래프|
|이미지 잘림 방지|—|`max-height: 660px` (인라인 스타일)|긴 스크린샷|

**이미지 형식별 용도**:

* **SVG** — 로고 (`kangdong\_logo.svg`). 벡터라 어떤 크기에서도 선명. print-pdf에서 CSS `background: url()` 로 참조 가능
* **JPEG** — 사진, 스크린샷, HWP에서 추출한 대부분의 이미지. 용량 효율적
* **PNG** — 투명 배경이 필요한 경우 (`Zarathu Circle Clipping Mask2.png` 등)

**PDF export에서 2페이지 문제가 생기면 반드시 `height="Xpx"`를 QMD에서 지정할 것** — 뒤의 PDF Export 섹션 참고

### 이미지 overflow 처리

큰 스크린샷이 슬라이드를 넘칠 때:

```markdown
::: {style="overflow: hidden; max-height: 660px;"}
!\[](img/긴스크린샷.jpeg){width="100%"}
:::
```

* `overflow: hidden`으로 넘치는 부분 자르기
* `max-height`로 최대 높이 제한

### 발표자 노트

```markdown
::: {.notes}
여기에 발표 대본 내용. 일반 모드에서 S키를 누르면 speaker view에서 보임.
print-pdf 모드에서는 show-notes: false이므로 숨겨짐.
:::
```

### 테이블

일반 markdown 테이블 사용. 정렬: `|:---|` 좌측, `|:---:|` 가운데, `|---:|` 우측:

```markdown
| 구분 | 내용 | 비율 |
|:---|:---|---:|
| 항목1 | 설명 | 60% |
```

* 테이블 전용 CSS 클래스를 감싸는 div에 적용 (아래 컴포넌트 섹션 참고)

### 각주

```markdown
::: {.footnote}
※ 용어1: 설명\\
※ 용어2: 설명 (줄바꿈은 백슬래시 `\\`로)
:::
```

* **`\\` 줄바꿈 주의**: 백슬래시 뒤에 공백 없이 바로 줄바꿈해야 함. 공백이 들어가면 줄바꿈 안 됨

### bold 텍스트

`\*\*텍스트\*\*` → `<strong>` 태그 → 색상이 자동으로 `#2A3D21` (짙은 초록)으로 적용됨. accent-box 안에서는 `#C8E6C9` (연초록)

## 컴포넌트 카탈로그

### 강조 박스 계열 — 정보 전달·요약·핵심 메시지

```markdown
::: {.highlight-box}
\*\*핵심 내용\*\*: 설명
:::
```

* `.highlight-box` (초록 `#2E7D32`), `.highlight-box-blue` (`#1565C0`), `.highlight-box-teal` (`#00838F`), `.highlight-box-purple` (`#7B1FA2`), `.highlight-box-gray` (`#37474F`)
* 좌측 4px 보더 + 연한 배경 + border-radius 오른쪽만
* **선택 기준**: 단일 메시지 → green, 순서가 있는 나열 → 5색 순환, 특정 카테고리 매칭 → 해당 색상

**accent-box** — 특별히 강조할 핵심 한두 줄. 짙은 초록 그라데이션 배경 + 흰색 텍스트:

```markdown
::: {.accent-box}
\*\*bold는 연초록\*\*, 일반 텍스트는 흰색
:::
```

* `.accent-box-emerald` — 연초록 배경(`#E8F5E9`) + 짙은 초록 텍스트. accent-box보다 부드러운 톤

**선택 기준**: highlight-box는 보조 설명, accent-box는 슬라이드의 가장 핵심 메시지 1개에만 사용

### 카드 계열 — 기관/조직 설명, 역할 기술

```markdown
::: {.card}
\*\*기관명 또는 역할\*\*

- 내용1
- 내용2
:::
```

* `.card` — 좌측 초록(`#2E7D32`) 보더. 주관기관·주요 역할에 사용
* `.card-navy` — 좌측 남색(`#263238`) 보더. 보조 정보·참여기관에 사용

**card-grid** — 2열 카드 배치 (카드 크기가 작아짐, 0.62em):

```markdown
::: {.card-grid}
::: {.card}
카드1
:::
::: {.card}
카드2
:::
:::
```

### 소제목·본문·간격

```markdown
::: {.section-title}
소제목 텍스트
:::

::: {.body-text}
본문 텍스트 블록 (리스트 아이템과 동일한 0.78em 크기)
:::

::: {.spacer-sm}
:::
```

* `.spacer-xs` (6px) — 미세 간격
* `.spacer-sm` (12px) — 일반 간격 (가장 자주 사용)
* `.spacer-md` (24px) — 큰 간격

### 3열 요약 그리드 — KPI, 성과목표

```markdown
::: {.summary-grid}

::: {.summary-item .si-green}
\*\*제목\*\*

수치·설명
:::

::: {.summary-item .si-blue}
\*\*제목\*\*

수치·설명
:::

::: {.summary-item .si-teal}
\*\*제목\*\*

수치·설명
:::

:::
```

* `.si-green`, `.si-blue`, `.si-teal`, `.si-purple`, `.si-gray`
* 하단 4px 컬러 보더 + 연한 배경 + 그림자
* `summary-grid-compact` — 축소 버전 (0.62em, padding 축소)

### 5단계 프로세스 플로우

HTML로 직접 작성 (Quarto markdown div로는 flex 레이아웃이 어려움):

```html
<div class="process-flow">
<div class="pstep pstep-1">
<span class="step-label">STEP 1</span>
<span class="step-title">제목</span>
<span class="step-desc">설명</span>
</div>
<div class="process-arrow">▶</div>
<div class="pstep pstep-2">
<!-- 반복 -->
</div>
<!-- pstep-3, pstep-4, pstep-5 -->
</div>
```

### 마일스톤 타임라인

```markdown
::: {.milestone-box}

::: {.milestone .ms-1}
::: {.ms-month}
기간 (예: 종료 후 1\~3개월)
:::
::: {.ms-content}
내용
:::
:::

::: {.milestone .ms-2}
::: {.ms-month}
기간
:::
::: {.ms-content}
내용
:::
:::

:::
```

* `.ms-1`(초록) \~ `.ms-4`(보라). ms-month는 상단 색상 헤더, ms-content는 하단 본문
* `.milestone-box-compact` — 축소 버전 (ms-month 0.72em, ms-content 0.62em)

### 연구역량 박스

```markdown
::: {.capability-box}
::: {.cap-title}
역량 제목
:::
내용
:::
```

### 연구팀 그리드

```markdown
::: {.team-grid}
::: {.team-member}
\*\*이름\*\* (직책)\\
역할 설명
:::
::: {.team-member-ext}
\*\*이름\*\* (외부 참여)\\
역할 설명
:::
:::
```

* `.team-member` — 초록 좌측 보더 (내부 인력)
* `.team-member-ext` — 보라 좌측 보더 (외부 참여 인력)

### 테이블 전용 클래스

테이블을 감싸는 div에 적용. 각각 컬럼 너비, 헤더 색상, 본문 스타일이 다름:

|클래스|용도|특징|
|-|-|-|
|`.team-table`|인력/컨소시엄|컬럼 너비 고정, 구분선|
|`.role-table`|역할분담 (3열)|0.58em, 좁은 1열+넓은 3열|
|`.schedule-table`|일정 총괄|월별 좁은 컬럼, 색상별 1열, 흰색 본문|
|`.budget-table`|예산|흰색 본문, 마지막 행 합계 강조|
|`.hitl-table`|연번+내용 2열|연번 2%+내용 98%|
|`.detail-1`\~`.detail-5`|상세일정|색상별 헤더, 4열 고정 너비|

## 전형적 슬라이드 레이아웃 패턴

### 패턴 1: 소제목 + 리스트 + 강조박스 (가장 기본)

```markdown
## 슬라이드 제목

::: {.section-title}
소제목
:::

- 내용1
- 내용2
- 내용3

::: {.spacer-sm}
:::

::: {.highlight-box}
\*\*핵심 메시지\*\*
:::

::: {.notes}
발표 대본
:::
```

### 패턴 2: 좌 텍스트 + 우 이미지

```markdown
## 슬라이드 제목

:::: {.columns}

::: {.column width="55%"}

::: {.section-title}
소제목
:::

- 내용

::: {.highlight-box}
강조
:::

:::

::: {.column width="45%"}
!\[](img/이미지.jpeg){width="100%" fig-align="center"}
:::

::::
```

**컬럼 너비 권장 조합**:

* 텍스트 + 큰 이미지: `55% : 45%` 또는 `58% : 42%`
* 텍스트 + 텍스트: `50% : 50%`
* 예시 화면 2개 비교: `48% : 52%`
* 텍스트 많은 쪽이 넓게: `60% : 40%`

### 패턴 3: 요약 그리드 + 테이블

```markdown
## 슬라이드 제목

::: {.summary-grid}
::: {.summary-item .si-green}
내용
:::
::: {.summary-item .si-blue}
내용
:::
::: {.summary-item .si-teal}
내용
:::
:::

::: {.spacer-sm}
:::

| 표 |
```

### 패턴 4: 복수 강조박스 나열 (추진전략, 서비스 형태 등)

```markdown
## 슬라이드 제목

::: {.section-title}
소제목
:::

::: {.highlight-box}
\*\*항목 1\*\* — 설명
:::

::: {.highlight-box-blue}
\*\*항목 2\*\* — 설명
:::

::: {.highlight-box-teal}
\*\*항목 3\*\* — 설명
:::
```

* 5색 순서: green → blue → teal → purple → gray. 6개 이상이면 green부터 다시 순환

## 특수 슬라이드 패턴

### 목차 슬라이드

```markdown
## 목차

::: {style="padding: 10px 40px;"}

::: {.highlight-box}
\*\*I. 제목\*\* — 부제
:::

::: {.highlight-box-blue}
\*\*II. 제목\*\* — 부제
:::

::: {.highlight-box-teal}
\*\*III. 제목\*\*
:::

::: {.highlight-box-purple}
\*\*IV. 제목\*\* — 부제
:::

::: {.highlight-box-gray}
\*\*V. 제목\*\*
:::

:::
```

* 바깥 div에 `padding: 10px 40px` 으로 좌우 여백
* 5색 순서대로 사용

### 마지막 슬라이드 ("감사합니다")

```markdown
## {background-color="#2A3D21"}

<div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 70vh;">
<p style="color: #ffffff; font-size: 2.5em; font-weight: 700; margin: 0;">감사합니다</p>
<p style="color: #ffffff; font-size: 1.15em; font-weight: 600; margin-top: 30px;">사업명</p>
<p style="color: #C8E6C9; font-size: 0.85em; margin-top: 10px;">기관명</p>
</div>
```

* `##` 뒤에 제목 없이 `{background-color}` 속성만 → 빈 제목 슬라이드
* 로고·페이지번호는 header-inject.html에서 `:last-child`로 자동 숨김
* custom-style.css에서 `section\[data-background-color="#2A3D21"] h1` 의 border를 제거

### 타이틀 슬라이드

YAML 헤더의 `title-slide-attributes`로 제어. QMD 본문에 직접 작성하지 않음:

```yaml
title-slide-attributes:
  data-background-image: bg.png
  data-background-size: cover
  data-background-opacity: "0.3"
```

* `data-background-opacity`를 높이면 배경이 선명, 낮추면 투명
* 로고·페이지번호는 header-inject.html에서 `:first-child`로 자동 숨김

## header-inject.html 구조와 수정 규칙

### CSS 영역 (`<style>`)

순서대로:

1. **일반 모드 로고**: `.kdh-logo` — `position: fixed`, `top: 46px`, `right: 8.5%`, `height: 54px`
2. **Print-PDF에서 일반 로고/슬라이드번호 숨기기**: `html.print-pdf .kdh-logo { display: none }` 등
3. **Pure CSS 로고 (print-pdf 전용)**: `.pdf-page::before` — `background: url('img/kangdong\_logo.svg')`, `width: 252px`, `height: 54px`
4. **Pure CSS 페이지번호 (print-pdf 전용)**: `.pdf-page::after` — CSS counter 사용, `font-size: 14px`, `color: #666`
5. **슬라이드별 print 보정**: `.pdf-page:nth-child(N)` 셀렉터로 특정 슬라이드 CSS 조정
6. **첫/마지막 슬라이드 숨김**: `.pdf-page:first-child`, `.pdf-page:last-child`에서 `::before`/`::after` 숨김

### JS 영역 (`<script>`)

* `if (!/print-pdf/gi.test(window.location.search))` — print-pdf 모드에서는 JS 실행 안 함
* 일반 모드 전용: `setupNormalMode()` 함수

  * 로고 img 동적 생성 → `.reveal`에 appendChild
  * `Reveal.on('slidechanged', updateVisibility)` — 첫/마지막 슬라이드에서 로고·footer·slide-number 숨기기

### 로고 위치/크기 수치 근거

* `top: 46px` — h2 제목 아래, 콘텐츠 시작 전 영역
* `right: 8.5%` — 슬라이드 번호(`right: 8.5%`)와 수평 정렬
* `width: 252px`, `height: 54px` — 로고 원본 비율 유지하면서 적당한 크기
* `opacity: 0.85` — 콘텐츠를 가리지 않도록 약간 투명
* `z-index: 200` — 콘텐츠 위에 표시되도록

### 수정 시 주의사항

* **`html.print-pdf`와 `html.reveal-print` 두 셀렉터 모두 작성**: Reveal.js 버전에 따라 클래스명이 다름
* **페이지번호 하드코딩**: `content: counter(pdf-slide) " / 26"` — **슬라이드 추가/삭제 시 총 수(26) 수동 변경 필요**
* **nth-child 번호**: 슬라이드 순서 변경 시 보정 대상 번호도 밀림. 반드시 확인

## 슬라이드 추가/삭제 시 동기화 체크리스트

1. **header-inject.html 총 페이지 수** — `" / 26"` 부분 업데이트
2. **header-inject.html nth-child 번호** — 기존 슬라이드별 print 보정 번호가 밀리지 않았는지 확인
3. **발표 대본(.docx)** — 해당 슬라이드 대본 추가/삭제/수정
4. **목차 슬라이드** — 구조 변경 시 목차 내용 업데이트
5. **렌더링 후 확인** — 일반 모드 + print-pdf 모드 둘 다

## 콘텐츠 overflow 대처 전략

슬라이드에 내용이 안 들어갈 때, 이 순서로 시도:

1. **spacer 제거/축소** — `.spacer-md` → `.spacer-sm` → `.spacer-xs` → 아예 제거
2. **폰트 크기 축소** — `.body-text` 대신 `.micro-text` (0.72em), 또는 인라인 `{style="font-size: 0.7em;"}`
3. **2단 레이아웃 활용** — 세로로 긴 내용을 좌우 2단으로 분산
4. **이미지 크기 축소** — `height="Xpx"` 줄이기, `max-height` 인라인 스타일
5. **슬라이드 분할** — 최후 수단. "제목 (1/2)", "제목 (2/2)" 또는 "제목 — 상세" 형식

**절대 하지 말 것**: `transform: scale()`로 전체 축소 — scrollHeight에 영향 없어서 PDF export 문제 발생

## 자주 발생하는 실수 및 금지사항

### QMD 문법 관련

* `:::` 닫기 빠뜨리기 → 이후 모든 슬라이드가 한 슬라이드에 합쳐짐. **열고 닫는 수가 반드시 맞아야 함**
* 중첩 div에서 콜론 수 혼동 → 바깥 `::::`(4개), 안쪽 `:::`(3개) 엄격히 구분
* `{.columns}` 없이 `{.column width="50%"}` 사용 → 컬럼 레이아웃 동작 안 함. **반드시 `:::: {.columns}`로 감싸기**
* 각주 `\\` 뒤에 공백 → 줄바꿈 안 됨

### CSS 관련

* 새 컴포넌트를 `zarathu\_theme.scss`에 추가 → **custom-style.css에 추가할 것**
* `!important` 남용 → 특정 print-pdf 보정이나 inline style 덮어쓸 때만 사용

### 이미지 관련

* 큰 이미지를 height 제한 없이 삽입 → PDF export에서 2페이지 할당 문제 발생
* PNG를 JPEG 대신 사용 → 용량만 커짐 (투명 배경 불필요 시)

### header-inject.html 관련

* print-pdf CSS에 `html.reveal-print` 셀렉터 누락 → 일부 Reveal.js 버전에서 동작 안 함
* 슬라이드 추가 후 nth-child 번호 미수정 → 엉뚱한 슬라이드에 보정 적용

## 발표 대본(DOCX) 수정 방법

python-docx 사용. **변경된 슬라이드 내용만 반영. 원본 텍스트는 절대 건드리지 않기.**

```python
from docx import Document
doc = Document('발표대본\_AI바우처\_서승인교수\_3.docx')

# 1. 문단 번호 확인 (0-based)
for i, p in enumerate(doc.paragraphs):
    print(i, p.text\[:60])

# 2. 단일 run 문단 수정
p = doc.paragraphs\[N]
p.runs\[0].text = "새 텍스트"

# 3. 복수 run 문단 수정 (Word가 서식 단위로 run을 쪼개놓은 경우)
p = doc.paragraphs\[N]
for r in p.runs\[1:]:
    r.\_element.getparent().remove(r.\_element)
p.runs\[0].text = "새 텍스트"

# 4. 문단 삽입 (특정 문단 뒤에)
from docx.oxml.ns import qn
ref\_p = doc.paragraphs\[N].\_element
new\_p\_el = ref\_p.addnext(ref\_p.makeelement(qn('w:p'), {}))
# 새 문단에 run 추가
from docx.oxml import OxmlElement
new\_run = OxmlElement('w:r')
new\_text = OxmlElement('w:t')
new\_text.text = "삽입할 텍스트"
new\_run.append(new\_text)
new\_p\_el.append(new\_run)

doc.save('발표대본.docx')
```

**주의**: Word 문서의 한 문단이 28개 run으로 쪼개져 있는 경우도 있음. 단순 `p.text` 치환이 아니라 run 단위로 처리해야 서식이 유지됨.

## 렌더링

```bash
quarto render index.qmd
```

* 결과: `index.html` + `index\_files/` (Reveal.js 라이브러리)
* `index\_files/libs/revealjs/` 안에 Reveal.js 코어와 플러그인(quarto-support 등)이 있음. **이 파일들은 수정하지 말 것** — 렌더링 시 매번 덮어씀
* 렌더링 후 반드시 HTML과 print-pdf 모두 확인

\---

## Reveal.js PDF Export (print-pdf 모드) 가이드

### 핵심 원리

* `?print-pdf` URL 파라미터로 진입 → `html.print-pdf` 클래스 추가
* Reveal.js가 각 `<section>`을 `.pdf-page` div로 감싸고, **scrollHeight 측정** 후 페이지 할당
* 1페이지 = **989px**. `scrollHeight > 989px`이면 2페이지(1978px) 할당 → **빈 페이지 발생**

### 2페이지 할당 문제 (가장 빈번한 문제)

**원인**: Reveal.js가 비동기 초기화 중 scrollHeight를 측정하는 시점에, 이미지가 아직 크기 제한 없이 렌더링되거나 inline-block columns가 wrap되어 높이가 일시적으로 989px 초과. CSS가 나중에 적용되어 실제로는 들어가지만, 페이지 할당은 이미 완료됨.

**근본 해결 — QMD에서 이미지 height 제한**:

```markdown
!\[](img/example.jpeg){width="100%" height="200px" fig-align="center"}
```

QMD에서 height를 명시하면 HTML `<img>` 태그에 height 속성이 직접 들어가서, Reveal.js 측정 시점부터 크기가 제한됨.

### CSS vs QMD: 어디에서 고치는지 판단 기준

**핵심 원칙**: scrollHeight 측정에 영향을 주는 요소(이미지 원본 크기)는 **QMD**에서, 측정 후 렌더링에만 영향을 주는 요소(마진, 폰트, 간격)는 **CSS**에서

|문제|CSS로 해결|QMD에서 해결|
|-|-|-|
|이미지 크기 → 2페이지 할당|`max-height` 보조적으로만|**`height="Xpx"` 필수**|
|텍스트-이미지 겹침|`margin-top` override|—|
|폰트 크기 미세 조정|`font-size` override|—|
|spacer 제거로 공간 확보|`display: none`|—|
|로고/페이지번호 표시|`::before`/`::after`|—|

### 절대 하면 안 되는 것들

* `transform: scale()` → scrollHeight를 줄이지 않아 Reveal.js 페이지 할당에 영향 없음
* `position: fixed` → print-pdf에서 페이지별 동작 안 함
* CSS `!important`로 `.pdf-page` height 강제 → 화면에서는 보이지만 **인쇄 시 콘텐츠 잘림**
* JS로 Reveal.js 초기화 후 inline height 수정 → 화면에선 OK지만 **인쇄 시 Chrome이 원래 레이아웃 사용**

**중요: PDF export mode 화면 스크린샷과 실제 Ctrl+P 인쇄 결과가 다를 수 있음. 반드시 실제 PDF 생성까지 검증.**

### 슬라이드별 print 보정 패턴 (header-inject.html에 추가)

```css
/\* 이미지 크기 제한 \*/
html.print-pdf .pdf-page:nth-child(N) section img,
html.reveal-print .pdf-page:nth-child(N) section img {
  max-height: 580px !important;
}

/\* 폰트 축소 \*/
html.print-pdf .pdf-page:nth-child(N) section,
html.reveal-print .pdf-page:nth-child(N) section {
  font-size: 0.88em !important;
}

/\* spacer 제거 \*/
html.print-pdf .pdf-page:nth-child(N) section .spacer-sm,
html.reveal-print .pdf-page:nth-child(N) section .spacer-sm {
  display: none !important;
}

/\* inline style margin override \*/
html.print-pdf .pdf-page:nth-child(N) section .column div\[style\*="margin-top"],
html.reveal-print .pdf-page:nth-child(N) section .column div\[style\*="margin-top"] {
  margin-top: 20px !important;
}
```

### Print-PDF 로고/페이지번호 (Pure CSS)

```css
/\* CSS counter \*/
html.print-pdf .reveal .slides { counter-reset: pdf-slide; }
html.print-pdf .reveal .slides .pdf-page { counter-increment: pdf-slide; }

/\* 로고: ::before \*/
html.print-pdf .reveal .slides .pdf-page::before {
  content: '';
  position: absolute;
  top: 46px; right: 8.5%;
  width: 252px; height: 54px;
  background: url('img/kangdong\_logo.svg') no-repeat right center / contain;
  z-index: 200; opacity: 0.85;
}

/\* 페이지번호: ::after \*/
html.print-pdf .reveal .slides .pdf-page::after {
  content: counter(pdf-slide) " / 26";
  position: absolute;
  bottom: 16px; right: 8.5%;
  font-size: 14px; color: #666; z-index: 200;
}

/\* 첫/마지막 숨김 \*/
html.print-pdf .reveal .slides .pdf-page:first-child::before,
html.print-pdf .reveal .slides .pdf-page:first-child::after,
html.print-pdf .reveal .slides .pdf-page:last-child::before,
html.print-pdf .reveal .slides .pdf-page:last-child::after {
  display: none !important;
}
```

### print-pdf 디버깅 팁

1. **scrollHeight 확인**: DevTools Console에서 `document.querySelectorAll('.pdf-page').forEach((p,i) => console.log(i+1, p.style.height, p.querySelector('section').scrollHeight))`
2. **2페이지 할당 여부 확인**: `height: 1978px`인 pdf-page가 있으면 2페이지로 할당된 것
3. **어떤 요소가 높이를 초과시키는지**: 해당 section 안의 요소를 하나씩 `display:none`으로 숨기면서 scrollHeight 변화 관찰
4. **실제 PDF 생성 검증**: 화면에서 OK여도 Ctrl+P → PDF 저장 시 잘리는 경우 있음. 반드시 마지막에 실제 PDF로 확인

### PDF 자동 검증 (Playwright, headless 환경)

```bash
# 필요 라이브러리 설치 (최초 1회)
cd /tmp \&\& mkdir -p libs
apt download libgbm1 libwayland-server0 libwayland-client0 libxkbcommon0 libegl1 libgles2
# 각각 dpkg-deb -x \*.deb /tmp/libs/ 로 풀기

# 실행
LD\_LIBRARY\_PATH=/tmp/libs/usr/lib/x86\_64-linux-gnu/:$LD\_LIBRARY\_PATH \\
npx playwright launch --browser chromium
```

* `page.goto('file:///path/to/index.html?print-pdf')` → `page.pdf()`로 실제 PDF 생성
* 총 페이지 수가 슬라이드 수와 일치하는지 확인 (빈 페이지 = 2페이지 할당 문제)

