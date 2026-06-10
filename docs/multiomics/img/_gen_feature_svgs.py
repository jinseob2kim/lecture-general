#!/usr/bin/env python3
# 멀티오믹스 6대 특징 슬라이드용 개념 SVG 생성 (덱 색상 체계)
import math, os

FONT = "'Malgun Gothic','Noto Sans KR',sans-serif"
OUT = os.path.dirname(os.path.abspath(__file__))

def save(name, body, w=620, h=440):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" '
           f'font-family="{FONT}">\n{body}\n</svg>\n')
    with open(os.path.join(OUT, name), 'w') as f:
        f.write(svg)
    print("wrote", name)

# 결정적 난수 (재현성)
class RNG:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (1103515245*self.s + 12345) & 0x7fffffff
        return self.s / 0x7fffffff

# ---------------------------------------------------------------- ① 고차원 p>>n
def matrix():
    b = []
    b.append('<defs><pattern id="cellG" width="26" height="26" patternUnits="userSpaceOnUse">'
             '<rect width="26" height="26" fill="#E8F5E9" stroke="#66BB6A" stroke-width="1"/></pattern></defs>')
    # wide-short matrix: 18 cols x 4 rows
    mx, my, mw, mh = 76, 150, 468, 104
    b.append(f'<rect x="{mx}" y="{my}" width="{mw}" height="{mh}" fill="url(#cellG)" stroke="#1B5E20" stroke-width="2.5"/>')
    # p brace (top)
    b.append(f'<path d="M{mx} 134 L{mx} 126 L{mx+mw} 126 L{mx+mw} 134" fill="none" stroke="#2E7D32" stroke-width="2"/>')
    b.append('<text x="310" y="116" text-anchor="middle" font-size="21" font-weight="700" fill="#1B5E20">p = 변수(마커) · 수만~수백만</text>')
    # n brace (left)
    b.append(f'<path d="M58 {my} L50 {my} L50 {my+mh} L58 {my+mh}" fill="none" stroke="#2E7D32" stroke-width="2"/>')
    b.append(f'<text x="40" y="202" text-anchor="middle" font-size="18" font-weight="700" fill="#1B5E20" transform="rotate(-90 40 202)">n = 표본 · 수십~수백</text>')
    b.append('<text x="310" y="322" text-anchor="middle" font-size="46" font-weight="800" fill="#2E7D32">p ≫ n</text>')
    b.append('<text x="310" y="362" text-anchor="middle" font-size="18" fill="#37474F">차원의 저주 · 과적합 · 회귀 해 불안정</text>')
    save('feat_highdim.svg', "\n".join(b))

# ---------------------------------------------------------------- ② 다중공선성 LD
def ld():
    b = []
    b.append('<defs>'
             '<linearGradient id="ldg" x1="0" y1="0" x2="0" y2="1">'
             '<stop offset="0%" stop-color="#0D47A1"/><stop offset="50%" stop-color="#1976D2"/>'
             '<stop offset="100%" stop-color="#E3F2FD"/></linearGradient>'
             '<pattern id="ldgrid" width="34" height="34" patternUnits="userSpaceOnUse" patternTransform="rotate(45 0 0)">'
             '<rect width="34" height="34" fill="none" stroke="#90CAF9" stroke-width="1" opacity="0.55"/></pattern>'
             '</defs>')
    # SNP markers row
    x0, x1, y = 120, 500, 122
    b.append(f'<line x1="{x0}" y1="{y}" x2="{x1}" y2="{y}" stroke="#0D47A1" stroke-width="2"/>')
    n = 9
    for i in range(n):
        cx = x0 + (x1-x0)*i/(n-1)
        b.append(f'<circle cx="{cx:.0f}" cy="{y}" r="6" fill="#1565C0" stroke="#0D47A1" stroke-width="1.5"/>')
    b.append(f'<text x="310" y="98" text-anchor="middle" font-size="17" fill="#37474F">SNP (염색체상 인접 변이)</text>')
    # LD triangle
    apex = (310, 360)
    b.append(f'<polygon points="{x0},{y+8} {x1},{y+8} {apex[0]},{apex[1]}" fill="url(#ldg)" stroke="#0D47A1" stroke-width="2"/>')
    b.append(f'<polygon points="{x0},{y+8} {x1},{y+8} {apex[0]},{apex[1]}" fill="url(#ldgrid)"/>')
    b.append('<text x="310" y="404" text-anchor="middle" font-size="18" font-weight="700" fill="#0D47A1">LD block — 인접 변이끼리 강한 상관 (r² ↑)</text>')
    save('feat_collinearity.svg', "\n".join(b))

