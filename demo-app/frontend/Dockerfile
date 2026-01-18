FROM node:20-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

# Create a startup script that generates info.json before starting nginx
RUN echo '#!/bin/sh' > /usr/local/bin/start.sh && \
    echo 'echo "{\"frontend_hostname\": \"$(hostname)\"}" > /usr/share/nginx/html/info.json' >> /usr/local/bin/start.sh && \
    echo 'exec nginx -g "daemon off;"' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 80
CMD ["/usr/local/bin/start.sh"]
