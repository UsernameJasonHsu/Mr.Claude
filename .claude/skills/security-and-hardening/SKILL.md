---
name: security-and-hardening
description: 強化程式碼以防範漏洞。適用於處理使用者輸入、身分驗證、資料儲存或外部整合時。適用於建置任何接受不受信任資料、管理使用者 session，或與第三方服務互動的功能時。
---

# 安全性與強化

## 概述

網頁應用程式的安全優先開發實務。把每一項外部輸入都當成有敵意的、把每一項機密都當成神聖的、把每一次授權檢查都當成必要的。安全不是一個階段 —— 它是對每一行碰到使用者資料、身分驗證或外部系統的程式碼所施加的限制。

## 適用時機

- 建置任何會接受使用者輸入的東西
- 實作身分驗證或授權
- 儲存或傳輸敏感資料
- 與外部 API 或服務整合
- 加入檔案上傳、webhook 或回呼
- 處理付款或個資

## 流程：先做威脅建模

沒有威脅模型就硬加上去的防護措施，只是猜測。強化之前，先花五分鐘用攻擊者的角度思考：

1. **畫出信任邊界。** 不可信資料從哪裡進入你的系統？HTTP 請求、表單欄位、檔案上傳、webhook、第三方 API、訊息佇列，以及 **LLM 輸出**。每一個邊界都是攻擊面。
2. **點名資產。** 什麼東西值得偷或值得破壞？憑證、個資、付款資料、管理操作、金流。
3. **對每個邊界跑一遍 STRIDE** —— 這是一個快速的檢視視角，不是繁複的儀式：

| 威脅 | 要問什麼 | 典型的緩解措施 |
|---|---|---|
| **S**poofing（偽冒） | 有人能偽裝成某個使用者／服務嗎？ | 身分驗證、簽章驗證 |
| **T**ampering（篡改） | 資料在傳輸中或靜態儲存時能被改動嗎？ | 完整性檢查、參數化查詢、HTTPS |
| **R**epudiation（否認） | 某個操作事後能被否認嗎？ | 安全事件的稽核日誌 |
| **I**nformation disclosure（資訊洩漏） | 資料會外洩嗎？ | 加密、欄位允許清單、籠統的錯誤訊息 |
| **D**enial of service（阻斷服務） | 它會被打爆嗎？ | 流量限制、輸入大小上限、逾時 |
| **E**levation of privilege（權限提升） | 使用者能取得他不該有的權限嗎？ | 授權檢查、最小權限 |

4. **在使用情境旁邊寫下濫用情境。** 對每個功能問：「我會怎麼濫用這個？」—— 然後把它變成你的第一個測試。

如果你說不出某個功能的信任邊界，就代表你還沒準備好保護它。這正是 OWASP **A04：不安全的設計** —— 大多數資安事件始於設計，而不是程式碼。

## 三級界線制度

### 一定要做（沒有例外）

- **在系統邊界驗證所有外部輸入**（API 路由、表單處理函式）
- **所有資料庫查詢都參數化** —— 絕不把使用者輸入串接進 SQL
- **對輸出做編碼**以防止 XSS（使用框架的自動轉義，不要繞過它）
- **所有對外通訊都用 HTTPS**
- **用 bcrypt／scrypt／argon2 雜湊密碼**（絕不以明文儲存）
- **設定安全性標頭**（CSP、HSTS、X-Frame-Options、X-Content-Type-Options）
- **session 使用 httpOnly、secure、sameSite cookie**
- **每次發布前執行 `npm audit`**（或同等工具）

### 先問過（需要人類核准）

- 新增身分驗證流程，或改動驗證邏輯
- 儲存新類別的敏感資料（個資、付款資訊）
- 新增外部服務整合
- 變更 CORS 設定
- 新增檔案上傳處理函式
- 修改流量限制或節流設定
- 授予提升的權限或角色

### 絕對不做

- **絕不把機密 commit** 進版控（API 金鑰、密碼、token）
- **絕不記錄敏感資料**（密碼、token、完整信用卡號）
- **絕不把用戶端驗證當成安全邊界**
- **絕不為了方便而停用安全性標頭**
- **絕不對使用者提供的資料使用 `eval()` 或 `innerHTML`**
- **絕不把 session 存在用戶端可存取的儲存空間**（例如把驗證 token 放進 localStorage）
- **絕不把堆疊追蹤或內部錯誤細節暴露給使用者**

## OWASP Top 10 的防範模式

以下是防範模式，不是排名。2021 年的排序請見 `references/security-checklist.md` 的快速對照表。

### 注入攻擊（SQL、NoSQL、作業系統指令）

