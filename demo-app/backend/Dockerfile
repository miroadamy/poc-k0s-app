FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app
COPY Main.java .
RUN javac Main.java
RUN jar --create --file app.jar --main-class Main Main.class

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/app.jar ./app.jar
EXPOSE 8080
ENV PORT=8080
CMD ["java", "-jar", "/app/app.jar"]