# ---------------------------------------------------------------- ③ 다중검정 Manhattan
def manhattan():
    b = []
    L, R, T, B = 72, 556, 70, 330
    ymax = 10.0
    def yv(v): return B - (v/ymax)*(B-T)
    bands = 6
    bw = (R-L)/bands
    teal_dark, teal_light = "#00838F", "#4DB6AC"
    rng = RNG(7)
    # background bands
    for i in range(bands):
        if i % 2 == 0:
            b.append(f'<rect x="{L+i*bw:.1f}" y="{T}" width="{bw:.1f}" height="{B-T}" fill="#E0F2F1" opacity="0.6"/>')
    # axes
    b.append(f'<line x1="{L}" y1="{B}" x2="{R}" y2="{B}" stroke="#37474F" stroke-width="2"/>')
    b.append(f'<line x1="{L}" y1="{T}" x2="{L}" y2="{B}" stroke="#37474F" stroke-width="2"/>')
    # threshold line at 5e-8 (-log10 = 7.3)
    yt = yv(7.3)
    b.append(f'<line x1="{L}" y1="{yt:.1f}" x2="{R}" y2="{yt:.1f}" stroke="#C62828" stroke-width="2" stroke-dasharray="7 5"/>')
    b.append(f'<text x="{R-4}" y="{yt-7:.1f}" text-anchor="end" font-size="14" font-weight="700" fill="#C62828">genome-wide P = 5×10⁻⁸</text>')
    # points
    peak_bands = {1:8.6, 4:9.2}
    for i in range(bands):
        col = teal_dark if i % 2 == 0 else teal_light
        npts = 16
        for k in range(npts):
            x = L + i*bw + 8 + rng.next()*(bw-16)
            v = 0.2 + rng.next()*2.6  # background noise
            # occasional mild bump
            if rng.next() > 0.85: v += rng.next()*1.6
            b.append(f'<circle cx="{x:.1f}" cy="{yv(v):.1f}" r="3.1" fill="{col}"/>')
        # peak cluster
        if i in peak_bands:
            top = peak_bands[i]
            cxp = L + i*bw + bw*0.5
            for k in range(9):
                dx = (rng.next()-0.5)*46
                vv = top - abs(dx)/46*4.2 - rng.next()*0.7
                b.append(f'<circle cx="{cxp+dx:.1f}" cy="{yv(vv):.1f}" r="3.4" fill="#006064"/>')
    # y label
    b.append(f'<text x="34" y="{(T+B)/2:.0f}" text-anchor="middle" font-size="16" font-weight="700" fill="#37474F" transform="rotate(-90 34 {(T+B)/2:.0f})">−log₁₀(P)</text>')
    b.append(f'<text x="{(L+R)/2:.0f}" y="{B+26}" text-anchor="middle" font-size="16" fill="#37474F">염색체 위치 (수십만~수백만 변이 동시 검정)</text>')
    b.append(f'<text x="{(L+R)/2:.0f}" y="{B+52}" text-anchor="middle" font-size="15" fill="#C62828">붉은 선 위 신호만 유의 — 보정 없이는 위양성 폭증</text>')
    save('feat_multipletest.svg', "\n".join(b))

