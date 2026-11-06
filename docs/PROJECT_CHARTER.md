# 📋 Project Charter: GreenLand

## 1. General Project Information
* **Project Name:** GreenLand (Smart Greenhouse Management Ecosystem)
* **Chosen Uniqueness Track:** Resource Savings (Energy & Water optimization)
* **Target Audience:** Commercial greenhouse owners and agronomists

---

## 2. User Persona: Erlan
* **Name & Age:** Ерлан (Erlan), 42 года.
* **Occupation & Location:** Владелец коммерческой теплицы томатов (площадь 800 м²), пригородная зона г. Алматы.
* **Context & Workflow:** 
  * Выращивает тепличные томаты круглый год.
  * В теплице работают 2 наемных работника, которые получают устные поручения.
  * В зимний период и межсезонье расходы на отопление (газ/электричество) и фитоосвещение составляют до 50% себестоимости продукции.
* **Core Pain Point:** 
  * Деньги уходят впустую из-за неэффективного использования тарифов электроэнергии: ночью действует льготный тариф (11.20 ₸/кВт⋅ч), а днем — пиковый (28.50 ₸/кВт⋅ч).
  * Человеческий фактор: работники забывают закрывать фрамуги при резком похолодании или поздно включают полив в жару.

---

## 3. Signature Feature Statement
> *«Наше приложение рассчитывает финансовую экономию в тенге и автоматически оптимизирует работу отопления и фитоосвещения по дифференцированным тарифам на электроэнергию и прогнозу погоды, потому что наш пользователь Ерлан теряет до половины чистой прибыли на неконтролируемых энергозатратах».*

---

## 4. Team Roles & Responsibilities

1. **Mobile UI & Design Lead (Lumix):**
   * UI/UX Design System, 5 screens, bilingual localization (RU/KZ), offline resilience (M8).
2. **Mobile Logic & Integration Lead:**
   * Supabase integration, state management, remote command execution (M3), alerts (M5).
3. **Backend & Cloud Database Lead:**
   * PostgreSQL tables, RLS isolation policies (M1), telemetry storage (M6), automation rules (M4).
4. **Simulator & Energy Feature Lead (infinity889):**
   * Microclimate physics model in Python, response to commands (<5s SLA), stress-test generator (M8), KZT tariff savings calculation.
