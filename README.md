# Busan PublicData Startup 2025

![Flutter](https://img.shields.io/badge/Flutter-App-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Client-0175C2?logo=dart&logoColor=white)
![Public Data](https://img.shields.io/badge/Public%20Data-Busan-0F766E)
![Portfolio](https://img.shields.io/badge/Portfolio-Public%20Sector%20IT-111827)

> 2025년 부산광역시 공공·빅데이터 활용 창업경진대회용 Flutter 앱 프로젝트입니다. 공공데이터 기반 서비스 아이디어를 앱 형태로 구현하기 위한 초기 프로토타입입니다.

## 프로젝트 개요

| 항목 | 내용 |
| --- | --- |
| 대회 | 2025년 부산광역시 공공·빅데이터 활용 창업경진대회 |
| 형태 | Flutter 기반 앱 프로토타입 |
| 관심 직무 연결 | 공기업 전산직, 공공데이터 서비스, 디지털 서비스 기획 |
| 현재 상태 | Flutter 기본 구조와 초기 화면/인증 구조 초안 |
| Drive 확인 자료 | Flutter 원본 폴더, 리뷰 크롤링 노트북, Firebase 설정 흔적 |

## 이 저장소의 역할

이 프로젝트는 완성형 서비스라기보다, 공공데이터 활용 창업경진대회에서 앱 아이디어를 구현하기 위한 초기 코드베이스입니다. GitHub 포트폴리오에서는 다음 역량을 보여주는 보조 프로젝트로 배치하는 것이 적절합니다.

- Flutter 프로젝트 구조를 만들고 플랫폼별 빌드 타깃을 관리한 경험
- 공공데이터 기반 서비스 아이디어를 앱 화면으로 옮기는 초기 구현 경험
- 리뷰 크롤링 등 외부 데이터를 서비스 기획에 연결하려는 시도
- 공공데이터/크롤링/인증 설정 파일의 공개 경계를 구분하는 감각

## 현재 구현 상태

현재 GitHub 코드에는 Flutter 기본 counter 앱 구조가 대부분 남아 있고, 일부 인증/라우팅 파일은 빈 파일입니다.

```text
lib/
|-- main.dart
|-- app.dart
|-- routes/
|   `-- app_routes.dart
|-- screens/
|   `-- auth/
|       |-- login_screen.dart
|       `-- signup_screen.dart
`-- services/
    |-- auth_service.dart
    `-- login.dart
```

따라서 이 저장소는 “완성 앱”이 아니라 **공공데이터 앱 프로토타입의 출발점**으로 설명하는 것이 정직합니다.

## Drive 자료 검토 결과

Google Drive에서 같은 프로젝트로 보이는 폴더를 확인했습니다.

- `Busan_PublicData_Startup`: Flutter 프로젝트 원본, `assets`, `.dart_tool`, `build`, `.idea` 포함
- `리뷰_크롤링.ipynb`: 리뷰 데이터 수집 실험 노트북
- `firebase.json`, `.flutter-plugins`, `.flutter-plugins-dependencies`: 로컬/환경 의존 설정 파일

이번 보완에서는 아래 자료를 GitHub에 추가하지 않았습니다.

- `build/`, `.dart_tool/`, `.idea/`: 로컬 빌드/IDE 산출물
- Firebase 관련 설정: 프로젝트 식별자나 배포 환경 정보가 포함될 수 있음
- 리뷰 크롤링 원본: 수집 출처와 재배포 조건 확인 필요

## 실행 방법

```bash
flutter pub get
flutter run
```

지원 플랫폼은 Flutter 기본 템플릿 기준으로 Android, iOS, Web, Windows, macOS, Linux 구조가 포함되어 있습니다.

## 포트폴리오에서의 활용 방식

이 저장소는 메인 프로젝트보다는 “공공데이터 기반 앱 프로토타입” 항목으로 짧게 소개하는 것이 좋습니다. 메인 프로젝트로 제출하려면 다음 보완이 필요합니다.

- 공공데이터 출처와 서비스 문제 정의 문서화
- 실제 앱 화면을 counter template에서 서비스 화면으로 교체
- 로그인/회원가입/라우팅 구현
- 크롤링 데이터의 공개 가능 범위 확인
- `docs/`에 화면 흐름, 데이터 흐름, 배포 구조 추가

## 공개 안전성

공공데이터 프로젝트라도 크롤링 데이터, Firebase 설정, 빌드 산출물은 그대로 공개하면 위험할 수 있습니다. 이 저장소는 현재 공개 가능한 Flutter 소스 중심으로 유지하고, Drive의 원본/빌드/환경 파일은 추가하지 않았습니다.