# ---------------------------------------------------------------- ④ 데이터 이종성 분포
def distributions():
    b = []
    purple, pd, pl = "#7B1FA2", "#4A148C", "#F3E5F5"
    panels = [
        ("유전형 SNP", "범주 0 / 1 / 2", "cat"),
        ("RNA-seq", "count · 과분산", "skew"),
        ("메틸화 β", "0~1 경계 · 양극", "beta"),
        ("단백·대사체", "연속 · log 정규", "lognorm"),
    ]
    # 2 x 2 grid
    pw, ph = 270, 146
    gx, gy = 40, 58
    gap = 16
    for idx, (title, sub, kind) in enumerate(panels):
        col = idx % 2; row = idx // 2
        ox = gx + col*(pw+gap)
        oy = gy + row*(ph+30+14)
        b.append(f'<rect x="{ox}" y="{oy}" width="{pw}" height="{ph+30}" rx="8" fill="#FFFFFF" stroke="#BA68C8" stroke-width="1.6"/>')
        b.append(f'<text x="{ox+12}" y="{oy+22}" font-size="16" font-weight="700" fill="#4A148C">{title}</text>')
        b.append(f'<text x="{ox+pw-12}" y="{oy+22}" text-anchor="end" font-size="12" fill="#7B1FA2">{sub}</text>')
        # plot area
        px, py, pwd, pht = ox+16, oy+34, pw-32, ph-22
        base = py+pht
        b.append(f'<line x1="{px}" y1="{base}" x2="{px+pwd}" y2="{base}" stroke="#9E9E9E" stroke-width="1.4"/>')
        if kind == "cat":
            hs = [0.55, 0.95, 0.45]
            bw = pwd/ (len(hs)*1.7)
            for i,h in enumerate(hs):
                bx = px + pwd*(0.12 + i*0.30)
                bh = h*pht
                b.append(f'<rect x="{bx:.1f}" y="{base-bh:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="{purple}" opacity="0.85"/>')
                b.append(f'<text x="{bx+bw/2:.1f}" y="{base+15:.1f}" text-anchor="middle" font-size="12" fill="#4A148C">{i}</text>')
        elif kind == "skew":
            hs = [0.95,0.78,0.55,0.38,0.26,0.17,0.10,0.06]
            bw = pwd/len(hs)
            for i,h in enumerate(hs):
                bx = px + i*bw
                bh = h*pht
                b.append(f'<rect x="{bx:.1f}" y="{base-bh:.1f}" width="{bw-2:.1f}" height="{bh:.1f}" fill="{purple}" opacity="0.85"/>')
        elif kind == "beta":
            hs = [0.92,0.5,0.28,0.18,0.16,0.18,0.30,0.55,0.95]
            bw = pwd/len(hs)
            for i,h in enumerate(hs):
                bx = px + i*bw
                bh = h*pht
                b.append(f'<rect x="{bx:.1f}" y="{base-bh:.1f}" width="{bw-2:.1f}" height="{bh:.1f}" fill="{purple}" opacity="0.85"/>')
            b.append(f'<text x="{px+2}" y="{base+15}" font-size="11" fill="#4A148C">0</text>')
            b.append(f'<text x="{px+pwd-2}" y="{base+15}" text-anchor="end" font-size="11" fill="#4A148C">1</text>')
        elif kind == "lognorm":
            pts = []
            for i in range(40):
                x = i/39.0
                # log-normal-ish curve
                t = (x*3.2)+0.05
                yv = (1/(t*0.85))*math.exp(-((math.log(t)+0.2)**2)/(2*0.55**2))
                pts.append((px + x*pwd, yv))
            mxy = max(p[1] for p in pts)
            poly = " ".join(f"{p[0]:.1f},{base-(p[1]/mxy)*pht:.1f}" for p in pts)
            b.append(f'<polyline points="{px},{base} {poly} {px+pwd},{base}" fill="{purple}" fill-opacity="0.3" stroke="{purple}" stroke-width="2"/>')
    save('feat_heterogeneity.svg', "\n".join(b))

