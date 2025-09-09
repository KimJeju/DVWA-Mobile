██████╗ ██╗   ██╗██╗    ██╗ █████╗     ███╗   ███╗ ██████╗ ██████╗ ██╗██╗     
██╔══██╗╚██╗ ██╔╝██║    ██║██╔══██╗    ████╗ ████║██╔═══██╗██╔══██╗██║██║     
██████╔╝ ╚████╔╝ ██║ █╗ ██║███████║    ██╔████╔██║██║   ██║██████╔╝██║██║     
██╔═══╝   ╚██╔╝  ██║███╗██║██╔══██║    ██║╚██╔╝██║██║   ██║██╔═══╝ ██║██║     
██║        ██║   ╚███╔███╔╝██║  ██║    ██║ ╚═╝ ██║╚██████╔╝██║     ██║███████╗
╚═╝        ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
                              MOBILE

# DVWA Mobile (Damn Vulnerable Mobile Application)

> 📱 Intentionally Vulnerable Mobile Application for Security Education  
> ⚠️ **This app is intentionally vulnerable. DO NOT use it in production.**

---

## 🚀 Introduction
**DVWA Mobile**은 보안 연구 및 교육을 위해 제작된 **의도적으로 취약한 모바일 애플리케이션**입니다.  
웹 해킹 학습용 [DVWA](https://github.com/digininja/DVWA)의 컨셉을 모바일(Android/iOS) 환경으로 확장한 프로젝트로,  
Flutter + SQLite 기반으로 제작되었습니다.  

사용자는 APK를 설치한 뒤 Burp Suite 등 프록시 도구를 활용하여 다양한 취약점을 직접 실습할 수 있습니다.  

---

## ⚠️ Disclaimer
- 본 프로젝트는 **연구·교육 목적**으로만 사용해야 합니다.  
- 실제 서비스나 운영 환경에서는 절대 사용하지 마십시오.  
- 본 앱의 사용으로 인해 발생하는 모든 책임은 전적으로 사용자 본인에게 있습니다.  

---

## ✨ Features
- **SQL Injection** (로그인 bypass)
- **XSS** (게시판/댓글)
- **File Upload** (확장자 검증 없음)
- **CSRF** (비밀번호 변경 시 토큰 검증 없음)

---

## 📂 Project Structure

dvwa_mobile/
├─ lib/
│ ├─ main.dart
│ ├─ pages/
│ │ ├─ login_page.dart # SQLi
│ │ ├─ board_page.dart # XSS
│ │ ├─ upload_page.dart # File Upload
│ │ └─ settings_page.dart # 앱 설정/리셋
│ ├─ services/
│ │ └─ db.dart # SQLite 연결
│ └─ widgets/
├─ assets/
│ └─ README_lab.md
├─ docs/
│ ├─ banner.png
│ └─ user_guide.pdf
└─ README.md

---

## 🧪 Example Scenarios
1. **SQLi**  
   - 로그인 화면 → `username: ' OR '1'='1` 입력 시 로그인 우회  

2. **XSS**  
   - 게시판 댓글 입력 시 `<img src=x onerror=alert(1)>` 실행  

3. **CSRF**  
   - 토큰 없이 비밀번호 변경 요청 재전송  

4. **File Upload**  
   - `.php`, `.exe` 등 임의 파일 업로드 성공  

---

## 🛠️ Tech Stack
- **Framework**: Flutter 3.x / Dart  
- **Database**: SQLite  
- **Proxy Tool**: Burp Suite (실습용)  

---

## 📦 Installation
### 1. APK 설치
```bash
adb install dvwa_mobile.apk
```
---

## 📜  Burp Suite 연동

기기 또는 에뮬레이터의 Wi-Fi 프록시를 Burp Suite로 설정합니다.

필요하다면 Burp Suite CA 인증서를 기기에 설치합니다.

DVWA Mobile 앱을 실행한 후, Burp에서 트래픽을 캡처하여 공격 시나리오를 실습할 수 있습니다.

---

## 🖼️ Screenshots & Demo

(추후 업데이트 예정)

로그인 SQLi 우회 화면

Burp Suite 프록시 캡처 화면

게시판 XSS 실행 결과

파일 업로드 시연

---

⚠️ Additional Clause for DVWA Mobile: </br>
This software is created *for educational and research purposes only.  
Do not use this software for illegal activities, real-world exploitation,  
or in production environments.  
Any misuse of this project is solely the responsibility of the user.

---