```typescript
// BAD: SQL injection via string concatenation
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// GOOD: Parameterized query
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// GOOD: ORM with parameterized input
const user = await prisma.user.findUnique({ where: { id: userId } });
```

### 身分驗證缺陷

```typescript
// Password hashing
import { hash, compare } from 'bcrypt';

const SALT_ROUNDS = 12;
const hashedPassword = await hash(plaintext, SALT_ROUNDS);
const isValid = await compare(plaintext, hashedPassword);

// Session management
app.use(session({
  secret: process.env.SESSION_SECRET,  // From environment, not code
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,     // Not accessible via JavaScript
    secure: true,       // HTTPS only
    sameSite: 'lax',    // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,  // 24 hours
  },
}));
```

### 跨站腳本攻擊（XSS）

```typescript
// BAD: Rendering user input as HTML
element.innerHTML = userInput;

// GOOD: Use framework auto-escaping (React does this by default)
return <div>{userInput}</div>;

// If you MUST render HTML, sanitize first
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### 存取控制缺陷

```typescript
// Always check authorization, not just authentication
app.patch('/api/tasks/:id', authenticate, async (req, res) => {
  const task = await taskService.findById(req.params.id);

  // Check that the authenticated user owns this resource
  if (task.ownerId !== req.user.id) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Not authorized to modify this task' }
    });
  }

  // Proceed with update
  const updated = await taskService.update(req.params.id, req.body);
  return res.json(updated);
});
```

### 安全設定錯誤

```typescript
// Security headers (use helmet for Express)
import helmet from 'helmet';
app.use(helmet());

// Content Security Policy
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],  // Tighten if possible
    imgSrc: ["'self'", 'data:', 'https:'],
    connectSrc: ["'self'"],
  },
}));

// CORS — restrict to known origins
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
}));
```

### 敏感資料曝光

```typescript
// Never return sensitive fields in API responses
function sanitizeUser(user: UserRecord): PublicUser {
  const { passwordHash, resetToken, ...publicFields } = user;
  return publicFields;
}

// Use environment variables for secrets
const API_KEY = process.env.STRIPE_API_KEY;
if (!API_KEY) throw new Error('STRIPE_API_KEY not configured');
```

### 伺服器端請求偽造（SSRF）

任何時候伺服器去抓取一個受使用者影響的網址 —— webhook、「從網址匯入」、圖片代理、連結預覽 —— 攻擊者就能把它導向內部服務（雲端 metadata、`localhost`、私有 IP）。

```typescript
// BAD: fetch whatever the user gives you
await fetch(req.body.webhookUrl);

// GOOD: allowlist scheme + host, reject if ANY resolved IP is private, forbid redirects
import { lookup } from 'node:dns/promises';
import ipaddr from 'ipaddr.js';

const ALLOWED_HOSTS = new Set(['hooks.example.com']);

async function assertSafeUrl(raw: string): Promise<URL> {
  const url = new URL(raw);
  if (url.protocol !== 'https:') throw new Error('https only');
  if (!ALLOWED_HOSTS.has(url.hostname)) throw new Error('host not allowed');
  // Resolve ALL records; a single private/reserved address fails the check.
  const addrs = await lookup(url.hostname, { all: true });
  if (addrs.some((a) => ipaddr.parse(a.address).range() !== 'unicast')) {
    throw new Error('private/reserved IP');
  }
  return url;
}

await fetch(await assertSafeUrl(req.body.webhookUrl), { redirect: 'error' });
```

`range() !== 'unicast'` 這個檢查涵蓋了 IPv4 與 IPv6 的 loopback、link-local `169.254.169.254`（雲端 metadata，SSRF 的頭號目標）、私有位址與 unique-local 範圍。

**注意 —— 這仍然有 TOCTOU 的空隙。** `fetch` 在檢查之後會再解析一次 DNS，所以攻擊者用短 TTL 的記錄，就能在驗證與連線之間把位址改綁到內部 IP。對高風險介面，請解析一次並連到那個釘住的 IP，或在前面放一個過濾代理（`request-filtering-agent` / `ssrf-req-filter`）。

## 輸入驗證模式

### 在邊界做 schema 驗證

```typescript
import { z } from 'zod';

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().max(2000).optional(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.string().datetime().optional(),
});

// Validate at the route handler
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: result.error.flatten(),
      },
    });
  }
  // result.data is now typed and validated
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

### 檔案上傳的安全性

```typescript
// Restrict file types and sizes
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

function validateUpload(file: UploadedFile) {
  if (!ALLOWED_TYPES.includes(file.mimetype)) {
    throw new ValidationError('File type not allowed');
  }
  if (file.size > MAX_SIZE) {
    throw new ValidationError('File too large (max 5MB)');
  }
  // Don't trust the file extension — check magic bytes if critical
}
```

