---
name: shipping-and-launch
description: 準備正式環境上線發布。適用於準備部署至正式環境時。適用於需要上線前檢核清單、設定監控、規劃分階段推出（staged rollout），或需要回滾（rollback）策略時。
---

# 交付與上線

## 概述

有把握地交付。目標不只是「部署出去」—— 而是安全地部署：監控就位、回滾計畫備妥，並且清楚知道成功長什麼樣。每一次上線都應該是可逆、可觀測、漸進的。

## 適用時機

- 第一次把某個功能部署到正式環境
- 對使用者發布重大變更
- 遷移資料或基礎設施
- 開放 beta 或搶先體驗計畫
- 任何帶有風險的部署（也就是全部）

## 上線前檢核清單

### 程式碼品質

- [ ] 所有測試通過（單元、整合、e2e）
- [ ] 建置成功且沒有警告
- [ ] Lint 與型別檢查通過
- [ ] 程式碼已審查並核准
- [ ] 沒有應該在上線前解決掉的 TODO 註解
- [ ] 正式環境程式碼中沒有除錯用的 `console.log`
- [ ] 錯誤處理涵蓋了預期中的失敗模式

### 安全性

- [ ] 程式碼或版控中沒有機密資料
- [ ] `npm audit` 沒有嚴重或高風險漏洞
- [ ] 所有面向使用者的端點都有輸入驗證
- [ ] 身分驗證與授權檢查已就位
- [ ] 安全性標頭已設定（CSP、HSTS 等）
- [ ] 身分驗證端點有流量限制
- [ ] CORS 限制在特定來源（不是萬用字元）

### 效能

- [ ] Core Web Vitals 落在「Good」門檻內
- [ ] 關鍵路徑上沒有 N+1 查詢
- [ ] 圖片已最佳化（壓縮、響應式尺寸、延遲載入）
- [ ] Bundle 大小在預算內
- [ ] 資料庫查詢有適當的索引
- [ ] 靜態資源與重複查詢已設定快取

### 無障礙性

- [ ] 所有可互動元素都能用鍵盤操作
- [ ] 螢幕閱讀器能傳達頁面內容與結構
- [ ] 色彩對比符合 WCAG 2.1 AA（文字 4.5:1）
- [ ] 對話框與動態內容的焦點管理正確
- [ ] 錯誤訊息具描述性，且與表單欄位有關聯
- [ ] axe-core 或 Lighthouse 沒有無障礙性警告

### 基礎設施

- [ ] 正式環境的環境變數已設定
- [ ] 資料庫遷移已套用（或已準備好套用）
- [ ] DNS 與 SSL 已設定
- [ ] 靜態資源的 CDN 已設定
- [ ] 日誌與錯誤回報已設定
- [ ] 健康檢查端點存在且會回應

### 文件

- [ ] README 已更新，包含任何新的設定需求
- [ ] API 文件是最新的
- [ ] 所有架構決策都已寫成 ADR
- [ ] 變更紀錄已更新
- [ ] 面向使用者的文件已更新（若適用）

## 功能旗標策略

把功能藏在旗標後面交付，讓「部署」與「發布」脫鉤：

```typescript
// Feature flag check
const flags = await getFeatureFlags(userId);

if (flags.taskSharing) {
  // New feature: task sharing
  return <TaskSharingPanel task={task} />;
}

// Default: existing behavior
return null;
```

**功能旗標的生命週期：**

```
1. DEPLOY with flag OFF     → Code is in production but inactive
2. ENABLE for team/beta     → Internal testing in production environment
3. GRADUAL ROLLOUT          → 5% → 25% → 50% → 100% of users
4. MONITOR at each stage    → Watch error rates, performance, user feedback
5. CLEAN UP                 → Remove flag and dead code path after full rollout
```

**規則：**
- 每個功能旗標都要有負責人與到期日
- 全面推出後 2 週內清掉旗標
- 不要巢狀使用功能旗標（會產生指數級的組合）
- 在 CI 中要測試旗標的兩種狀態（開與關）

## 分階段推出

### 推出順序

```
1. DEPLOY to staging
   └── Full test suite in staging environment
   └── Manual smoke test of critical flows

2. DEPLOY to production (feature flag OFF)
   └── Verify deployment succeeded (health check)
   └── Check error monitoring (no new errors)

3. ENABLE for team (flag ON for internal users)
   └── Team uses the feature in production
   └── 24-hour monitoring window

4. CANARY rollout (flag ON for 5% of users)
   └── Monitor error rates, latency, user behavior
   └── Compare metrics: canary vs. baseline
   └── 24-48 hour monitoring window
   └── Advance only if all thresholds pass (see table below)

5. GRADUAL increase (25% -> 50% -> 100%)
   └── Same monitoring at each step
   └── Ability to roll back to previous percentage at any point

6. FULL rollout (flag ON for all users)
   └── Monitor for 1 week
   └── Clean up feature flag
```

### 推出的決策門檻

用這些門檻決定每個階段要推進、暫停，還是回滾：

