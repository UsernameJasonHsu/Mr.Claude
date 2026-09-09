---
name: ci-cd-and-automation
description: 自動化 CI/CD 管線設定。適用於建立或修改建置與部署管線。適用於需要自動化品質關卡、在 CI 中設定測試執行器，或建立部署策略時。
---

# CI/CD 與自動化

## 概述

把品質關卡自動化，讓任何變更都必須通過測試、lint、型別檢查與建置才能進入正式環境。CI/CD 是所有其他技能的強制執行機制 —— 它會抓到人類與 agent 漏掉的東西，而且對每一項變更都一致地執行。

**左移（Shift Left）：** 盡可能在管線的越早階段抓到問題。在 lint 階段抓到的 bug 只花幾分鐘；同一個 bug 在正式環境抓到要花好幾小時。把檢查往上游移 —— 靜態分析在測試之前、測試在測試環境之前、測試環境在正式環境之前。

**更快就是更安全：** 更小的批次與更頻繁的發布會降低風險，而不是提高風險。含 3 項變更的部署，比含 30 項的容易除錯。頻繁發布也會建立起大家對發布流程本身的信心。

## 適用時機

- 為新專案建立 CI 管線
- 新增或修改自動化檢查
- 設定部署管線
- 當某項變更應該觸發自動驗證時
- 除錯 CI 失敗

## 品質關卡管線

每項變更在合併前都要通過這些關卡：

```
Pull Request Opened
    │
    ▼
┌─────────────────┐
│   LINT CHECK     │  eslint, prettier
│   ↓ pass         │
│   TYPE CHECK     │  tsc --noEmit
│   ↓ pass         │
│   UNIT TESTS     │  jest/vitest
│   ↓ pass         │
│   BUILD          │  npm run build
│   ↓ pass         │
│   INTEGRATION    │  API/DB tests
│   ↓ pass         │
│   E2E (optional) │  Playwright/Cypress
│   ↓ pass         │
│   SECURITY AUDIT │  npm audit
│   ↓ pass         │
│   BUNDLE SIZE    │  bundlesize check
└─────────────────┘
    │
    ▼
  Ready for review
```

**任何關卡都不能跳過。** 若 lint 失敗，就修 lint —— 不要把規則關掉。若測試失敗，就修程式碼 —— 不要跳過測試。

## GitHub Actions 設定

### 基本 CI 管線

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npx tsc --noEmit

      - name: Test
        run: npm test -- --coverage

      - name: Build
        run: npm run build

      - name: Security audit
        run: npm audit --audit-level=high
```

### 加上資料庫整合測試

```yaml
  integration:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: ci_user
          POSTGRES_PASSWORD: ${{ secrets.CI_DB_PASSWORD }}
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: Run migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/testdb
      - name: Integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/testdb
```

> **注意：** 即使是只在 CI 用的測試資料庫，憑證也要用 GitHub Secrets，而不是把值寫死。這能養成好習慣，也能避免測試憑證在其他情境被誤用。

### E2E 測試

```yaml
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: Install Playwright
        run: npx playwright install --with-deps chromium
      - name: Build
        run: npm run build
      - name: Run E2E tests
        run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

## 把 CI 失敗回饋給 agent

CI 搭配 AI agent 的威力在於那個回饋迴圈。當 CI 失敗時：

```
CI fails
    │
    ▼
Copy the failure output
    │
    ▼
Feed it to the agent:
"The CI pipeline failed with this error:
[paste specific error]
Fix the issue and verify locally before pushing again."
    │
    ▼
Agent fixes → pushes → CI runs again
```

**關鍵模式：**

```
Lint failure → Agent runs `npm run lint --fix` and commits
Type error  → Agent reads the error location and fixes the type
Test failure → Agent follows debugging-and-error-recovery skill
Build error → Agent checks config and dependencies
```

## 部署策略

### 預覽部署

每個 PR 都有一個預覽部署，供手動測試：

```yaml
# Deploy preview on PR (Vercel/Netlify/etc.)
deploy-preview:
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
    - name: Deploy preview
      run: npx vercel --token=${{ secrets.VERCEL_TOKEN }}
```

### 功能旗標

功能旗標讓「部署」與「發布」脫鉤。把未完成或有風險的功能藏在旗標後面部署，你就能：

- **把程式碼推上去但不啟用它。** 及早合併進 main，準備好再啟用。
- **不重新部署就回滾。** 關掉旗標，而不是還原程式碼。
- **對新功能做金絲雀發布。** 先對 1% 使用者啟用，再 10%，再 100%。
- **跑 A/B 測試。** 比較有無該功能時的行為差異。

