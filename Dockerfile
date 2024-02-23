# 기본 이미지로 Flutter SDK가 포함된 Docker 이미지 사용
FROM cirrusci/flutter:latest

# 작업 디렉토리 설정
WORKDIR /app

# 현재 디렉토리의 모든 파일을 컨테이너의 /app에 복사
COPY . /app

# Flutter 의존성 가져오기
RUN flutter pub get

# 릴리스 모드로 애플리케이션 빌드
RUN flutter build web

# nginx를 사용하여 빌드된 애플리케이션 서비스
FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html
EXPOSE 80

# nginx 시작
CMD ["nginx", "-g", "daemon off;"]
