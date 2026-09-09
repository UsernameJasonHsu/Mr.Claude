---
name: performance-optimization
description: 最佳化應用程式效能。適用於存在效能需求、懷疑發生效能劣化，或需要改善 Core Web Vitals 或載入時間時。適用於效能剖析（profiling）發現需要修正的瓶頸時。
---

# 效能最佳化

## 概述

先量測，再最佳化。沒有量測的效能工作就是在猜 —— 而猜測會導致過早最佳化：增加了複雜度，卻沒有改善真正重要的東西。先做效能剖析、找出真正的瓶頸、修好它、再量一次。只最佳化那些量測結果證明重要的部分。

## 適用時機

- 規格中有效能需求（載入時間預算、回應時間 SLA）
- 使用者或監控回報系統很慢
- Core Web Vitals 分數低於門檻
- 你懷疑某項變更造成了效能退步
- 建置處理大量資料或高流量的功能

**不適用時機：** 在沒有問題證據之前不要做最佳化。過早最佳化增加的複雜度，代價高過它換來的效能。

## Core Web Vitals 目標

| 指標 | Good | Needs Improvement | Poor |
|------|------|-------------------|------|
| **LCP**（Largest Contentful Paint） | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **INP**（Interaction to Next Paint） | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS**（Cumulative Layout Shift） | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## 最佳化流程

```
1. MEASURE  → Establish baseline with real data
2. IDENTIFY → Find the actual bottleneck (not assumed)
3. FIX      → Address the specific bottleneck
4. VERIFY   → Measure again, confirm improvement
5. GUARD    → Add monitoring or tests to prevent regression
```

### 步驟 1：量測

兩種互補的做法 —— 兩者都要用：

- **合成測試（Lighthouse、DevTools Performance 分頁）：** 條件受控、可重現。最適合用在 CI 的退步偵測，以及隔離特定問題。
- **RUM（web-vitals 函式庫、CrUX）：** 真實條件下的真實使用者資料。要驗證某項修正是否真的改善了使用者體驗，這是必要的。

**前端：**
```bash
# Synthetic: Lighthouse in Chrome DevTools (or CI)
# Chrome DevTools → Performance tab → Record
# Chrome DevTools MCP → Performance trace

# RUM: Web Vitals library in code
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

**後端：**
```bash
# Response time logging
# Application Performance Monitoring (APM)
# Database query logging with timing

# Simple timing
console.time('db-query');
const result = await db.query(...);
console.timeEnd('db-query');
```

### 該從哪裡開始量測

用症狀來決定先量什麼：

```
What is slow?
├── First page load
│   ├── Large bundle? --> Measure bundle size, check code splitting
│   ├── Slow server response? --> Measure TTFB in DevTools Network waterfall
│   │   ├── DNS long? --> Add dns-prefetch / preconnect for known origins
│   │   ├── TCP/TLS long? --> Enable HTTP/2, check edge deployment, keep-alive
│   │   └── Waiting (server) long? --> Profile backend, check queries and caching
│   └── Render-blocking resources? --> Check network waterfall for CSS/JS blocking
├── Interaction feels sluggish
│   ├── UI freezes on click? --> Profile main thread, look for long tasks (>50ms)
│   ├── Form input lag? --> Check re-renders, controlled component overhead
│   └── Animation jank? --> Check layout thrashing, forced reflows
├── Page after navigation
│   ├── Data loading? --> Measure API response times, check for waterfalls
│   └── Client rendering? --> Profile component render time, check for N+1 fetches
└── Backend / API
    ├── Single endpoint slow? --> Profile database queries, check indexes
    ├── All endpoints slow? --> Check connection pool, memory, CPU
    └── Intermittent slowness? --> Check for lock contention, GC pauses, external deps
```

### 步驟 2：找出瓶頸

依類別常見的瓶頸：

**前端：**

| 症狀 | 可能原因 | 怎麼查 |
|------|---------|--------|
| LCP 慢 | 大圖、阻塞渲染的資源、伺服器慢 | 看網路瀑布圖、圖片大小 |
| CLS 高 | 圖片沒有指定尺寸、內容太晚載入、字型造成位移 | 查看版面位移的歸因 |
| INP 差 | 主執行緒上有大量 JavaScript、大範圍 DOM 更新 | 在效能追蹤中找長任務 |
| 初次載入慢 | bundle 太大、網路請求太多 | 檢查 bundle 大小、程式碼分割 |

**後端：**

| 症狀 | 可能原因 | 怎麼查 |
|------|---------|--------|
| API 回應慢 | N+1 查詢、缺索引、查詢沒最佳化 | 看資料庫查詢日誌 |
| 記憶體不斷成長 | 洩漏的引用、沒有上限的快取、過大的載荷 | 分析 heap 快照 |
| CPU 尖峰 | 同步的重運算、regex 回溯 | CPU 效能剖析 |
| 延遲高 | 缺快取、重複運算、網路跳點太多 | 追蹤請求穿越整個堆疊 |

### 步驟 3：修正常見反模式

#### N+1 查詢（後端）

```typescript
// BAD: N+1 — one query per task for the owner
const tasks = await db.tasks.findMany();
for (const task of tasks) {
  task.owner = await db.users.findUnique({ where: { id: task.ownerId } });
}

// GOOD: Single query with join/include
const tasks = await db.tasks.findMany({
  include: { owner: true },
});
```

#### 沒有上限的資料抓取

```typescript
// BAD: Fetching all records
const allTasks = await db.tasks.findMany();