```typescript
// Simple feature flag pattern
if (featureFlags.isEnabled('new-checkout-flow', { userId })) {
  return renderNewCheckout();
}
return renderLegacyCheckout();
```

**旗標的生命週期：** 建立 → 開放測試 → 金絲雀 → 全面推出 → 移除旗標與死碼。永遠活著的旗標會變成技術債 —— 建立時就設好清理日期。

### 分階段推出

```
PR merged to main
    │
    ▼
  Staging deployment (auto)
    │ Manual verification
    ▼
  Production deployment (manual trigger or auto after staging)
    │
    ▼
  Monitor for errors (15-minute window)
    │
    ├── Errors detected → Rollback
    └── Clean → Done
```

### 回滾計畫

每次部署都應該是可逆的：

```yaml
# Manual rollback workflow
name: Rollback
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to rollback to'
        required: true

jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - name: Rollback deployment
        run: |
          # Deploy the specified previous version
          npx vercel rollback ${{ inputs.version }}
```

## 環境管理

```
.env.example       → Committed (template for developers)
.env                → NOT committed (local development)
.env.test           → Committed (test environment, no real secrets)
CI secrets          → Stored in GitHub Secrets / vault
Production secrets  → Stored in deployment platform / vault
```

CI 絕不該持有正式環境的機密。CI 測試要用另一組獨立的機密。

## CI 之外的自動化

### Dependabot／Renovate

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
```

### Build Cop 角色

指派一位負責讓 CI 保持綠燈的人。當建置壞掉時，Build Cop 的職責就是修好它或還原它 —— 而不是由造成壞掉的那個人負責。這能防止壞掉的建置不斷累積，同時大家都以為「應該有別人會去修」。

### PR 檢查

- **必要審查：** 合併前至少 1 個核准
- **必要狀態檢查：** CI 必須通過才能合併
- **分支保護：** 不允許對 main 做 force push
- **自動合併：** 若所有檢查通過且已核准，就自動合併

## CI 最佳化

當管線超過 10 分鐘時，依影響大小依序套用這些策略：

```
Slow CI pipeline?
├── Cache dependencies
│   └── Use actions/cache or setup-node cache option for node_modules
├── Run jobs in parallel
│   └── Split lint, typecheck, test, build into separate parallel jobs
├── Only run what changed
│   └── Use path filters to skip unrelated jobs (e.g., skip e2e for docs-only PRs)
├── Use matrix builds
│   └── Shard test suites across multiple runners
├── Optimize the test suite
│   └── Remove slow tests from the critical path, run them on a schedule instead
└── Use larger runners
    └── GitHub-hosted larger runners or self-hosted for CPU-heavy builds
```

**範例：快取與平行化**
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npx tsc --noEmit

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm test -- --coverage
```

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「CI 太慢了」 | 去最佳化管線（見下方「CI 最佳化」），不要跳過它。一條 5 分鐘的管線能省下好幾小時的除錯。 |
| 「這個變更很瑣碎，跳過 CI」 | 瑣碎的變更也會弄壞建置。而且瑣碎變更的 CI 本來就跑很快。 |
| 「這個測試不穩定，重跑就好」 | 不穩定的測試會掩蓋真正的 bug，還浪費大家時間。去修那個不穩定性。 |
| 「我們之後再加 CI」 | 沒有 CI 的專案會累積出一堆壞掉的狀態。第一天就把它設起來。 |
| 「手動測試就夠了」 | 手動測試無法規模化，也不可重複。能自動化的就自動化。 |

## 警訊

- 專案裡沒有 CI 管線
- CI 失敗被忽略或消音
- 為了讓管線過關而在 CI 中停用測試
- 沒有經過測試環境驗證就直接部署正式環境
- 沒有回滾機制
- 機密存在程式碼或 CI 設定檔中（而不是機密管理服務）
- CI 時間很長卻沒有任何最佳化的努力

## 驗證

設定或修改 CI 之後：

- [ ] 所有品質關卡都在（lint、型別、測試、建置、稽核）
- [ ] 管線在每個 PR 與每次推送到 main 時都會跑
- [ ] 失敗會阻擋合併（已設定分支保護）
- [ ] CI 結果會回饋進開發迴圈
- [ ] 機密存在機密管理服務中，不在程式碼裡
- [ ] 部署有回滾機制
- [ ] 測試套件的管線在 10 分鐘內跑完
