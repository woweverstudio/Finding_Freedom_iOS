# 포트폴리오 분석 기능 기획서

> 버전: 0.2  
> 최종 수정: 2024.12.20

---

## 📌 개요

### 기능 소개
사용자가 한국 및 미국 주식 종목을 검색하여 자신만의 포트폴리오를 구성하고, 각 종목의 비중을 설정한 뒤 **포트폴리오 전체의 성과 지표**를 분석하여 점수화하는 기능입니다.

### 핵심 가치
- 🎯 **교육적**: 투자자에게 포트폴리오 지표(CAGR, Sharpe Ratio 등)의 의미를 쉽게 설명
- 📊 **실용적**: 실제 과거 데이터 기반으로 객관적인 분석 제공
- 💡 **인사이트**: 포트폴리오의 강점과 개선점을 친절하게 안내
- 💰 **배당 친화적**: 배당투자자를 위한 배당률 및 Total Return 분석

### 위치
- 탭 순서: 홈 → 시뮬레이션 → **포트폴리오(NEW)** → 메뉴

---

## 1. 데이터 아키텍처 (수정됨)

### 1.1 핵심 원칙
1. **비용 최소화**: 사용자 로컬 캐싱으로 Supabase 요청 최소화
2. **단순한 서버**: Supabase에는 raw 데이터만 저장 (점수 계산 X)
3. **로컬 계산**: 모든 지표 계산은 사용자 디바이스에서 수행

### 1.2 새로운 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                     외부 데이터 소스                              │
│  (Yahoo Finance, KRX API, Alpha Vantage 등)                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ 주 1회 (Cron Job / Supabase Edge Function)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase Database                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ stocks 테이블 (Raw 데이터만)                              │    │
│  │ - ticker, name, exchange, currency                       │    │
│  │ - price_history (JSON 또는 별도 테이블)                   │    │
│  │ - dividend_history (배당 데이터)                          │    │
│  │ - updated_at                                             │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ 주 1회 다운로드 (앱 시작 시 체크)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     iOS 앱 (로컬)                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ SwiftData (로컬 캐시)                                     │    │
│  │ - 종목 raw 데이터 (1주일 캐싱)                             │    │
│  │ - 사용자 포트폴리오                                       │    │
│  │ - 계산된 지표 (로컬 계산)                                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 로컬 계산 엔진                                            │    │
│  │ - CAGR, Sharpe Ratio, MDD 등 계산                        │    │
│  │ - 배당 포함 Total Return 계산                             │    │
│  │ - 포트폴리오 점수화                                       │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 데이터 동기화 흐름

```swift
// 앱 시작 시 동기화 체크
func checkDataSync() async {
    let lastSyncDate = UserDefaults.lastDataSyncDate
    let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    
    if lastSyncDate < oneWeekAgo {
        // Supabase에서 최신 데이터 다운로드
        await downloadLatestStockData()
        UserDefaults.lastDataSyncDate = Date()
    }
}
```

### 1.4 Supabase 스키마

```sql
-- 종목 기본 정보
CREATE TABLE stocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticker VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    name_korean VARCHAR(100),
    exchange VARCHAR(20) NOT NULL,  -- NYSE, NASDAQ, KOSPI, KOSDAQ
    sector VARCHAR(50),
    currency VARCHAR(3) NOT NULL,   -- USD, KRW
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 가격 히스토리 (5년치)
CREATE TABLE price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id UUID REFERENCES stocks(id),
    date DATE NOT NULL,
    open DECIMAL(15, 4),
    high DECIMAL(15, 4),
    low DECIMAL(15, 4),
    close DECIMAL(15, 4),           -- 조정 종가
    volume BIGINT,
    UNIQUE(stock_id, date)
);

-- 배당 히스토리
CREATE TABLE dividend_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id UUID REFERENCES stocks(id),
    ex_date DATE NOT NULL,
    amount DECIMAL(15, 6) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    UNIQUE(stock_id, ex_date)
);

-- 데이터 업데이트 로그
CREATE TABLE data_sync_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sync_type VARCHAR(20) NOT NULL,  -- 'weekly', 'manual'
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    stocks_updated INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'running'
);
```

### 1.5 주간 데이터 수집 (Supabase Edge Function)

```typescript
// supabase/functions/weekly-data-sync/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  // 1. 모든 종목 목록 가져오기
  const { data: stocks } = await supabase
    .from('stocks')
    .select('id, ticker, exchange')
  
  // 2. 각 종목별 최신 데이터 수집
  for (const stock of stocks) {
    // Yahoo Finance / Alpha Vantage 등에서 데이터 수집
    const priceData = await fetchPriceData(stock.ticker)
    const dividendData = await fetchDividendData(stock.ticker)
    
    // 3. Supabase에 저장
    await supabase.from('price_history').upsert(priceData)
    await supabase.from('dividend_history').upsert(dividendData)
  }
  
  return new Response(JSON.stringify({ success: true }))
})

// Supabase Cron 설정: 매주 일요일 자정 실행
// crontab: "0 0 * * 0"
```