## 分診 npm audit 的結果

不是每一項稽核發現都需要立刻處理。用這個決策樹：

```
npm audit reports a vulnerability
├── Severity: critical or high
│   ├── Is the vulnerable code reachable in your app?
│   │   ├── YES --> Fix immediately (update, patch, or replace the dependency)
│   │   └── NO (dev-only dep, unused code path) --> Fix soon, but not a blocker
│   └── Is a fix available?
│       ├── YES --> Update to the patched version
│       └── NO --> Check for workarounds, consider replacing the dependency, or add to allowlist with a review date
├── Severity: moderate
│   ├── Reachable in production? --> Fix in the next release cycle
│   └── Dev-only? --> Fix when convenient, track in backlog
└── Severity: low
    └── Track and fix during regular dependency updates
```

**關鍵問題：**
- 那個有漏洞的函式在你的程式碼路徑中真的會被呼叫嗎？
- 這個相依套件是執行期相依，還是只在開發時用？
- 以你的部署情境而言，這個漏洞真的可被利用嗎（例如純用戶端 App 中的伺服器端漏洞）？

當你決定延後修正時，記下理由並設一個回顧日期。

### 供應鏈衛生

`npm audit` 抓的是已知 CVE；它抓不到惡意套件或名稱搶註的套件。此外還要：

- **把 lockfile 納入版控**，並在 CI 中用 `npm ci`（而不是 `npm install`）安裝 —— 可重現的建置，沒有無聲的版本漂移。
- **加入新相依套件之前先審視它** —— 維護狀況、下載量，以及它是否真的值得存在。每個相依套件都是攻擊面（OWASP **A06：有漏洞的元件**、**LLM03：供應鏈**）。
- **對不熟悉套件中的 `postinstall` 腳本要提高警覺** —— 它們會在安裝時執行任意程式碼。
- **留意名稱搶註** —— `cross-env` vs `crossenv`、`react-dom` vs `reactdom`。

## 流量限制

```typescript
import rateLimit from 'express-rate-limit';

// General API rate limit
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,                   // 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
}));

// Stricter limit for auth endpoints
app.use('/api/auth/', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,  // 10 attempts per 15 minutes
}));
```

## 機密管理

```
.env files:
  ├── .env.example  → Committed (template with placeholder values)
  ├── .env          → NOT committed (contains real secrets)
  └── .env.local    → NOT committed (local overrides)

.gitignore must include:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

**commit 前一律先檢查：**
```bash
# Check for accidentally staged secrets
git diff --cached | grep -i "password\|secret\|api_key\|token"
```

**只要有機密被 commit 過，就要換掉它。** 刪掉那一行或改寫歷史都不夠 —— 它一旦傳到遠端，就要假設它已經洩漏。先撤銷並重新簽發金鑰，再把它從歷史中清除。

## 保護 AI／LLM 功能

若你的 App 會呼叫 LLM —— 聊天機器人、摘要器、agent、RAG —— 它就繼承了一整套新的攻擊面。請對照 [OWASP Top 10 for LLM Applications（2025）](https://genai.owasp.org/llm-top-10/)：

- **把所有模型輸出都當成不可信輸入（LLM05：不當的輸出處理）。** 絕不把 LLM 輸出直接送進 `eval`、SQL、shell、`innerHTML` 或檔案路徑。要像對待原始使用者輸入一樣去驗證與編碼它。
- **假設提示可以被劫持（LLM01：提示注入）。** 情境視窗中的不可信文字 —— 使用者訊息、抓來的網頁、一份 PDF —— 都可能帶著指令。系統提示不是安全邊界；權限要用程式碼強制執行，而不是寫在提示裡。
- **把機密與其他使用者的資料排除在提示之外（LLM02／LLM07）。** 情境中的任何東西都可能被回吐出來。不要把 API 金鑰、跨租戶資料，或完整的系統提示放在模型能複述的地方。
- **限制工具與 agent 的權限（LLM06：過度授權）。** 把工具的範圍縮到最小、對破壞性或不可逆的操作要求確認，並驗證每一個工具參數。
- **設定消耗上限（LLM10：無上限消耗）。** 對 token、請求速率與迴圈／遞迴深度設上限，讓精心構造的輸入無法把成本衝高或把系統掛住。
- **隔離檢索資料（LLM08：向量與嵌入的弱點）。** 在 RAG 中，把向量資料庫當成一道信任邊界：依租戶分割嵌入，讓一個使用者無法檢索到另一個人的資料；並在索引前驗證文件，讓被下毒的內容無法操縱答案。

```typescript
// BAD: trusting model output as a command or as markup
const sql = await llm.generate(`Write SQL for: ${userQuestion}`);
await db.query(sql);                                   // arbitrary query execution
container.innerHTML = await llm.reply(userMessage);   // stored XSS, via the model

