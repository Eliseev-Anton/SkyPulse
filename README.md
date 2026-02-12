

# SkyPulse 

SkyPulse — iOS-приложение для поиска рейсов, просмотра табло аэропортов и хранения истории поисковых запросов.  
Проект демонстрирует production-подход к разработке iOS-приложений с использованием MVVM, RxSwift и Coordinator-навигации.

---

## Overview

Приложение демонстрирует:

- MVVM архитектуру
- Реактивное программирование (RxSwift)
- Навигацию через Coordinator (RxFlow)
- Локальное хранение данных (Realm)
- Масштабируемую слоистую структуру проекта

Проект создан как демонстрация архитектурных навыков iOS-разработки.

---

## Features

### Flight Search
- Поиск по номеру рейса
- Поиск по маршруту (From → To)
- Поиск по аэропорту

### Airport Board
- Табло вылетов
- Табло прилётов

### Search History
- Автоматическое сохранение истории поисков
- Локальное хранение через Realm

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Swift | Основной язык разработки |
| UIKit | UI слой |
| RxSwift / RxCocoa | Реактивные потоки данных |
| RxFlow | Навигация (Coordinator Pattern) |
| Realm | Локальное хранение данных |
| SnapKit | AutoLayout DSL |

---

## Architecture

Проект построен с использованием **MVVM + Coordinator (RxFlow)**.  
В проекте используется слоистая архитектура с разделением на Presentation / Domain / Data.

---

# SkyPulse Project Structure

## Application Layer
- AppDelegate / SceneDelegate
- Dependency Injection / Assemblies
- AppFlow / AppStepper

## Presentation Layer (MVVM + RxFlow)

**Flows**
- AppFlow
- SplashFlow
- DashboardFlow

**Steppers**
- AppStepper
- SplashStepper
- DashboardStepper

**Screens**
- **Splash**
  - SplashViewController
  - SplashViewModel
- **SearchFlights**
  - SearchFlightsViewController
  - SearchFlightsViewModel
- **AirportBoard**
  - AirportBoardViewController
  - AirportBoardViewModel
- **SearchHistory**
  - SearchHistoryViewController
  - SearchHistoryViewModel

**UIComponents**
- Cells
- ReusableViews
- Extensions

## Domain Layer

**Entities**
- Flight
- Airport
- SearchQuery

**UseCases**
- FetchAirportBoardUseCase
- SearchFlightsUseCase
- SaveSearchHistoryUseCase
- FetchSearchHistoryUseCase

**RepositoryProtocols**
- FlightsRepositoryProtocol
- AirportRepositoryProtocol
- SearchHistoryRepositoryProtocol

## Data Layer

**Network**
- APIClient
- Endpoints
- DTOModels
- Mappers (DTO → Domain)

**Repositories (Implementations)**
- FlightsRepository
- AirportRepository
- SearchHistoryRepository

**Persistence**
- RealmModels
- RealmManager
## Data Flow
View → ViewModel → UseCase → Repository → API / Database

Преимущества:

- Тестируемость  
- Слабая связанность слоёв  
- Простота масштабирования  

---

## Navigation

Навигация реализована через RxFlow.

**AppFlow**
- **SplashFlow**
- **DashboardFlow**
  - **Flight Search**
  - **Airport Board**
  - **Search History**

---

Преимущества:

- ViewController не содержит навигационной логики  
- Экраны не связаны напрямую  
- Простое добавление новых флоу  

---

## Reactive Programming

Взаимодействие между слоями построено на Observable-потоках.

RxSwift позволяет:

- Обрабатывать асинхронные операции  
- Управлять потоками данных  
- Централизованно обрабатывать ошибки  

---

## Persistence

Realm используется для хранения истории поисковых запросов.

Сохраняются:

- Тип поиска  
- Параметры запроса  
- Дата выполнения  

---

## Requirements

- Xcode 15+
- iOS 15+
- Swift 5+

---

## Installation

### 1. Clone repository

```bash
git clone https://github.com/yourusername/SkyPulse.git
cd SkyPulse
```

### 2.Install dependencies

Если используется Swift Package Manager — зависимости подтянутся автоматически.

Если используется CocoaPods:
Если используется Swift Package Manager — зависимости подтянутся автоматически.

Если используется CocoaPods:

```bash
pod install
```
### 3. Open project

Открыть файл:
```bash
SkyPulse.xcworkspace
```

### Purpose of the Project

Проект создан для демонстрации навыков разработки iOS-приложений:
- Архитектурное проектирование
- Реактивный стек (RxSwift)
- Навигация через Coordinator (RxFlow)
- Работа с сетью и локальной БД
- Production-подход к структуре проекта
- Использование современного подхода к асинхронности (Swift Concurrency: async/await)
- Понимание и поддержка legacy-подходов (completion handlers, escaping closures)