### 1.6 비용 예상

| 항목 | 월간 예상 비용 |
|------|---------------|
| Supabase Free Tier | $0 (500MB DB, 2GB 전송) |
| Supabase Pro (필요시) | $25/월 |
| 외부 API (Yahoo Finance) | $0 (무료 API 사용) |
| **합계** | **$0 ~ $25/월** |

---

## 2. 배당 데이터 및 Total Return

### 2.1 배당 관련 지표

| 지표 | 설명 | 계산 방법 |
|------|------|-----------|
| **배당률 (Dividend Yield)** | 현재 주가 대비 연간 배당금 비율 | `연간 배당금 합계 / 현재 주가` |
| **배당 성장률** | 배당금의 연평균 성장률 | `(최근배당/5년전배당)^(1/5) - 1` |
| **Payout Ratio** | 순이익 대비 배당금 비율 | 외부 API 제공시 표시 |

### 2.2 배당 포함 Total Return 계산

```swift
/// 배당을 포함한 총 수익률 계산
struct TotalReturnCalculator {
    
    /// Price Return (가격 변동만)
    static func calculatePriceReturn(
        startPrice: Double,
        endPrice: Double
    ) -> Double {
        return (endPrice - startPrice) / startPrice
    }
    
    /// Dividend Return (배당 수익률)
    static func calculateDividendReturn(
        dividends: [DividendData],
        averagePrice: Double
    ) -> Double {
        let totalDividends = dividends.reduce(0) { $0 + $1.amount }
        return totalDividends / averagePrice
    }
    
    /// Total Return (배당 재투자 가정)
    /// 중요: 배당금이 지급될 때마다 재투자했다고 가정하여 계산
    static func calculateTotalReturn(
        priceHistory: [PriceData],
        dividends: [DividendData]
    ) -> Double {
        var shares: Double = 1.0
        var totalValue: Double = priceHistory.first?.close ?? 0
        
        for i in 1..<priceHistory.count {
            let date = priceHistory[i].date
            let price = priceHistory[i].close
            
            // 해당 날짜에 배당이 있었다면 재투자
            if let dividend = dividends.first(where: { $0.exDate == date }) {
                let dividendAmount = shares * dividend.amount
                let newShares = dividendAmount / price
                shares += newShares
            }
            
            totalValue = shares * price
        }
        
        let startValue = priceHistory.first?.close ?? 1
        return (totalValue - startValue) / startValue
    }
    
    /// CAGR with Dividend Reinvestment
    static func calculateCAGRWithDividends(
        priceHistory: [PriceData],
        dividends: [DividendData],
        years: Double
    ) -> Double {
        let totalReturn = calculateTotalReturn(
            priceHistory: priceHistory,
            dividends: dividends
        )
        return pow(1 + totalReturn, 1 / years) - 1
    }
}
```

### 2.3 배당 정보 UI 표시

```swift
struct DividendInfoCard: View {
    let stock: StockInfo
    let dividendYield: Double
    let dividendGrowthRate: Double
    let exDividendDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 배당률 표시
            HStack {
                Text("💰 배당률")
                    .font(.headline)
                Spacer()
                Text("\(dividendYield * 100, specifier: "%.2f")%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(dividendYield > 0.03 ? .green : .primary)
            }
            
            // 배당 성장률
            if dividendGrowthRate > 0 {
                HStack {
                    Text("📈 배당 성장률 (5Y)")
                    Spacer()
                    Text("\(dividendGrowthRate * 100, specifier: "%.1f")%")
                }
            }
            
            // 다음 배당락일
            if let exDate = exDividendDate {
                HStack {
                    Text("📅 다음 배당락일")
                    Spacer()
                    Text(exDate, style: .date)
                }
            }
            
            // 배당 투자자를 위한 팁
            if dividendYield > 0.04 {
                Text("💡 고배당 종목이에요! 배당 재투자 효과가 클 수 있어요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

---

## 3. 지표 친절한 설명

### 3.1 CAGR 설명

```swift
struct CAGRExplanation: View {
    let cagr: Double
    let years: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 메인 설명
            Text("📊 CAGR이 뭔가요?")
                .font(.headline)
            
            Text("""
            CAGR(Compound Annual Growth Rate)은 \
            **연평균 복합 성장률**이에요.
            
            쉽게 말해, "\(years)년 동안 매년 평균 몇 %씩 성장했는지"를 \
            보여주는 숫자예요.
            """)
            .font(.body)
            
