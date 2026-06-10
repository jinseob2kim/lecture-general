#!/usr/bin/env python3
# Early / Intermediate / Late 멀티오믹스 통합 시점 개념도
import os
FONT = "'Malgun Gothic','Noto Sans KR',sans-serif"
OUT = os.path.dirname(os.path.abspath(__file__))
W, H = 640, 430
G, T, P = "#2E7D32", "#1565C0", "#00838F"
PUR, PURL = "#7B1FA2", "#BA68C8"
GRY = "#555"

b = ['<defs><marker id="ar" markerWidth="9" markerHeight="9" refX="7" refY="4" orient="auto">'
     '<path d="M0 0 L8 4 L0 8 Z" fill="#666"/></marker></defs>']

def stack(x, yc):
    """3 오믹스 입력 블록 (G/T/P) 세로 스택. 각 블록 중심 y 반환."""
    out, centers = [], []
    sw, sh, gap = 28, 18, 4
    tot = 3*sh + 2*gap
    y0 = yc - tot/2
    for i, (lab, col) in enumerate([("G", G), ("T", T), ("P", P)]):
        yy = y0 + i*(sh+gap)
        out.append(f'<rect x="{x}" y="{yy:.0f}" width="{sw}" height="{sh}" rx="3" fill="{col}"/>')
        out.append(f'<text x="{x+sw/2}" y="{yy+13:.0f}" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">{lab}</text>')
        centers.append(yy + sh/2)
    return out, x+sw, centers

def arrow(x1, y1, x2, y2):
    return f'<line x1="{x1:.0f}" y1="{y1:.0f}" x2="{x2:.0f}" y2="{y2:.0f}" stroke="#666" stroke-width="1.8" marker-end="url(#ar)"/>'

def circle(x, y, lab, fill=PUR, r=15):
    return [f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"/>',
            f'<text x="{x}" y="{y+4}" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">{lab}</text>']

def label(x, yc, txt, col):
    return f'<text x="{x}" y="{yc+5}" font-size="15" font-weight="800" fill="{col}">{txt}</text>'

LX = 12            # 좌측 라벨
SX = 118          # 오믹스 스택
MX = 232          # 중간 노드
KX = 372          # 모델
RX = 470          # 결과(Late)
ycs = [78, 215, 352]

# 구분선
for yy in (148, 285):
    b.append(f'<line x1="6" y1="{yy}" x2="{W-6}" y2="{yy}" stroke="#E0E0E0" stroke-width="1"/>')

# ---------- Early ----------
yc = ycs[0]
b.append(label(LX, yc, "Early", PUR))
s, rx, cys = stack(SX, yc); b += s
b.append(arrow(rx+4, yc, MX-6, yc))
# concatenate: 3 세로 스트라이프 한 박스
cw, ch = 26, 66
for i, col in enumerate([G, T, P]):
    b.append(f'<rect x="{MX+i*cw}" y="{yc-ch/2:.0f}" width="{cw}" height="{ch}" fill="{col}" opacity="0.9"/>')
b.append(f'<rect x="{MX}" y="{yc-ch/2:.0f}" width="{3*cw}" height="{ch}" fill="none" stroke="#333" stroke-width="1.6"/>')
b.append(f'<text x="{MX+3*cw/2}" y="{yc+ch/2+15:.0f}" text-anchor="middle" font-size="11" fill="#555">한 행렬로 연결</text>')
b.append(arrow(MX+3*cw+4, yc, KX-16, yc))
b += circle(KX, yc, "모델")
b.append(f'<text x="{KX+24}" y="{yc+4}" font-size="12" fill="#333">단일 모델</text>')

# ---------- Intermediate ----------
yc = ycs[1]
b.append(label(LX, yc, "Intermed.", PUR))
s, rx, cys = stack(SX, yc); b += s
# 각 오믹스 → 공통 잠재인자 박스로 수렴
fx, fy, fw, fh = MX, yc-32, 78, 64
for cyv in cys:
    b.append(arrow(rx+4, cyv, fx-6, yc))
b.append(f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" rx="8" fill="#F3E5F5" stroke="{PUR}" stroke-width="1.8"/>')
for i in range(3):
    b.append(f'<circle cx="{fx+20+i*20}" cy="{yc-6}" r="6" fill="{PURL}"/>')
b.append(f'<text x="{fx+fw/2}" y="{yc+18}" text-anchor="middle" font-size="10.5" fill="{PUR}" font-weight="700">공통 factor</text>')
b.append(arrow(fx+fw+4, yc, KX-16, yc))
b += circle(KX, yc, "모델")
b.append(f'<text x="{KX+24}" y="{yc-2}" font-size="12" fill="#333">MOFA·SNF</text>')
b.append(f'<text x="{KX+24}" y="{yc+14}" font-size="12" fill="#333">DIABLO</text>')

# ---------- Late ----------
yc = ycs[2]
b.append(label(LX, yc, "Late", PUR))
s, rx, cys = stack(SX, yc); b += s
# 각 오믹스 → 각자 모델 → 결과 통합
mcols = [G, T, P]
for cyv, col in zip(cys, mcols):
    b.append(arrow(rx+4, cyv, MX-2, cyv))
    b += circle(MX+14, cyv, "M", fill=col, r=12)
for cyv in cys:
    b.append(arrow(MX+28, cyv, KX-16, yc))
b += circle(KX, yc, "통합", fill=PUR)
b.append(f'<text x="{KX+24}" y="{yc+4}" font-size="12" fill="#333">결과 결합</text>')
b.append(f'<text x="{MX-4}" y="{yc+50}" text-anchor="middle" font-size="11" fill="#555">계층별 모델</text>')

svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" font-family="{FONT}">\n'
       + "\n".join(b) + "\n</svg>\n")
with open(os.path.join(OUT, "feat_integration.svg"), "w") as f:
    f.write(svg)
print("wrote feat_integration.svg")