# ---------------------------------------------------------------- ⑤ 기술 잡음·교란 batch
def batch():
    b = []
    cA, cB = "#EF6C00", "#5E35B1"   # batch 1 / 2
    frame = "#37474F"
    def panel(ox, oy, w, h, title, mixed):
        out = [f'<rect x="{ox}" y="{oy}" width="{w}" height="{h}" rx="8" fill="#ECEFF1" stroke="{frame}" stroke-width="1.8"/>']
        out.append(f'<text x="{ox+w/2}" y="{oy+24}" text-anchor="middle" font-size="17" font-weight="700" fill="#263238">{title}</text>')
        # axes
        ax0, ay0 = ox+30, oy+h-26
        out.append(f'<line x1="{ax0}" y1="{ay0}" x2="{ox+w-18}" y2="{ay0}" stroke="#90A4AE" stroke-width="1.4"/>')
        out.append(f'<line x1="{ax0}" y1="{oy+38}" x2="{ax0}" y2="{ay0}" stroke="#90A4AE" stroke-width="1.4"/>')
        out.append(f'<text x="{ax0-6}" y="{oy+46}" text-anchor="end" font-size="11" fill="#607D8B">PC2</text>')
        out.append(f'<text x="{ox+w-16}" y="{ay0+4}" font-size="11" fill="#607D8B">PC1</text>')
        rng = RNG(3 if mixed else 11)
        cx0, cy0 = ox+w*0.40, oy+h*0.55
        for grp,(col,cxoff) in enumerate([(cA,-1),(cB,1)]):
            for k in range(14):
                if mixed:
                    cx = cx0 + (rng.next()-0.5)*w*0.46
                    cy = cy0 + (rng.next()-0.5)*h*0.46
                else:
                    cx = cx0 + cxoff*w*0.17 + (rng.next()-0.5)*w*0.20
                    cy = cy0 + (rng.next()-0.5)*h*0.42
                out.append(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="4.4" fill="{col}" opacity="0.85"/>')
        return out
    b += panel(34, 84, 248, 230, "보정 전 — batch별 분리", False)
    b += panel(338, 84, 248, 230, "보정 후 — 혼합", True)
    # arrow
    b.append('<defs><marker id="ar" markerWidth="12" markerHeight="12" refX="8" refY="4" orient="auto">'
             '<path d="M0 0 L9 4 L0 8 Z" fill="#37474F"/></marker></defs>')
    b.append('<line x1="288" y1="199" x2="332" y2="199" stroke="#37474F" stroke-width="3" marker-end="url(#ar)"/>')
    b.append('<text x="310" y="186" text-anchor="middle" font-size="13" font-weight="700" fill="#37474F">ComBat·SVA</text>')
    # legend
    b.append(f'<circle cx="70" cy="350" r="6" fill="{cA}"/><text x="84" y="355" font-size="14" fill="#263238">Batch 1</text>')
    b.append(f'<circle cx="180" cy="350" r="6" fill="{cB}"/><text x="194" y="355" font-size="14" fill="#263238">Batch 2</text>')
    b.append('<text x="320" y="355" font-size="14" fill="#37474F">집단구조·세포조성도 동일하게 PC 보정 필요</text>')
    save('feat_batch.svg', "\n".join(b))

# ---------------------------------------------------------------- ⑥ 사전지식·공개데이터
def reference():
    b = []
    green, gd = "#2E7D32", "#1B5E20"
    # center node
    cx, cy = 310, 230
    b.append(f'<rect x="{cx-92}" y="{cy-42}" width="184" height="84" rx="14" fill="#2E7D32" stroke="#1B5E20" stroke-width="2.5"/>')
    b.append(f'<text x="{cx}" y="{cy-6}" text-anchor="middle" font-size="20" font-weight="800" fill="#FFFFFF">통합 분석</text>')
    b.append(f'<text x="{cx}" y="{cy+22}" text-anchor="middle" font-size="13" fill="#C8E6C9">enrichment · MR · imputation · PRS</text>')
    # DB cylinders around
    dbs = [
        (118, 96, "GWAS Catalog", "변이–형질"),
        (502, 96, "GTEx (eQTL)", "조절"),
        (118, 364, "KEGG·Reactome", "경로·기능"),
        (502, 364, "1000G·TopMed", "참조 패널"),
    ]
    b.append('<defs><marker id="arg" markerWidth="12" markerHeight="12" refX="8" refY="4" orient="auto">'
             '<path d="M0 0 L9 4 L0 8 Z" fill="#66BB6A"/></marker></defs>')
    for (x,y,name,sub) in dbs:
        # cylinder
        w,h = 132, 56
        b.append(f'<ellipse cx="{x}" cy="{y-h/2}" rx="{w/2}" ry="10" fill="#A5D6A7" stroke="{gd}" stroke-width="2"/>')
        b.append(f'<rect x="{x-w/2}" y="{y-h/2}" width="{w}" height="{h}" fill="#E8F5E9" stroke="{gd}" stroke-width="2"/>')
        b.append(f'<line x1="{x-w/2}" y1="{y-h/2}" x2="{x-w/2}" y2="{y+h/2}" stroke="{gd}" stroke-width="2"/>')
        b.append(f'<line x1="{x+w/2}" y1="{y-h/2}" x2="{x+w/2}" y2="{y+h/2}" stroke="{gd}" stroke-width="2"/>')
        b.append(f'<ellipse cx="{x}" cy="{y+h/2}" rx="{w/2}" ry="10" fill="#E8F5E9" stroke="{gd}" stroke-width="2"/>')
        b.append(f'<text x="{x}" y="{y-2}" text-anchor="middle" font-size="14" font-weight="700" fill="#1B5E20">{name}</text>')
        b.append(f'<text x="{x}" y="{y+16}" text-anchor="middle" font-size="11" fill="#2E7D32">{sub}</text>')
        # arrow to center
        b.append(f'<line x1="{x + (70 if x<cx else -70):.0f}" y1="{y + (24 if y<cy else -24):.0f}" '
                 f'x2="{cx + (-96 if x<cx else 96):.0f}" y2="{cy + (-30 if y<cy else 30):.0f}" '
                 f'stroke="#66BB6A" stroke-width="2.5" marker-end="url(#arg)"/>')
    save('feat_reference.svg', "\n".join(b))

matrix(); ld(); manhattan(); distributions(); batch(); reference()
print("done")