// GOOD: Paginated with limits
const tasks = await db.tasks.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' },
});
```

#### 缺少圖片最佳化（前端）

```html
<!-- BAD: No dimensions, no format optimization -->
<img src="/hero.jpg" />

<!-- GOOD: Hero / LCP image — art direction + resolution switching, high priority -->
<!--
  Two techniques combined:
  - Art direction (media): different crop/composition per breakpoint
  - Resolution switching (srcset + sizes): right file size per screen density
-->
<picture>
  <!-- Mobile: portrait crop (8:10) -->
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.avif 400w, /hero-mobile-800.avif 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/avif"
  />
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.webp 400w, /hero-mobile-800.webp 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/webp"
  />
  <!-- Desktop: landscape crop (2:1) -->
  <source
    srcset="/hero-800.avif 800w, /hero-1200.avif 1200w, /hero-1600.avif 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/avif"
  />
  <source
    srcset="/hero-800.webp 800w, /hero-1200.webp 1200w, /hero-1600.webp 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/webp"
  />
  <img
    src="/hero-desktop.jpg"
    width="1200"
    height="600"
    fetchpriority="high"
    alt="Hero image description"
  />
</picture>

<!-- GOOD: Below-the-fold image — lazy loaded + async decoding -->
<img
  src="/content.webp"
  width="800"
  height="400"
  loading="lazy"
  decoding="async"
  alt="Content image description"
/>
```

#### 不必要的重新渲染（React）

```tsx
// BAD: Creates new object on every render, causing children to re-render
function TaskList() {
  return <TaskFilters options={{ sortBy: 'date', order: 'desc' }} />;
}

// GOOD: Stable reference
const DEFAULT_OPTIONS = { sortBy: 'date', order: 'desc' } as const;
function TaskList() {
  return <TaskFilters options={DEFAULT_OPTIONS} />;
}

// Use React.memo for expensive components
const TaskItem = React.memo(function TaskItem({ task }: Props) {
  return <div>{/* expensive render */}</div>;
});

// Use useMemo for expensive computations
function TaskStats({ tasks }: Props) {
  const stats = useMemo(() => calculateStats(tasks), [tasks]);
  return <div>{stats.completed} / {stats.total}</div>;
}
```

#### Bundle 過大

```typescript
// Modern bundlers (Vite, webpack 5+) handle named imports with tree-shaking automatically,
// provided the dependency ships ESM and is marked `sideEffects: false` in package.json.
// Profile before changing import styles — the real gains come from splitting and lazy loading.

// GOOD: Dynamic import for heavy, rarely-used features
const ChartLibrary = lazy(() => import('./ChartLibrary'));

// GOOD: Route-level code splitting wrapped in Suspense
const SettingsPage = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <SettingsPage />
    </Suspense>
  );
}
```

#### 缺少快取（後端）

```typescript
// Cache frequently-read, rarely-changed data
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
let cachedConfig: AppConfig | null = null;
let cacheExpiry = 0;

async function getAppConfig(): Promise<AppConfig> {
  if (cachedConfig && Date.now() < cacheExpiry) {
    return cachedConfig;
  }
  cachedConfig = await db.config.findFirst();
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedConfig;
}

// HTTP caching headers for static assets
app.use('/static', express.static('public', {
  maxAge: '1y',           // Cache for 1 year
  immutable: true,        // Never revalidate (use content hashing in filenames)
}));

// Cache-Control for API responses
res.set('Cache-Control', 'public, max-age=300'); // 5 minutes
```

## 效能預算

設定預算並強制執行：

```
JavaScript bundle: < 200KB gzipped (initial load)
CSS: < 50KB gzipped
Images: < 200KB per image (above the fold)
Fonts: < 100KB total
API response time: < 200ms (p95)
Time to Interactive: < 3.5s on 4G
Lighthouse Performance score: ≥ 90
```

**在 CI 中強制執行：**
```bash
# Bundle size check
npx bundlesize --config bundlesize.config.json

# Lighthouse CI
npx lhci autorun
```

## 延伸閱讀

詳細的效能檢核清單、最佳化指令與反模式參考，見 `references/performance-checklist.md`。


## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「我們之後再最佳化」 | 效能債會疊加。現在就修掉明顯的反模式，微幅最佳化可以延後。 |
| 「在我電腦上很快」 | 你的電腦不是使用者的電腦。在具代表性的硬體與網路條件下做效能剖析。 |
| 「這項最佳化很明顯」 | 你沒量過，就不算知道。先做效能剖析。 |
| 「使用者不會注意到 100ms」 | 研究顯示 100ms 的延遲會影響轉換率。使用者注意到的比你以為的多。 |
| 「框架會處理效能」 | 框架能預防一些問題，但修不了 N+1 查詢或過大的 bundle。 |

## 警訊

- 沒有效能剖析資料就做最佳化
- 資料抓取中有 N+1 查詢
- 清單型端點沒有分頁
- 圖片沒有指定尺寸、沒有延遲載入，或沒有響應式尺寸
- bundle 大小不斷成長卻沒人檢視
- 正式環境沒有效能監控
- 到處都是 `React.memo` 與 `useMemo`（用太多跟用太少一樣糟）

## 驗證

任何與效能相關的變更之後：

- [ ] 有前後的量測結果（具體數字）
- [ ] 具體的瓶頸已找出並處理
- [ ] Core Web Vitals 落在「Good」門檻內
- [ ] bundle 大小沒有明顯增加
- [ ] 新的資料抓取程式碼中沒有 N+1 查詢
- [ ] CI 中的效能預算通過（若有設定）
- [ ] 既有測試仍然通過（最佳化沒有弄壞行為）