            // 비유 설명
            VStack(alignment: .leading, spacing: 8) {
                Text("🌳 나무로 비유하면...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("""
                씨앗(초기 투자금)이 \(years)년 후 나무(현재 가치)가 되었을 때, \
                매년 동일한 비율로 자랐다면 그 비율이 바로 CAGR이에요!
                """)
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            // 해석 가이드
            VStack(alignment: .leading, spacing: 8) {
                Text("📈 CAGR 해석 가이드")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("10% 이상: 매우 좋은 성과 (S&P500 장기 평균)")
                }
                HStack {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("5~10%: 양호한 성과")
                }
                HStack {
                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                    Text("0~5%: 예금 수준")
                }
                HStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("음수: 손실 발생")
                }
            }
            .font(.caption)
            
            // 현재 포트폴리오 평가
            Divider()
            
            HStack {
                Text("내 포트폴리오:")
                    .fontWeight(.medium)
                Text("\(cagr * 100, specifier: "%.1f")%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(cagrColor)
            }
            
            Text(cagrInterpretation)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    var cagrColor: Color {
        switch cagr {
        case 0.10...: return .green
        case 0.05..<0.10: return .blue
        case 0..<0.05: return .yellow
        default: return .red
        }
    }
    
    var cagrInterpretation: String {
        switch cagr {
        case 0.15...: return "🎉 훌륭해요! 시장 평균을 크게 상회하는 성과예요."
        case 0.10..<0.15: return "👍 좋아요! S&P500 장기 평균과 비슷한 성과예요."
        case 0.05..<0.10: return "😊 양호해요. 은행 예금보다는 좋은 성과예요."
        case 0..<0.05: return "🤔 예금 금리 수준이에요. 전략을 점검해보세요."
        default: return "😢 손실이 발생했어요. 포트폴리오 재검토를 권장해요."
        }
    }
}
```

### 3.2 Sharpe Ratio 설명

```swift
struct SharpeRatioExplanation: View {
    let sharpeRatio: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 메인 설명
            Text("⚖️ Sharpe Ratio가 뭔가요?")
                .font(.headline)
            
            Text("""
            Sharpe Ratio는 **위험 대비 수익률**을 측정해요.
            
            "같은 위험을 감수했을 때, 얼마나 효율적으로 \
            수익을 냈는지"를 보여주는 지표예요.
            """)
            .font(.body)
            
            // 비유 설명
            VStack(alignment: .leading, spacing: 8) {
                Text("🚗 자동차 연비로 비유하면...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("""
                연비가 좋은 차가 같은 기름으로 더 멀리 가듯이, \
                Sharpe Ratio가 높으면 같은 위험으로 더 많은 수익을 낸 거예요!
                
                • 연료 = 감수한 위험 (변동성)
                • 거리 = 얻은 수익
                • 연비 = Sharpe Ratio
                """)
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 공식 (간단히)
            VStack(alignment: .leading, spacing: 8) {
                Text("📐 계산 방법 (참고)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Sharpe Ratio = (포트폴리오 수익률 - 무위험 수익률) ÷ 변동성")
                    .font(.caption)
                    .fontFamily(.monospaced)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
                
                Text("무위험 수익률은 보통 국채 금리를 사용해요 (현재 약 3~4%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 해석 가이드
            VStack(alignment: .leading, spacing: 8) {
                Text("📊 Sharpe Ratio 해석 가이드")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("1.5 이상: 매우 우수 (헤지펀드 수준)")
                }
                HStack {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("1.0~1.5: 우수 (좋은 전략)")
                }
                HStack {
                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                    Text("0.5~1.0: 보통")
                }
                HStack {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                    Text("0~0.5: 미흡 (위험 대비 수익 낮음)")
                }
                HStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("음수: 무위험 자산보다 못함")
                }
            }
            .font(.caption)
            
            // 현재 포트폴리오 평가
            Divider()
            
            HStack {
                Text("내 포트폴리오:")
                    .fontWeight(.medium)
                Text("\(sharpeRatio, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sharpeColor)
            }
            
            Text(sharpeInterpretation)
                .font(.callout)
                .foregroundColor(.secondary)
            
            // 개선 팁
            if sharpeRatio < 1.0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 Sharpe Ratio 개선 팁")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("• 상관관계가 낮은 자산으로 분산투자")
                    Text("• 변동성이 낮은 종목 비중 늘리기")
                    Text("• 채권 등 안전자산 일부 편입 고려")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    var sharpeColor: Color {
        switch sharpeRatio {
        case 1.5...: return .green
        case 1.0..<1.5: return .blue
        case 0.5..<1.0: return .yellow
        case 0..<0.5: return .orange
        default: return .red
        }
    }
    
    var sharpeInterpretation: String {
        switch sharpeRatio {
        case 1.5...: return "🏆 뛰어나요! 위험 대비 매우 효율적인 수익을 내고 있어요."
        case 1.0..<1.5: return "👍 좋아요! 감수한 위험 대비 좋은 수익을 내고 있어요."
        case 0.5..<1.0: return "😊 보통이에요. 괜찮은 편이지만 개선 여지가 있어요."
        case 0..<0.5: return "🤔 위험 대비 수익이 낮아요. 전략 점검을 권장해요."
        default: return "😢 무위험 자산(예금)보다 못한 성과예요. 재검토가 필요해요."
        }
    }
}
```

### 3.3 추가 지표 설명 (확장 가능)

```swift
/// 지표 설명 팩토리
struct MetricExplanationFactory {
    
    static func explanation(for metric: PortfolioMetric) -> MetricExplanation {
        switch metric {
        case .cagr(let value):
            return MetricExplanation(
                title: "연평균 수익률 (CAGR)",
                emoji: "📈",
                simpleExplanation: "매년 평균 몇 %씩 성장했는지",
                analogy: "나무가 매년 같은 비율로 자라는 것처럼, 투자금이 매년 성장한 비율이에요.",
                value: value,
                interpretation: interpretCAGR(value)
            )
            
        case .sharpeRatio(let value):
            return MetricExplanation(
                title: "위험조정수익률 (Sharpe Ratio)",
                emoji: "⚖️",
                simpleExplanation: "감수한 위험 대비 얼마나 효율적으로 수익을 냈는지",
                analogy: "자동차 연비처럼, 같은 연료(위험)로 더 멀리(수익) 가는 것이 좋아요!",
                value: value,
                interpretation: interpretSharpe(value)
            )
            
        case .mdd(let value):
            return MetricExplanation(
                title: "최대 낙폭 (MDD)",
                emoji: "📉",
                simpleExplanation: "역대 최고점에서 최저점까지 얼마나 떨어졌는지",
                analogy: "롤러코스터의 가장 높은 곳에서 가장 낮은 곳까지의 높이 차이예요.",
                value: value,
                interpretation: interpretMDD(value)
            )
            
        case .volatility(let value):
            return MetricExplanation(
                title: "변동성",
                emoji: "🎢",
                simpleExplanation: "가격이 얼마나 출렁거리는지",
                analogy: "바다 파도의 높이처럼, 변동성이 높으면 오르내림이 심해요.",
                value: value,
                interpretation: interpretVolatility(value)
            )
            
        case .dividendYield(let value):
            return MetricExplanation(
                title: "배당률",
                emoji: "💰",
                simpleExplanation: "투자금 대비 매년 받는 배당금 비율",
                analogy: "월세 수익률처럼, 내 투자금 대비 매년 받는 현금이에요.",
                value: value,
                interpretation: interpretDividendYield(value)
            )
        }
    }
    
    // 각 지표별 해석 함수...
}
```

---

## 4. 비즈니스 모델 개편 및 마이그레이션

### 4.1 현재 상태
| 상품 | 가격 | 유형 |
|------|------|------|
| 몬테카를로 시뮬레이션 | ₩3,300 | 비소모성 (영구) |

### 4.2 새로운 비즈니스 모델

```
┌────────────────────────────────────────────────────────────────┐
│                     Exit Pro (₩9,900)                         │
│                    비소모성 (영구 구매)                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────────────┐    ┌─────────────────────┐           │
│  │ 🎲 몬테카를로 시뮬레이션 │    │ 📊 포트폴리오 분석    │           │
│  │                     │    │                     │           │
│  │ • 30,000회 시뮬레이션 │    │ • 무제한 종목        │           │
│  │ • 성공 확률 분석     │    │ • 전체 지표 분석     │           │
│  │ • 퍼센타일 분석      │    │ • 배당 분석          │           │
│  │ • 자산 경로 시각화   │    │ • AI 인사이트        │           │
│  └─────────────────────┘    └─────────────────────┘           │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ 🎁 Pro 전용 추가 혜택                                 │       │
│  │ • 광고 제거                                          │       │
│  │ • 미래 업데이트 기능 포함                              │       │
│  │ • 우선 지원                                          │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 4.3 무료 vs Pro 기능 비교

| 기능 | 무료 | Pro (₩9,900) |
|------|------|-------------|
| **기본 대시보드** | ✅ | ✅ |
| **자산 기록** | ✅ | ✅ |
| **은퇴 계획 설정** | ✅ | ✅ |
| **기본 계산** | ✅ | ✅ |
| --- | --- | --- |
| **몬테카를로 시뮬레이션** | 1,000회 (맛보기) | 30,000회 |
| **시뮬레이션 시각화** | ❌ | ✅ |
| **퍼센타일 분석** | ❌ | ✅ |
| --- | --- | --- |
| **포트폴리오 종목 수** | 3개 | 무제한 |
| **기본 지표 (CAGR, 변동성)** | ✅ | ✅ |
| **고급 지표 (Sharpe, MDD, Beta)** | ❌ | ✅ |
| **배당 분석** | ❌ | ✅ |
| **섹터 분석** | ❌ | ✅ |
| **AI 인사이트** | ❌ | ✅ |
| --- | --- | --- |
| **광고** | 있음 | 없음 |

### 4.4 마이그레이션 계획

#### Phase 1: 준비 (출시 2주 전)

1. **새 Product ID 등록**
   ```swift
   enum ProductID: String, CaseIterable {
       case montecarloSimulation = "montecarlo_simulation"  // 레거시
       case exitPro = "exit_pro"                            // 신규
   }
   ```

2. **기존 구매자 처리 로직**
   ```swift
   /// 기존 몬테카를로 구매자는 자동으로 Pro 혜택 부여
   var hasProAccess: Bool {
       // 레거시 구매자 또는 신규 Pro 구매자
       purchasedProductIDs.contains(ProductID.montecarloSimulation.rawValue) ||
       purchasedProductIDs.contains(ProductID.exitPro.rawValue)
   }
   ```

#### Phase 2: 소프트 론칭 (출시일)

1. **앱스토어 변경사항**
   - 기존 `montecarlo_simulation` (₩3,300) → **판매 중단** (숨김)
   - 신규 `exit_pro` (₩9,900) → **판매 시작**

2. **앱 내 UI 변경**
   - 기존 "몬테카를로 시뮬레이션 잠금해제" → "Exit Pro 업그레이드"
   - 포트폴리오 탭 추가

3. **기존 구매자 안내**
   ```swift
   // 기존 구매자에게 표시할 배너
   if hasMontecarloSimulation && !hasExitPro {
       Banner(
           title: "🎉 무료 업그레이드!",
           message: "기존 구매자님께 포트폴리오 분석 기능을 무료로 제공해드려요!"
       )
   }
   ```

#### Phase 3: 완전 전환 (출시 1개월 후)

1. **레거시 상품 완전 제거**
   - 앱스토어에서 `montecarlo_simulation` 삭제
   - 앱 코드에서 레거시 처리 로직 유지 (기존 구매자 지원)

2. **마케팅 메시지 통일**
   - "Exit Pro로 은퇴 계획을 완성하세요"

### 4.5 마이그레이션 코드 예시

```swift
// StoreKitService.swift 업데이트

@Observable
final class StoreKitService {
    
    enum ProductID: String, CaseIterable {
        case montecarloSimulation = "montecarlo_simulation"  // 레거시 (숨김)
        case exitPro = "exit_pro"                            // 신규
    }
    
    // MARK: - Computed Properties
    
    /// Pro 기능 접근 권한 (레거시 또는 신규 구매자)
    var hasProAccess: Bool {
        purchasedProductIDs.contains(ProductID.montecarloSimulation.rawValue) ||
        purchasedProductIDs.contains(ProductID.exitPro.rawValue)
    }
    
    /// 기존 몬테카를로 구매자 (마이그레이션 대상)
    var isLegacyPurchaser: Bool {
        purchasedProductIDs.contains(ProductID.montecarloSimulation.rawValue) &&
        !purchasedProductIDs.contains(ProductID.exitPro.rawValue)
    }
    
    /// 판매 중인 Pro 상품
    var proProduct: Product? {
        products.first { $0.id == ProductID.exitPro.rawValue }
    }
    
    /// Pro 가격 표시
    var proPriceDisplay: String {
        proProduct?.displayPrice ?? "₩9,900"
    }
    
    // MARK: - Purchase Methods
    
    /// Pro 구매
    @MainActor
    func purchaseExitPro() async -> Bool {
        guard let product = proProduct else {
            errorMessage = "제품을 찾을 수 없습니다"
            return false
        }
        return await purchase(product)
    }
}
```

### 4.6 기존 구매자 혜택 안내 UI

```swift
struct LegacyPurchaserBanner: View {
    @Environment(StoreKitService.self) private var storeKit
    
    var body: some View {
        if storeKit.isLegacyPurchaser {
            VStack(spacing: 12) {
                HStack {
                    Text("🎉")
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("기존 구매자 특별 혜택!")
                            .font(.headline)
                        Text("포트폴리오 분석 기능이 무료로 추가되었어요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text("""
                몬테카를로 시뮬레이션을 구매해주신 고객님께 \
                감사의 마음을 담아, 새로운 포트폴리오 분석 기능을 \
                무료로 제공해드립니다! 🙏
                """)
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding()
        }
    }
}
```

---

## 5. 로컬 계산 엔진

### 5.1 포트폴리오 분석기

```swift
/// 로컬에서 동작하는 포트폴리오 분석 엔진
enum PortfolioAnalyzer {
    
    /// 포트폴리오 전체 분석
    static func analyze(
        holdings: [PortfolioHolding],
        priceHistories: [String: [PriceData]],
        dividendHistories: [String: [DividendData]],
        riskFreeRate: Double = 0.035  // 무위험 수익률 (현재 약 3.5%)
    ) -> PortfolioAnalysisResult {
        
        // 1. 포트폴리오 일별 수익률 계산
        let portfolioReturns = calculatePortfolioReturns(
            holdings: holdings,
            priceHistories: priceHistories,
            dividendHistories: dividendHistories
        )
        
        // 2. 개별 지표 계산
        let cagr = calculateCAGR(returns: portfolioReturns)
        let volatility = calculateVolatility(returns: portfolioReturns)
        let sharpeRatio = calculateSharpeRatio(
            returns: portfolioReturns,
            riskFreeRate: riskFreeRate
        )
        let mdd = calculateMDD(returns: portfolioReturns)
        let dividendYield = calculateDividendYield(
            holdings: holdings,
            dividendHistories: dividendHistories,
            priceHistories: priceHistories
        )
        
        // 3. Total Return (배당 포함)
        let totalReturn = calculateTotalReturn(
            holdings: holdings,
            priceHistories: priceHistories,
            dividendHistories: dividendHistories
        )
        
        // 4. 점수화
        let score = calculateScore(
            cagr: cagr,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            mdd: mdd
        )
        
        return PortfolioAnalysisResult(
            cagr: cagr,
            cagrWithDividends: totalReturn.cagr,
            totalReturn: totalReturn.total,
            priceReturn: totalReturn.price,
            dividendReturn: totalReturn.dividend,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            mdd: mdd,
            dividendYield: dividendYield,
            score: score
        )
    }
    
    // ... 개별 계산 함수들
}
```

### 5.2 결과 모델

```swift
/// 포트폴리오 분석 결과
struct PortfolioAnalysisResult {
    // 수익 지표
    let cagr: Double                    // 가격만
    let cagrWithDividends: Double       // 배당 포함
    let totalReturn: Double             // 총 수익률 (배당 포함)
    let priceReturn: Double             // 가격 수익률
    let dividendReturn: Double          // 배당 수익률
    
    // 위험 지표
    let volatility: Double
    let sharpeRatio: Double
    let mdd: Double
    
    // 배당 지표
    let dividendYield: Double
    
    // 종합 점수
    let score: PortfolioScore
    
    /// 사용자 친화적 요약
    var summary: String {
        """
        📊 포트폴리오 분석 결과
        
        💰 수익성
        • CAGR: \(String(format: "%.1f", cagr * 100))%
        • 배당 포함 CAGR: \(String(format: "%.1f", cagrWithDividends * 100))%
        • 총 수익률: \(String(format: "%.1f", totalReturn * 100))%
          - 가격 상승: \(String(format: "%.1f", priceReturn * 100))%
          - 배당 수익: \(String(format: "%.1f", dividendReturn * 100))%
        
        🛡️ 안정성
        • 변동성: \(String(format: "%.1f", volatility * 100))%
        • 최대 낙폭: \(String(format: "%.1f", mdd * 100))%
        
        ⚖️ 효율성
        • Sharpe Ratio: \(String(format: "%.2f", sharpeRatio))
        
        💰 배당
        • 배당률: \(String(format: "%.2f", dividendYield * 100))%
        """
    }
}

/// 포트폴리오 점수
struct PortfolioScore {
    let total: Int          // 0-100
    let profitability: Int  // 수익성 점수 (40점 만점)
    let stability: Int      // 안정성 점수 (30점 만점)
    let efficiency: Int     // 효율성 점수 (30점 만점)
    
    var grade: String {
        switch total {
        case 90...100: return "S"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        default: return "D"
        }
    }
}
```

---

## 6. 구현 로드맵 (수정됨)

### Phase 1: 인프라 구축 (1주)
- [ ] Supabase 프로젝트 설정
- [ ] 데이터베이스 스키마 생성
- [ ] Edge Function 개발 (주간 데이터 수집)
- [ ] iOS 로컬 캐싱 레이어 개발

### Phase 2: 핵심 기능 개발 (2주)
- [ ] 종목 검색 UI
- [ ] 포트폴리오 구성 UI
- [ ] 로컬 계산 엔진 개발
  - [ ] CAGR, Volatility
  - [ ] Sharpe Ratio, MDD
  - [ ] 배당 포함 Total Return
- [ ] 분석 결과 화면

### Phase 3: 사용자 경험 개선 (1주)
- [ ] 지표 설명 UI (CAGR, Sharpe 등)
- [ ] 인사이트 카드
- [ ] 배당 정보 카드
- [ ] 애니메이션 및 시각화

### Phase 4: 수익화 및 마이그레이션 (1주)
- [ ] Exit Pro 상품 등록
- [ ] 무료/Pro 기능 분리
- [ ] 기존 구매자 마이그레이션
- [ ] 레거시 상품 숨김 처리

### Phase 5: 테스트 및 출시 (1주)
- [ ] 단위 테스트
- [ ] 통합 테스트
- [ ] 베타 테스트
- [ ] 앱스토어 제출

---

## 7. 리스크 및 대응 방안 (수정됨)

| 리스크 | 영향 | 대응 방안 |
|--------|------|-----------|
| 데이터 수집 실패 | 높음 | 백업 API 준비, 수동 동기화 옵션 |
| 로컬 계산 성능 | 중간 | 백그라운드 처리, 캐싱 최적화 |
| 기존 구매자 불만 | 높음 | 무료 업그레이드로 선제 대응 |
| Supabase 비용 증가 | 중간 | 캐싱 최적화, 요청 최소화 |
| 배당 데이터 누락 | 중간 | 배당 없는 종목 명시, 수동 입력 옵션 |

---

## 8. 결론

### 핵심 전략
1. **비용 최소화**: 로컬 계산 + 주간 동기화로 서버 비용 절감
2. **사용자 가치**: 배당 포함 분석, 친절한 지표 설명
3. **기존 고객 존중**: 무료 업그레이드로 신뢰 유지
4. **수익 증대**: Pro 번들로 ARPU 상승 (₩3,300 → ₩9,900)

### 예상 효과
- 기존 구매자 만족도 상승 (무료 기능 추가)
- 신규 구매 전환율 상승 (더 많은 가치 제공)
- 월 서버 비용 $25 이하 유지

---

## 9. 투자 인사이트 UX 개선 방안

### 9.1 현재 문제점

현재 투자 인사이트는 **텍스트 중심의 긴 설명**으로 구성되어 있어 사용자가 읽다가 지치는 문제가 있습니다:

| 문제점 | 영향 |
|--------|------|
| 글씨가 너무 많음 | 사용자 이탈, 핵심 메시지 전달 실패 |
| 일관된 텍스트 스타일 | 중요한 정보와 부가 정보 구분 어려움 |
| 수동적인 정보 전달 | 사용자 참여도 낮음 |
| 단조로운 레이아웃 | 시각적 흥미 부족 |

### 9.2 개선 전략: "스캔 → 이해 → 행동" 프레임워크

사용자의 인사이트 소비 패턴을 3단계로 구분하여 설계합니다:

```
┌─────────────────────────────────────────────────────────────┐
│  1️⃣ 스캔 (2초)           한눈에 핵심 파악                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 💪 수익성: 우수 │ ⚠️ 안정성: 주의 │ 👍 효율성: 양호    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  2️⃣ 이해 (10초)          관심 영역 상세 확인                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ [카드 탭 시] 시각화 + 핵심 수치 + 짧은 해석              │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  3️⃣ 행동 (선택적)        구체적 개선 방안                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ [더보기] 상세 분석 + 추천 종목/ETF + 액션 버튼           │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 9.3 디자인 원칙

#### 1) 👀 한눈에 보이는 핵심 (Visual First)

**Before (현재):**
```
"포트폴리오 변동성이 22.5%로 적정 수준이에요. 
일부 종목이 변동성을 높이고 있어요. 
TSLA는 45.2%로 높은 변동성을 보이고..."
```

**After (개선):**
```swift
// 이모지 + 한 줄 요약 + 시각적 비교
┌────────────────────────────────────────┐
│ 🎢 변동성                              │
│                                        │
│ [====내 포트폴리오====]--[S&P500]---   │
│         22.5%              18.2%       │
│                                        │
│ 📊 S&P500보다 약간 높아요 (+4.3%p)     │
└────────────────────────────────────────┘
```

#### 2) 🧩 점진적 공개 (Progressive Disclosure)

```swift
// 1단계: 컴팩트 뷰 (기본)
┌─────────────────────────────────────┐
│ ⚠️ 변동성 주의                     │
│ TSLA가 포트폴리오 변동성의 주요 원인  │
│                            [더보기] │
└─────────────────────────────────────┘

// 2단계: 확장 뷰 (탭 시)
┌─────────────────────────────────────┐
│ ⚠️ 변동성 주의                     │
│                                     │
│ 📊 종목별 변동성                    │
│ ├─ TSLA  ████████████ 45.2%  ⚠️    │
│ ├─ AAPL  █████      28.5%          │
│ └─ VTI   ██         15.3%  ✓       │
│                                     │
│ 💡 제안: TSLA 비중 ↓, 저변동 ETF ↑  │
│                                     │
│ [VTI 추가하기]  [SCHD 알아보기]      │
└─────────────────────────────────────┘
```

#### 3) 🎮 게임화 요소 (Gamification)

```swift
// 점수 + 뱃지 시스템
struct InsightBadge {
    case dividendKing      // 배당률 4% 이상
    case lowVolatility     // 변동성 15% 이하
    case sharpeElite       // Sharpe 1.5 이상
    case balanced          // 3개 이상 섹터 분산
}

// UI 예시
┌─────────────────────────────────────┐
│ 🏆 획득한 뱃지                      │
│ [💰 배당킹] [🛡️ 안정투자] [⚖️ 균형] │
│                                     │
│ 🔒 잠긴 뱃지                        │
│ [🎯 샤프마스터] Sharpe 1.5 달성 시  │
└─────────────────────────────────────┘
```

#### 4) 📊 데이터 시각화 우선

```swift
// 숫자보다 시각화
enum VisualizationType {
    case comparisonBar     // 비교 막대 (vs S&P500)
    case progressRing      // 진행률 링 (목표 대비)
    case trendSparkline    // 미니 차트 (추세)
    case heatmap           // 히트맵 (섹터별 기여도)
    case radarChart        // 레이더 (종합 평가)
}
```

### 9.4 구체적 UI 컴포넌트 제안

#### A) 요약 카드 (Summary Card)

```swift
struct InsightSummaryCard: View {
    let category: InsightCategory
    let status: Status  // .good, .warning, .danger
    let headline: String  // 최대 15자
    let metric: String    // "22.5%", "1.25" 등
    
    var body: some View {
        HStack {
            // 상태 아이콘 (이모지 대신 SF Symbol 사용)
            StatusIcon(status: status)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading) {
                Text(category.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(headline)
                    .font(.body.bold())
            }
            
            Spacer()
            
            Text(metric)
                .font(.title2.bold())
                .foregroundColor(status.color)
        }
        .padding()
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
    }
}
```

#### B) 비교 슬라이더 (Comparison Slider)

```swift
struct ComparisonSlider: View {
    let myValue: Double
    let benchmark: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            // 시각적 비교 바
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 배경
                    Capsule().fill(Color.gray.opacity(0.2))
                    
                    // 벤치마크 마커
                    BenchmarkMarker(position: benchmarkPosition(in: geo))
                    
                    // 내 포트폴리오 마커
                    MyMarker(position: myPosition(in: geo))
                }
            }
            .frame(height: 24)
            
            // 간단한 해석
            Text(interpretation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    var interpretation: String {
        let diff = myValue - benchmark
        if diff > 0.05 {
            return "S&P500보다 \(String(format: "%.1f", diff * 100))%p 높아요"
        } else if diff < -0.05 {
            return "S&P500보다 \(String(format: "%.1f", abs(diff) * 100))%p 낮아요"
        } else {
            return "S&P500과 비슷해요"
        }
    }
}
```

#### C) 액션 카드 (Action Card)

```swift
struct InsightActionCard: View {
    let insight: Insight
    let suggestedActions: [SuggestedAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 인사이트 요약
            HStack {
                insight.icon
                Text(insight.shortMessage)
                    .font(.body)
            }
            
            // 추천 액션 버튼들
            HStack(spacing: 8) {
                ForEach(suggestedActions.prefix(2)) { action in
                    ActionButton(action: action)
                }
            }
        }
        .padding()
        .background(Color.Exit.cardBackground)
        .cornerRadius(12)
    }
}

struct SuggestedAction: Identifiable {
    let id = UUID()
    let icon: String      // "plus.circle"
    let label: String     // "VTI 추가"
    let action: () -> Void
}
```

### 9.5 콘텐츠 작성 가이드

#### 1) 문장 길이 제한

| 레벨 | 최대 길이 | 용도 |
|------|-----------|------|
| 헤드라인 | 15자 | 카드 제목 |
| 요약 | 30자 | 핵심 메시지 |
| 설명 | 60자 | 상세 설명 (확장 시) |

#### 2) 톤 & 매너

```
❌ Before: "포트폴리오의 변동성이 22.5%로 측정되었습니다."
✅ After:  "S&P500보다 살짝 출렁거려요 (+4%p)"

❌ Before: "Sharpe Ratio 1.25는 양호한 수준입니다."
✅ After:  "위험 대비 수익 효율 👍 (S&P500 대비 +0.4)"

❌ Before: "TSLA의 높은 변동성이 전체 포트폴리오 위험을 증가시킵니다."
✅ After:  "🚗 테슬라가 파도를 만들어요 (변동성 45%)"
```

#### 3) 숫자 표현

```swift
// 숫자를 맥락과 함께 표현
struct MetricWithContext {
    let value: Double
    let comparison: String  // "S&P500 대비"
    let direction: String   // "+3.2%p 높음"
    let meaning: String     // "위험이 조금 더 높아요"
}

// 예시
// "22.5%" → "22.5% (S&P500보다 +4.3%p)"
// "1.25" → "1.25 (상위 20% 수준)"
```

### 9.6 인터랙션 디자인

#### 1) 탭 동작

```
[카드 탭] → 확장/축소 애니메이션
[? 버튼] → 지표 설명 시트
[추천 종목] → 종목 상세 또는 검색
[공유] → 이미지로 내보내기
```

#### 2) 스와이프 동작

```
[좌 스와이프] → 다음 인사이트
[우 스와이프] → 이전 인사이트  
[아래 스와이프] → 인사이트 닫기
```

### 9.7 구현 우선순위

| 단계 | 기능 | 난이도 | 효과 |
|------|------|--------|------|
| 1 | 비교군 바 추가 (완료) | 중 | 높음 |
| 2 | 요약 카드 리디자인 | 중 | 높음 |
| 3 | 점진적 공개 UI | 중 | 중 |
| 4 | 액션 버튼 추가 | 낮음 | 중 |
| 5 | 뱃지 시스템 | 높음 | 낮음 |

### 9.8 예상 결과

| 지표 | Before | After (예상) |
|------|--------|--------------|
| 인사이트 완독률 | 30% | 70% |
| 평균 체류 시간 | 15초 | 45초 |
| 액션 전환율 | 5% | 20% |
| 사용자 만족도 | 3.5/5 | 4.5/5 |

---

*이 문서는 지속적으로 업데이트됩니다.*
*버전 0.3 - 비교군 기능 및 투자 인사이트 UX 개선 방안 추가*