// GOOD: model output is data — parse defensively, then validate, then encode
let intent;
try {
  intent = CommandSchema.parse(JSON.parse(await llm.replyJson(userMessage)));
} catch {
  throw new ValidationError('unexpected model output'); // JSON.parse or schema failed
}
await runAllowlistedAction(intent.action, intent.params);
container.textContent = await llm.reply(userMessage);
```

## 安全審查檢核清單

```markdown
### Authentication
- [ ] Passwords hashed with bcrypt/scrypt/argon2 (salt rounds ≥ 12)
- [ ] Session tokens are httpOnly, secure, sameSite
- [ ] Login has rate limiting
- [ ] Password reset tokens expire

### Authorization
- [ ] Every endpoint checks user permissions
- [ ] Users can only access their own resources
- [ ] Admin actions require admin role verification

### Input
- [ ] All user input validated at the boundary
- [ ] SQL queries are parameterized
- [ ] HTML output is encoded/escaped
- [ ] Server-side URL fetches are allowlisted (no SSRF to internal services)

### Data
- [ ] No secrets in code or version control
- [ ] Sensitive fields excluded from API responses
- [ ] PII encrypted at rest (if applicable)

### Infrastructure
- [ ] Security headers configured (CSP, HSTS, etc.)
- [ ] CORS restricted to known origins
- [ ] Dependencies audited for vulnerabilities
- [ ] Error messages don't expose internals

### Supply Chain
- [ ] Lockfile committed; CI installs with `npm ci`
- [ ] New dependencies reviewed (maintenance, downloads, postinstall scripts)

### AI / LLM (if used)
- [ ] Model output treated as untrusted (no eval/SQL/innerHTML/shell)
- [ ] Secrets and other users' data kept out of prompts
- [ ] Tool/agent permissions scoped; destructive actions require confirmation
```
## 延伸閱讀

詳細的安全檢核清單與 commit 前的驗證步驟，見 `references/security-checklist.md`。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「這是內部工具，安全不重要」 | 內部工具也會被入侵。攻擊者專挑最弱的那一環。 |
| 「我們之後再加安全機制」 | 事後補安全，難度是一開始就做進去的 10 倍。現在就加。 |
| 「不會有人想利用這個」 | 自動掃描器會找到它。靠隱蔽求安全，不叫安全。 |
| 「框架會處理安全性」 | 框架提供的是工具，不是保證。你還是得正確使用它們。 |
| 「這只是原型」 | 原型會變成正式環境。安全習慣從第一天養成。 |
| 「這裡做威脅建模太超過了」 | 花五分鐘想「我會怎麼攻擊這個」，能防掉那些日後任何防護措施都補不起來的設計缺陷。 |
| 「那只是 LLM 輸出，只是文字而已」 | 那段「文字」可能是一句 SQL、一個 script 標籤，或一條 shell 指令。要像對待任何不可信輸入一樣處理它。 |

## 警訊

- 使用者輸入直接被送進資料庫查詢、shell 指令或 HTML 渲染
- 機密出現在原始碼或 commit 歷史中
- API 端點沒有身分驗證或授權檢查
- 缺少 CORS 設定，或使用萬用字元（`*`）來源
- 身分驗證端點沒有流量限制
- 堆疊追蹤或內部錯誤被暴露給使用者
- 相依套件有已知的嚴重漏洞
- 伺服器抓取使用者提供的網址卻沒有允許清單（SSRF）
- LLM／模型輸出被送進查詢、DOM、shell 或 `eval`
- 機密、個資或完整的系統提示被放進 LLM 的情境視窗

## 驗證

實作與安全相關的程式碼之後：

- [ ] `npm audit` 沒有嚴重或高風險漏洞
- [ ] 原始碼與 git 歷史中沒有機密
- [ ] 所有使用者輸入都在系統邊界驗證過
- [ ] 每個受保護的端點都檢查了身分驗證與授權
- [ ] 回應中有安全性標頭（用瀏覽器 DevTools 確認）
- [ ] 錯誤回應不會暴露內部細節
- [ ] 身分驗證端點的流量限制已生效
- [ ] 伺服器端的網址抓取都對照允許清單驗證過（無 SSRF）
- [ ] LLM／模型輸出在使用前已驗證並編碼（若有 AI 功能）
