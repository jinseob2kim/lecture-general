// usage: node fit.js <url> <out.css> [maxBottom=800] [maxRight=1568] [zmax=1.7]
// 슬라이드별로 h2 이외 자식에 zoom 을 걸어 bottom/right 한계 안에서 가장 큰 값을 찾고 CSS 로 저장
const puppeteer = require('/home/js/.nvm/versions/node/v22.18.0/lib/node_modules/decktape/node_modules/puppeteer-core');
const fs = require('fs');
(async () => {
  const [url, out, mb, mr, zm, zn] = process.argv.slice(2);
  const maxB = Number(mb || 800), maxR = Number(mr || 1568), zmax = Number(zm || 1.7), zmin = Number(zn || 0.78);
  const browser = await puppeteer.launch({
    executablePath: '/home/js/.cache/ms-playwright/chromium-1140/chrome-linux/chrome',
    headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage']});
  const page = await browser.newPage();
  await page.setViewport({width: 1600, height: 900});
  await page.goto(url, {waitUntil: 'networkidle0', timeout: 120000});
  await page.waitForFunction('typeof Reveal !== "undefined" && Reveal.isReady()', {timeout: 60000});
  await page.evaluate(() => Reveal.configure({transition: 'none', backgroundTransition: 'none'}));
  await page.evaluate(() => document.fonts.ready);
  const n = await page.evaluate(() => Reveal.getSlides().length);
  const rules = [], log = [];
  for (let k = 0; k < n; k++) {
    const res = await page.evaluate(async (k, maxB, maxR, zmax, zmin) => {
      const s = Reveal.getSlides()[k];
      const i = Reveal.getIndices(s); Reveal.slide(i.h, i.v || 0);
      await new Promise(r => setTimeout(r, 150));
      if (!s.id || s.classList.contains('title-slide') || s.querySelector('h1') || s.id === 'thanks' || s.classList.contains('nofit')) return null;
      const kids = Array.from(s.children).filter(el => el.tagName !== 'H2' && !el.classList.contains('slide-master-header'));
      const measure = () => {
        const scale = Reveal.getScale();
        const top = s.getBoundingClientRect().top;
        const left = s.getBoundingClientRect().left;
        let b = 0, r = 0;
        kids.forEach(kid => [kid, ...kid.querySelectorAll('*')].forEach(el => {
          const rc = el.getBoundingClientRect();
          if (rc.width === 0 || rc.height === 0) return;
          b = Math.max(b, (rc.bottom - top) / scale);
          r = Math.max(r, (rc.right - left) / scale);
        }));
        return [b, r];
      };
      const setZ = z => kids.forEach(el => { el.style.zoom = z; });
      setZ(1); const [b0, r0] = measure();
      let lo = zmin, hi = zmax;
      setZ(hi); let [bh, rh] = measure();
      if (bh <= maxB && rh <= maxR) { lo = hi; }
      else {
        for (let it = 0; it < 14; it++) {
          const mid = (lo + hi) / 2; setZ(mid);
          const [b, r] = measure();
          if (b <= maxB && r <= maxR) lo = mid; else hi = mid;
        }
      }
      setZ(lo); const [b1, r1] = measure();
      setZ('');
      return {id: s.id, z: Math.floor(lo * 100) / 100, b0: Math.round(b0), r0: Math.round(r0), b1: Math.round(b1), r1: Math.round(r1)};
    }, k, maxB, maxR, zmax, zmin);
    if (!res) continue;
    log.push(`${res.id} z=${res.z} bottom ${res.b0}->${res.b1} right ${res.r0}->${res.r1}`);
    if (Math.abs(res.z - 1.0) > 0.005) rules.push(`#${res.id} > :not(h2):not(.slide-master-header) { zoom: ${res.z}; }`);
  }
  fs.writeFileSync(out, '/* fit.js 자동 생성: 슬라이드별 화면 채우기 zoom */\n' + rules.join('\n') + '\n');
  console.log(log.join('\n'));
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
