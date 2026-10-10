# 📱 KASH - Gestor Financiero Personal & Tracker de Deuda TDC (iOS Nativo)

> **"El crédito disponible en una Tarjeta de Crédito NO es dinero propio."**

KASH es una aplicación iOS nativa de grado financiero, de arquitectura **100% offline-first, segura y privada**. Sustituye y supera las hojas de cálculo tradicionales mediante una experiencia fluida, análisis predictivo de hábitos de endeudamiento, control estricto de liquidez y portabilidad absoluta.

---

## 🌟 Características Principales

1. **Regla de Oro Financiera:**  
   El disponible en tarjetas de crédito jamás se computa como liquidez ni patrimonio. La *Liquidez Real* solo considera activos propios (débito, efectivo, inversiones) menos pasivos consolidados.
2. **Arquitectura 100% Offline-First y Segura:**  
   Persistencia local en **SwiftData** protegida con `FileProtectionType.completeUnlessOpen` y encriptación de hardware en el Secure Enclave.
3. **Autenticación Biométrica Obligatoria:**  
   Soporte para Face ID y Touch ID con protección Privacy Shield Blur al pasar a segundo plano.
4. **Modo Privacidad Rápido (👁️):**  
   Oculta y desenfoca saldos sensibles con un toque para uso seguro en lugares públicos.
5. **Control de Pagos y Amortización Atómica:**  
   Transferencias directas de cuentas de liquidez a tarjetas con descuento de saldos de corte e impacto en compromisos del mes.
6. **Módulo de Análisis e Inteligencia Financiera:**  
   Gráficos circulares de categorías, semáforo de buró/endeudamiento, velocímetro de amortización (*Burn Rate vs. Payoff Rate*) y simulador de Deuda Cero con estrategia Avalancha.
7. **Widgets Interactivos (iOS 17+ WidgetKit & AppIntents):**  
   Visualización rápida de pasivos y botones de acción rápida para gastos, ingresos y pagos.
8. **Motor de Respaldo Modular (ZIP + CSV + JSON):**  
   Exportación e importación universal sin dependencia de servicios en la nube.

---

## 🛠️ Tecnologías y Requisitos

- **Plataforma Objetivo:** iOS 17.0+ (iPhone / iPad) + WidgetKit
- **Lenguaje:** Swift 5.10 / Swift 6
- **UI:** SwiftUI (FinTech Design System: Revolut / Robinhood / Wise)
- **Persistencia:** SwiftData
- **Gráficos:** Swift Charts
- **Widgets & Intents:** WidgetKit + AppIntents
- **Seguridad:** LocalAuthentication + CryptoKit + Apple Hardware Protection
- **Compresión:** Apple Archive / Compression

---

## 🏗️ Estructura del Proyecto

```
KASH/
├── KASH/
│   ├── App/
│   │   ├── KASHApp.swift
│   │   ├── AppState.swift
│   │   └── RootView.swift
│   ├── Core/
│   │   ├── DesignSystem/
│   │   │   ├── ColorTokens.swift
│   │   │   ├── Typography.swift
│   │   │   └── Components/
│   │   ├── Security/
│   │   │   ├── BiometricAuthManager.swift
│   │   │   └── PrivacyShieldView.swift
│   │   ├── Notifications/
│   │   │   └── NotificationManager.swift
│   │   └── Backup/
│   │       ├── BackupManager.swift
│   │       └── Models/
│   ├── Models/
│   │   ├── CreditCard.swift
│   │   ├── LiquidityAccount.swift
│   │   ├── TransactionCategory.swift
│   │   ├── Transaction.swift
│   │   ├── MonthlyRecord.swift
│   │   ├── CardMonthlyBalance.swift
│   │   ├── UpcomingPayment.swift
│   │   └── UserSettings.swift
│   ├── Features/
│   │   ├── Dashboard/
│   │   ├── Batches/
│   │   ├── Transactions/
│   │   ├── Analytics/
│   │   ├── Settings/
│   │   └── Onboarding/
│   └── Resources/
├── KASHWidgets/
│   ├── KASHWidgetsBundle.swift
│   ├── KASHWidgetEntry.swift
│   ├── Views/
│   └── Intents/
└── Tests/
    └── KASHTests/
```

---

## 📄 Licencia

Uso Personal y Privado. Desarrollado con estrictos estándares de ingeniería de software.