| 指標 | 推進（綠燈） | 暫停調查（黃燈） | 回滾（紅燈） |
|------|-------------|-----------------|-------------|
| 錯誤率 | 在基準線 10% 以內 | 高於基準線 10-100% | 超過基準線 2 倍 |
| P95 延遲 | 在基準線 20% 以內 | 高於基準線 20-50% | 高於基準線 50% 以上 |
| 用戶端 JS 錯誤 | 沒有新的錯誤類型 | 新錯誤出現在 <0.1% 的 session | 新錯誤出現在 >0.1% 的 session |
| 業務指標 | 持平或正向 | 下降 <5%（可能是雜訊） | 下降 >5% |

### 什麼時候該回滾

出現以下情況立刻回滾：
- 錯誤率超過基準線 2 倍以上
- P95 延遲增加超過 50%
- 使用者回報的問題暴增
- 偵測到資料完整性問題
- 發現安全漏洞

## 監控與可觀測性

### 該監控什麼

```
Application metrics:
├── Error rate (total and by endpoint)
├── Response time (p50, p95, p99)
├── Request volume
├── Active users
└── Key business metrics (conversion, engagement)

Infrastructure metrics:
├── CPU and memory utilization
├── Database connection pool usage
├── Disk space
├── Network latency
└── Queue depth (if applicable)

Client metrics:
├── Core Web Vitals (LCP, INP, CLS)
├── JavaScript errors
├── API error rates from client perspective
└── Page load time
```

### 錯誤回報

```typescript
// Set up error boundary with reporting
class ErrorBoundary extends React.Component {
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    // Report to error tracking service
    reportError(error, {
      componentStack: info.componentStack,
      userId: getCurrentUser()?.id,
      page: window.location.pathname,
    });
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback onRetry={() => this.setState({ hasError: false })} />;
    }
    return this.props.children;
  }
}

// Server-side error reporting
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  reportError(err, {
    method: req.method,
    url: req.url,
    userId: req.user?.id,
  });

  // Don't expose internals to users
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' },
  });
});
```

### 上線後驗證

上線後的第一個小時內：

```
1. Check health endpoint returns 200
2. Check error monitoring dashboard (no new error types)
3. Check latency dashboard (no regression)
4. Test the critical user flow manually
5. Verify logs are flowing and readable
6. Confirm rollback mechanism works (dry run if possible)
```

## 回滾策略

每次部署在發生之前，都要有回滾計畫：

```markdown
## Rollback Plan for [Feature/Release]

### Trigger Conditions
- Error rate > 2x baseline
- P95 latency > [X]ms
- User reports of [specific issue]

### Rollback Steps
1. Disable feature flag (if applicable)
   OR
1. Deploy previous version: `git revert <commit> && git push`
2. Verify rollback: health check, error monitoring
3. Communicate: notify team of rollback

### Database Considerations
- Migration [X] has a rollback: `npx prisma migrate rollback`
- Data inserted by new feature: [preserved / cleaned up]

### Time to Rollback
- Feature flag: < 1 minute
- Redeploy previous version: < 5 minutes
- Database rollback: < 15 minutes
```
## 延伸閱讀

- 每項變更在跑這份檢核清單之前都必須先跨過的專案層級「完成的定義」，見 `references/definition-of-done.md`
- 上線前的安全性檢查，見 `references/security-checklist.md`
- 上線前的效能檢核清單，見 `references/performance-checklist.md`
- 上線前的無障礙性驗證，見 `references/accessibility-checklist.md`

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「測試環境可以，正式環境就會可以」 | 正式環境有不同的資料、流量型態與邊界情境。部署後要監控。 |
| 「這個不需要功能旗標」 | 每個功能都受益於一個緊急關閉開關。就算是「簡單的」變更也可能弄壞東西。 |
| 「監控是額外開銷」 | 沒有監控，代表你是從使用者抱怨、而不是從儀表板得知問題。 |
| 「監控之後再加」 | 上線前就要加。看不見的東西，你無法除錯。 |
| 「回滾就是承認失敗」 | 回滾是負責任的工程作為。把壞掉的功能推上線才是失敗。 |

## 警訊

- 沒有回滾計畫就部署
- 正式環境沒有監控或錯誤回報
- 大爆炸式發布（全部一次上，沒有分階段）
- 功能旗標沒有到期日也沒有負責人
- 上線後第一個小時沒有人在盯
- 正式環境的設定是憑記憶做的，而不是寫成程式碼
- 「週五下午了，就上吧」

## 驗證

部署之前：

- [ ] 上線前檢核清單已完成（所有區塊都綠燈）
- [ ] 功能旗標已設定（若適用）
- [ ] 回滾計畫已寫成文件
- [ ] 監控儀表板已建好
- [ ] 已通知團隊本次部署

部署之後：

- [ ] 健康檢查回傳 200
- [ ] 錯誤率正常
- [ ] 延遲正常
- [ ] 關鍵使用者流程可運作
- [ ] 日誌有在流動
- [ ] 回滾機制已測試或確認就緒
