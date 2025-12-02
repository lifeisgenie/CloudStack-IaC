FROM nginx:alpine

# 기본 html 삭제 후 프로젝트 파일 복사
RUN rm -rf /usr/share/nginx/html/*
COPY src/ /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]